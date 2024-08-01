use std::collections::BTreeMap;
use std::path::Path;

// use bend::run_book;
use bend::{AdtEncoding, CompileResult, compile_book};
use bend::{desugar_book, diagnostics, load_file_to_book, readback_hvm_net, CompileOpts, RunOpts};
use bend::diagnostics::{Diagnostics, DiagnosticsConfig, Severity};
use bend::fun::{Book, Definition, Name, Num, Pattern, Tag, Term};
use bend::fun::net_to_term::net_to_term;
use bend::fun::term_to_net::{Labels, term_to_hvm};
use bend::net::hvm_to_net::hvm_to_net;
use bend::imports::DefaultLoader;
use macroquad::prelude::*;
use ::hvm::{ast, hvm};

use crate::api::{Command, Event};
use crate::convert::{FromTerm, IntoTerm};
use crate::hvm::HvmState;

pub type State = Term;

// TODO: Move `bend_book`, `labels` into a struct? 
pub struct App<'a> {
    hvm: HvmState<'a>,
    book: Book,
    labels: Labels,
}

impl<'a> App<'a> {
    pub fn load_from_file(path: &str) -> Result<Self, Diagnostics> {
        let path = Path::new(path);
        let package_loader = DefaultLoader::new(path);
        let diagnostics_cfg = DiagnosticsConfig::new(Severity::Allow, false);
        let mut book = load_file_to_book(path, package_loader, diagnostics_cfg)?;
        // book.entrypoint = entrypoint.map(Name::new);
        // bend_book.entrypoint = None;

        let compile_opts = CompileOpts::default();
        let diagnostics_cfg = DiagnosticsConfig::new(Severity::Allow, false);
        let result = compile_book(&mut book, compile_opts.clone(), diagnostics_cfg, None)?;
        let CompileResult { hvm_book, labels, .. } = result;
        let hvm_book: hvm::Book = hvm_book.build();

        let hvm = HvmState::new(hvm_book);
        Ok(App { book, hvm, labels })
    }

    pub fn init(&mut self) -> Result<State, Diagnostics> {
        // println!("App::init");
        let pats = [None, Some(Name::new("init")), None, None, None];
        let term = Term::rfold_lams(
            Term::Var { nam: Name::new("init") },
            pats.into_iter());
        self.main(vec![term])
    }

    pub fn tick(&mut self, state: &State) -> Result<State, Diagnostics> {
        // println!("App::tick");
        let pats = [None, None, Some(Name::new("tick")), None, None];
        let term = Term::rfold_lams(
            Term::app(Term::Var { nam: Name::new("tick") }, state.clone()),
            pats.into_iter());
        self.main(vec![term])
    }

    pub fn draw(&mut self, state: &State) -> Result<Vec<Command>, Diagnostics> {
        // println!("App::draw");
        let pats = [None, None, None, Some(Name::new("draw")), None];
        let term = Term::rfold_lams(
            Term::app(Term::Var { nam: Name::new("draw") }, state.clone()),
            pats.into_iter());
        let cmds = self.main(vec![term])?;
        let cmds = FromTerm::from_term(&cmds)
            .ok_or("Failed to decode term".to_owned())?;
        Ok(cmds)
    }

    pub fn when(&mut self, event: Event, state: &State) -> Result<State, Diagnostics> {
        // println!("App::when");
        let pats = [None, None, None, None, Some(Name::new("when"))];
        let term = Term::rfold_lams(
            Term::app(
                Term::app(
                    Term::Var { nam: Name::new("when") },
                    IntoTerm::into_term(event)),
                state.clone()),
            pats.into_iter());
        self.main(vec![term])
    }

    fn main(&mut self, args: Vec<Term>) -> Result<Term, Diagnostics> {
        let mut labels = self.labels.clone();

        // Convert/push args
        // let start = std::time::Instant::now();
        let args = args.iter().map(|term| -> Result<_, Diagnostics> {
            // Sometimes causes lib to panic; should desugar if possible
            let term = self.desugar_term(term)?;
            let net = term_to_hvm(&term, &mut labels)?;
            Ok(self.hvm.push_net(&net))
        });
        let args = args.collect::<Result<_, _>>()?;
        // println!("- Convert/push args: {:.2} ms", 1000.0 * start.elapsed().as_secs_f32());

        // Evaluate main
        // let start = std::time::Instant::now();
        let main = self.hvm.get_ref("main").unwrap();
        let result = self.hvm.call(main, args);
        let result = self.hvm.pop_net(result).ok_or("HVM Error".to_owned())?;
        // println!("- Evaluate/pop: {:.2} ms", 1000.0 * start.elapsed().as_secs_f32());

        // Readback
        // let start = std::time::Instant::now();
        let adt_encoding = CompileOpts::default().adt_encoding;
        let linear_readback = RunOpts::default().linear_readback;
        let (result, _) = readback_hvm_net(&result, &self.book, &labels, linear_readback, adt_encoding);
        // println!("- Readback: {:.2} ms", 1000.0 * start.elapsed().as_secs_f32());
        Ok(result)
    }

    // HACK: Fix for panic caused when calling `term_to_hvm`
    // with terms containing lists etc. without desugaring them first
    fn desugar_term(&mut self, term: &Term) -> Result<Term, Diagnostics> {
        let name = Name::new("__temp");
        let rule = bend::fun::Rule {
            pats: vec![],
            body: term.clone(),
        };
        let temp = Definition {
            name: name.clone(),
            rules: vec![rule],
            source: bend::fun::Source::Generated,
        };

        self.book.defs.insert(name.clone(), temp);
        // let compile_opts = CompileOpts::default();
        // let diagnostics_cfg = DiagnosticsConfig::new(Severity::Allow, false);
        // let _ = desugar_book(&mut self.book, compile_opts, diagnostics_cfg, None)?;
        self.book.encode_builtins();
        
        let temp = self.book.defs.remove(&name).unwrap();
        Ok(temp.rule().body.clone())
    }
}