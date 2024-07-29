use std::collections::BTreeMap;
use std::path::Path;

// use bend::run_book;
use bend::{AdtEncoding, CompileResult, compile_book};
use bend::{diagnostics, load_file_to_book, readback_hvm_net, CompileOpts, RunOpts};
use bend::diagnostics::{Diagnostics, DiagnosticsConfig, Severity};
use bend::fun::{Book, Name, Num, Pattern, Tag, Term};
use bend::fun::net_to_term::net_to_term;
use bend::fun::term_to_net::{Labels, term_to_hvm};
use bend::net::hvm_to_net::hvm_to_net;
use bend::imports::DefaultLoader;
use macroquad::prelude::*;
use ::hvm::{ast, hvm};

use crate::api::Command;
use crate::from_term::FromTerm;
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
        let pats = [None, Some(Name::new("init")), None, None, None];
        let term = Term::rfold_lams(
            Term::Var { nam: Name::new("init") },
            pats.into_iter());
        self.main(vec![term])
    }

    pub fn tick(&mut self, state: &State) -> Result<State, Diagnostics> {
        let pats = [None, None, Some(Name::new("tick")), None, None];
        let term = Term::rfold_lams(
            Term::app(Term::Var { nam: Name::new("tick") }, state.clone()),
            pats.into_iter());
        self.main(vec![term])
    }

    pub fn draw(&mut self, state: &State) -> Result<Vec<Command>, Diagnostics> {
        let pats = [None, None, None, Some(Name::new("draw")), None];
        let term = Term::rfold_lams(
            Term::app(Term::Var { nam: Name::new("draw") }, state.clone()),
            pats.into_iter());
        let cmds = self.main(vec![term])?;
        let cmds = FromTerm::from_term(&cmds)
            .ok_or("Failed to decode term".to_owned())?;
        Ok(cmds)
    }

    pub fn when(&mut self, key: KeyCode, state: &State) -> Result<State, Diagnostics> {
        let pats = [None, None, None, None, Some(Name::new("when"))];
        let term = Term::rfold_lams(
            Term::app(
                Term::app(
                    Term::Var { nam: Name::new("when") },
                    Term::Num { val: Num::U24(key as u32) }),
                state.clone()),
            pats.into_iter());
        self.main(vec![term])
    }

    fn main(&mut self, args: Vec<Term>) -> Result<Term, Diagnostics> {
        let mut labels = self.labels.clone();

        // Convert/push args
        let args = args.iter().map(|term| -> Result<_, Diagnostics> {
            let net = term_to_hvm(term, &mut labels)?;
            Ok(self.hvm.push_net(&net))
        });
        let args = args.collect::<Result<_, _>>()?;

        // Evaluate main
        let main = self.hvm.get_ref("main").unwrap();
        let result = self.hvm.call(main, args);
        let result = self.hvm.pop_net(result).ok_or("HVM Error".to_owned())?;

        // Readback
        let adt_encoding = CompileOpts::default().adt_encoding;
        let linear_readback = RunOpts::default().linear_readback;
        let (result, _) = readback_hvm_net(&result, &self.book, &labels, linear_readback, adt_encoding);
        Ok(result)
    }
}