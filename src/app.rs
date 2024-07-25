use std::path::Path;

use bend::{diagnostics, load_file_to_book, run_book, CompileOpts, RunOpts};
use bend::diagnostics::{Diagnostics, DiagnosticsConfig, Severity};
use bend::fun::{Book, Name, Pattern, Term};
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
        let cfg = DiagnosticsConfig::new(Severity::Allow, false);
        let fun = Term::rfold_lams(
            Term::Var { nam: Name::new("init") },
            [None, Some(Name::new("init")), None, None].into_iter());
        self.run(vec![fun])
    }

    pub fn tick(&self, state: &State) -> Result<State, Diagnostics> {
        let cfg = DiagnosticsConfig::new(Severity::Allow, false);
        let fun = Term::rfold_lams(
            Term::app(Term::Var { nam: Name::new("tick") }, state.clone()),
            [None, None, Some(Name::new("tick")), None].into_iter());
        self.run(vec![fun])
    }

    pub fn draw(&self, state: &State) -> Result<Vec<Command>, Diagnostics> {
        let fun = Term::rfold_lams(
            Term::app(Term::Var { nam: Name::new("draw") }, state.clone()),
            [None, None, None, Some(Name::new("draw"))].into_iter());
        let term = self.run(vec![fun])?;
        let cmds = FromTerm::from_term(&term).ok_or("Failed to parse".to_owned())?;
        Ok(cmds)
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