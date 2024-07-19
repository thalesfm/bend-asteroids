use bend::{compile_book, load_file_to_book, run_book, CompileOpts, RunOpts};
use bend::fun::{Book, Name, Term};
use bend::diagnostics::{Diagnostics, DiagnosticsConfig};
use std::path::Path;

fn load_book(path: &Path) -> Result<Book, Diagnostics> {
    let mut book = load_file_to_book(path)?;
    book.entrypoint = Some(Name::new("init"));
    Ok(book)
}

fn main() {
    /*
    // run_opts: CliRunOpts
    let linear = false; // ???
    let print_stats = false;

    // runArgs: RunArgs
    let pretty = true;
    // let run_opts = run_opts;
    // let comp_opts = ???
    // let warn_opts = ???
    let path = Path::new("./app.bend");
    let arguments: Option<Vec<bend::fun::Term>> = None;

    // cli: Cli
    // let mode = Mode::Run(run_args);
    let verbose = true;
    // let hvm_bin: Option<String> = None;
    // let entrypoint: Option<String> = Some("_init".to_string());

    let hvm_bin = "hvm".to_string();
    let run_cmd = "run";

    let mut book = load_book(&path).unwrap(); // ? not working for some reason
    let run_opts = RunOpts { linear_readback: linear, pretty, hvm_path: hvm_bin };
    let compile_opts = CompileOpts::default();
    let diagnostics_cfg = DiagnosticsConfig::default();

    // compile_book(&mut book, compile_opts.clone(), diagnostics_cfg, arguments.clone()).unwrap();

    match run_book(book, run_opts, compile_opts, diagnostics_cfg, arguments, run_cmd).unwrap() {
        Some((term, stats, diags)) => {
            println!("Success! Result:");
            println!("{}", term.display_pretty(0));
        }
        None => {
            println!("Failed :(")
        }
    };
    */

    let path = Path::new("./init.bend");
    let mut book = load_book(&path).unwrap();
    let state: Term;
    // book.entrypoint = Some(Name::new("foo"));
    let result = run_book(
        book,
        RunOpts::default(),
        CompileOpts::default(),
        DiagnosticsConfig::default(),
        None,
        "run");
    match result.unwrap() {
        Some((term, stats, diags)) => {
            println!("init() -> state: {}", term.display_pretty(0));
            state = term;
        }
        _ => panic!()
    };

    let path = Path::new("./update.bend");
    let book = load_book(&path).unwrap();
    let args = vec![state];
    let result = run_book(book, RunOpts::default(), CompileOpts::default(), DiagnosticsConfig::default(), Some(args), "run");
    let (term, _, _) = result.unwrap().unwrap();
    println!("update(state) -> {}", term.display_pretty(0));
    println!("Hello, world!");
}
