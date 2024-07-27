use std::collections::BTreeMap;
use std::path::Path;
use std::process::ExitCode;

// use bend::run_book;
use bend::{diagnostics, load_file_to_book, CompileOpts, RunOpts};
use bend::diagnostics::{Diagnostics, DiagnosticsConfig, Severity};
use bend::fun::{Book, Name, Num, Pattern, Tag, Term};
use bend::imports::DefaultLoader;
use macroquad::prelude::*;

use crate::api::*;
use crate::api::Command;
use crate::from_term::FromTerm;

pub type State = Term;

pub struct App {
    bend_book: Book,
    core_book: hvm::Book,
    labels: Labels,
}

impl App {
    pub fn load_from_file(path: &str) -> Result<App, Diagnostics> {
        let path = Path::new(path);
        let package_loader = DefaultLoader::new(path);
        let diagnostics_cfg = DiagnosticsConfig::new(Severity::Allow, false);
        let mut bend_book = load_file_to_book(path, package_loader, diagnostics_cfg)?;
        // book.entrypoint = entrypoint.map(Name::new);
        bend_book.entrypoint = None;

        let compile_opts = CompileOpts::default();
        let diagnostics_cfg = DiagnosticsConfig::new(Severity::Allow, false);
        let CompileResult { hvm_book: core_book, labels, diagnostics: _ } =
            compile_book(&mut bend_book, compile_opts.clone(), diagnostics_cfg, None)?;
        let core_book: hvm::Book = core_book.build();

        Ok(App { bend_book, core_book, labels })
    }

    pub fn init(&self) -> Result<State, Diagnostics> {
        // println!("App::init called");
        let arg = Term::rfold_lams(
            Term::Var { nam: Name::new("init") },
            [None, Some(Name::new("init")), None, None, None].into_iter());
        self.run(vec![arg])
    }

    pub fn tick(&self, state: &State) -> Result<State, Diagnostics> {
        // println!("App::tick called");
        let arg = Term::rfold_lams(
            Term::app(Term::Var { nam: Name::new("tick") }, state.clone()),
            [None, None, Some(Name::new("tick")), None, None].into_iter());
        self.run(vec![arg])
    }

    pub fn draw(&self, state: &State) -> Result<Vec<Command>, Diagnostics> {
        // println!("App::draw called");
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
        // println!("App::when called");
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
        // let diagnostics_cfg = DiagnosticsConfig::new(Severity::Allow, false);
        let run_opts = RunOpts::default();

        let mut labels = self.labels.clone();
        let args: Vec<ast::Net> = args.iter()
            .map(|term| term_to_hvm(&term, &mut labels))
            .collect::<Result<_, _>>()?;
        let net = run(&self.core_book, args).ok_or("Fuck".to_owned())?;

        let (term, _diags) =
            readback_hvm_net(&net, &self.bend_book, &labels, run_opts.linear_readback, compile_opts.adt_encoding);

        Ok(term)
    }
}

use bend::{AdtEncoding, CompileResult, compile_book};
use bend::fun::net_to_term::net_to_term;
use bend::fun::term_to_net::{Labels, term_to_hvm};
use bend::net::hvm_to_net::hvm_to_net;

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

use ::hvm::{ast, hvm};

pub fn run(book: &hvm::Book, args: Vec<ast::Net>) -> Option<ast::Net> {
    let net = hvm::GNet::new(1 << 29, 1 << 29);
    let mut tm = hvm::TMem::new(0, 1);

    let mut fids = BTreeMap::<String, hvm::Val>::new();
    fids.insert("main".to_string(), 0);
    for (fid, def) in book.defs.iter().enumerate() {
        if def.name != "main" {
            fids.insert(def.name.clone(), fid as hvm::Val);
        }
    }

    let main_id = book.defs.iter().position(|def| def.name == "main").unwrap();
    let main = hvm::Port::new(hvm::REF, main_id as u32);

    // root <- fresh()
    // tupl <- root
    assert!(tm.get_resources(&net, 0, 0, 1));
    net.vars_create(tm.vloc[0], hvm::NONE);
    let root = hvm::Port::new(hvm::VAR, tm.vloc[0] as u32);
    let mut tupl = root;

    for arg in args.iter().rev() {
        // Build & create arg
        let mut def = hvm::Def {
            name: "".to_string(),
            safe: true,
            root: hvm::Port(0),
            rbag: vec![],
            node: vec![],
            vars: 0,
        };

        arg.build(&mut def, &fids, &mut BTreeMap::new());
        
        assert!(tm.get_resources(&net, def.rbag.len(), def.node.len(), def.vars as usize));

        for i in 0..def.vars {
            net.vars_create(tm.vloc[i], hvm::NONE);
        }
        for i in 0..def.node.len() {
            net.node_create(tm.nloc[i], def.node[i].adjust_pair(&tm));
        }

        // TODO: Check if `rbag` is ever not empty. Otherwise, this is unnecessary
        for pair in &def.rbag {
            tm.link_pair(&net, pair.adjust_pair(&tm));
        }

        // tm.link_pair(net, Pair::new(def.root.adjust_port(tm), b));        
        let root = def.root.adjust_port(&tm);

        // port <- hvm: (arg port)
        assert!(tm.get_resources(&net, 0, 1, 0));
        net.node_create(tm.nloc[0], hvm::Pair::new(root, tupl));
        tupl = hvm::Port::new(hvm::CON, tm.nloc[0] as u32);
    }

    // @main ~ tupl (link)
    // root ~ ROOT  (push_redex)
    assert!(tm.get_resources(&net, 2, 0, 0));
    net.vars_create(hvm::ROOT.get_val() as usize, hvm::NONE);
    tm.rbag.push_redex(hvm::Pair::new(root, hvm::ROOT));
    tm.link_pair(&net, hvm::Pair::new(main, tupl));

    // Evaluates
    tm.evaluator(&net, &book);
    
    ast::Net::readback(&net, book)
}