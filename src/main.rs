mod api;
// mod app;
// mod hvm;
mod from_term;

use std::path::Path;
// use std::process::ExitCode;

use bend::{CompileOpts, RunOpts, load_file_to_book, run_book};
use bend::diagnostics::{Diagnostics, DiagnosticsConfig, Severity};
use bend::fun::{Book, Name, Pattern, Term};
use bend::imports::DefaultLoader;
use macroquad::prelude::*;

use api::Command;
// use app::App;
// use hvm::FromHvm;
use from_term::FromTerm;

type State = Term;

fn load_book(path: &Path, diag: DiagnosticsConfig) -> Result<Book, Diagnostics> {
    let package_loader = DefaultLoader::new(path);
    let mut book = load_file_to_book(path, package_loader, diag)?;
    // book.entrypoint = entrypoint.map(Name::new);
    book.entrypoint = None;
    Ok(book)
}

fn my_run_book(book: &Book, diag: DiagnosticsConfig, args: Vec<Term>) -> Option<Term> {
    let compile_opts = CompileOpts::default();
    let run_opts = RunOpts::default();

    let result = run_book(book.clone(), run_opts, compile_opts, diag, Some(args), "run-c").ok().unwrap();
    if let Some((term, stats, diags)) = result {
        // eprint!("{diags}");
        // println!("Result:\n{}", term.display_pretty(0));
        // println!("Result: {}", term);
        Some(term)
    } else {
        None
    }
}

fn window_conf() -> Conf {
    Conf {
        window_title: "Bend app".to_owned(),
        window_width: 640,
        window_height: 480,
        window_resizable: false,
        ..Default::default()
    }
}

fn init(book: &Book, diag: DiagnosticsConfig) -> Option<State> {
    let fun = Term::rfold_lams(
        Term::Var { nam: Name::new("init") },
        [None, Some(Name::new("init")), None, None].into_iter());
    my_run_book(book, diag, vec![fun])
}

fn tick(book: &Book, diag: DiagnosticsConfig, state: &State) -> Option<State> {
    let fun = Term::rfold_lams(
        Term::app(Term::Var { nam: Name::new("tick") }, state.clone()),
        [None, None, Some(Name::new("tick")), None].into_iter());
    my_run_book(book, diag, vec![fun])
}

fn draw(book: &Book, diag: DiagnosticsConfig, state: &State) -> Option<Vec<Command>> {
    let fun = Term::rfold_lams(
        Term::app(Term::Var { nam: Name::new("draw") }, state.clone()),
        [None, None, None, Some(Name::new("draw"))].into_iter());
    let term = my_run_book(book, diag, vec![fun])?;
    Vec::<Command>::from_term(&term)
}

#[macroquad::main(window_conf)]
async fn main() {
    let diagnostics_cfg = DiagnosticsConfig::new(Severity::Allow, false);
    let book = match load_book(Path::new("./bend-game/main.bend"), diagnostics_cfg) {
        Ok(book) => book,
        Err(diags) => {
            eprint!("{}", diags);
            return; // ExitCode::FAILURE;
        }
    };

    let mut state = init(&book, diagnostics_cfg).unwrap();
    loop {
        let commands = draw(&book, diagnostics_cfg, &state).unwrap_or(vec![]);
        println!("commands: {:?}", commands);

        for command in commands {
            match command {
                Command::Clear { color } => clear_background(color),
                Command::DrawLine { x1, y1, x2, y2, color } => draw_line(x1, y1, x2, y2, 5.0, color),
            }
        }

        // clear_background(BLACK);
        // draw_text(format!("state: {}", state.display_pretty(0)).as_str(), 64.0, 64.0, 30.0, WHITE);
        state = tick(&book, diagnostics_cfg, &state).unwrap();
        // println!("state: {:?}", state);
        next_frame().await
    }
}