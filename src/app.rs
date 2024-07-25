use std::path::Path;

use bend::{diagnostics, load_file_to_book, run_book, CompileOpts, RunOpts};
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