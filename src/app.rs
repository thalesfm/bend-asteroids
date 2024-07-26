use std::path::Path;

// use bend::run_book;
use bend::{diagnostics, load_file_to_book, CompileOpts, RunOpts};
use bend::diagnostics::{Diagnostics, DiagnosticsConfig, Severity};
use bend::fun::{Book, Name, Num, Pattern, Term};
use bend::imports::DefaultLoader;
use macroquad::prelude::*;

use crate::api::*;
use crate::api::Command;
use crate::from_term::FromTerm;

pub type State = Term;

pub struct App {
    book: Book,
}

impl App {
    pub fn load_from_file(path: &str) -> Result<App, Diagnostics> {
        let path = Path::new(path);
        let package_loader = DefaultLoader::new(path);
        let diagnostics_cfg = DiagnosticsConfig::new(Severity::Allow, false);
        let mut book = load_file_to_book(path, package_loader, diagnostics_cfg)?;
        // book.entrypoint = entrypoint.map(Name::new);
        book.entrypoint = None;
        Ok(App { book })
    }

    pub fn init(&self) -> Result<State, Diagnostics> {
        let arg = Term::rfold_lams(
            Term::Var { nam: Name::new("init") },
            [None, Some(Name::new("init")), None, None, None].into_iter());
        self.run(vec![arg])
    }

    pub fn tick(&self, state: &State) -> Result<State, Diagnostics> {
        let arg = Term::rfold_lams(
            Term::app(Term::Var { nam: Name::new("tick") }, state.clone()),
            [None, None, Some(Name::new("tick")), None, None].into_iter());
        self.run(vec![arg])
    }

    pub fn draw(&self, state: &State) -> Result<Vec<Command>, Diagnostics> {
        let arg = Term::rfold_lams(
            Term::app(Term::Var { nam: Name::new("draw") }, state.clone()),
            [None, None, None, Some(Name::new("draw")), None].into_iter());
        let term = self.run(vec![arg])?;
        let cmds = FromTerm::from_term(&term)
            .ok_or_else(|| {
                println!("Failed to parse term: {}\n", term.display_pretty(0));
                "Failed to parse".to_owned()
            })?;
        Ok(cmds)
    }

    pub fn when(&self, key: KeyCode, state: &State) -> Result<State, Diagnostics> {
        // Term::call( ... );
        let arg = Term::rfold_lams(
            Term::app(
                Term::app(
                    Term::Var { nam: Name::new("when") },
                    Term::Num { val: Num::U24(key as u32) }),
                state.clone()),
            [None, None, None, None, Some(Name::new("when"))].into_iter());
        self.run(vec![arg])
    }

    fn run(&self, args: Vec<Term>) -> Result<Term, Diagnostics> {
        let compile_opts = CompileOpts::default();
        let diagnostics_cfg = DiagnosticsConfig::new(Severity::Allow, false);
        let run_opts = RunOpts::default();
        let result = run_book(self.book.clone(), run_opts, compile_opts, diagnostics_cfg, Some(args), "run-c")?;
        let (term, _, _) = result.ok_or("Run failed".to_owned())?;
        Ok(term)
    }
}

use bend::{AdtEncoding, CompileResult, compile_book};
use bend::fun::net_to_term::net_to_term;
use bend::fun::term_to_net::{Labels, term_to_hvm};
use bend::net::hvm_to_net::hvm_to_net;

pub fn run_book(
    mut book: Book,
    run_opts: RunOpts,
    compile_opts: CompileOpts,
    diagnostics_cfg: DiagnosticsConfig,
    args: Option<Vec<Term>>,
    cmd: &str,
) -> Result<Option<(Term, String, Diagnostics)>, Diagnostics> {
    println!("\nFrame:");
    let start = std::time::Instant::now();
    let CompileResult { hvm_book: core_book, labels, diagnostics: _ } =
        compile_book(&mut book, compile_opts.clone(), diagnostics_cfg, args)?;
    println!("- Compile:  {:.2} ms", 1000.0*start.elapsed().as_secs_f32());

    let start = std::time::Instant::now();
    let (net, stats) = run_hvm(&core_book, cmd, &run_opts).ok_or("Fuck".to_owned())?;
    println!("- Run:      {:.2} ms", 1000.0*start.elapsed().as_secs_f32());

    let start = std::time::Instant::now();
    let (term, diags) =
        readback_hvm_net(&net, &book, &labels, run_opts.linear_readback, compile_opts.adt_encoding);
    println!("- Readback: {:.2} ms", 1000.0*start.elapsed().as_secs_f32());

    Ok(Some((term, stats, diags)))
}

pub fn readback_hvm_net(
    net: &::hvm::ast::Net,
    book: &Book,
    labels: &Labels,
    linear: bool,
    adt_encoding: AdtEncoding,
) -> (Term, Diagnostics) {
    let mut diags = Diagnostics::default();
    let net = hvm_to_net(net);
    let mut term = net_to_term(&net, book, labels, linear, &mut diags);
    #[allow(clippy::mutable_key_type)] // Safe to allow, we know how `Name` works.
    let recursive_defs = book.recursive_defs();
    term.expand_generated(book, &recursive_defs);
    term.resugar_strings(adt_encoding);
    term.resugar_lists(adt_encoding);
    (term, diags)
}

fn run_hvm(book: &::hvm::ast::Book, cmd: &str, run_opts: &RunOpts) -> Option<(ast::Net, String)> {
    let book = book.build();
    let net = run(&book)?;
    Some((net, "".to_owned()))
}

use ::hvm::{ast, hvm};

pub fn run(book: &hvm::Book) -> Option<ast::Net> {
    // Initializes the global net
    let net = hvm::GNet::new(1 << 29, 1 << 29);
  
    // Initializes threads
    let mut tm = hvm::TMem::new(0, 1);
  
    // Creates an initial redex that calls main
    let main_id = book.defs.iter().position(|def| def.name == "main").unwrap();
    tm.rbag.push_redex(hvm::Pair::new(hvm::Port::new(hvm::REF, main_id as u32), hvm::ROOT));
    net.vars_create(hvm::ROOT.get_val() as usize, hvm::NONE);
  
    // Evaluates
    tm.evaluator(&net, &book);
    
    ast::Net::readback(&net, book)
}