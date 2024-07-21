mod convert;

// use bend::{compile_book, load_file_to_book, run_book, CompileOpts, RunOpts};
// use bend::fun::{Book, Name, Term};
// use bend::diagnostics::{Diagnostics, DiagnosticsConfig};
use crate::convert::FromHvm;
use hvm::hvm;
use ::hvm::ast;
use std::collections::BTreeMap;

pub fn build(tree: &ast::Tree, net: &hvm::GNet, tm: &mut hvm::TMem, book: &ast::Book) -> hvm::Port {
    let mut name_to_fid = BTreeMap::new();
    let mut fid_to_name = BTreeMap::new();
    fid_to_name.insert(0, "main".to_string());
    name_to_fid.insert("main".to_string(), 0);
    for (_i, (name, _)) in book.defs.iter().enumerate() {
      if name != "main" {
        fid_to_name.insert(name_to_fid.len() as hvm::Val, name.clone());
        name_to_fid.insert(name.clone(), name_to_fid.len() as hvm::Val);
      }
    }
    let mut def = hvm::Def {
      name: "".to_string(),
      safe: true,
      root: hvm::Port(0),
      rbag: vec![],
      node: vec![],
      vars: 0,
    };
    let port = tree.build(&mut def, &name_to_fid, &mut BTreeMap::new());

    // Allocates needed nodes and vars.
    if !tm.get_resources(net, def.rbag.len() + 1, def.node.len(), def.vars as usize) {
        panic!()
    }

    // Stores new vars.
    for i in 0..def.vars {
      net.vars_create(tm.vloc[i], hvm::NONE);
      //println!("vars_create vars_loc[{:04X}] {:04X}", i, self.vloc[i]);
    }

    // Stores new nodes.
    for i in 0..def.node.len() {
      net.node_create(tm.nloc[i], def.node[i].adjust_pair(tm));
      //println!("node_create node_loc[{:04X}] {:016X}", i-1, def.node[i].0);
    }

    // Links.
    for pair in &def.rbag {
      tm.link_pair(net, pair.adjust_pair(tm));
    }
    // tm.link_pair(net, hvm::Pair::new(def.root.adjust_port(tm), b));

    return port;
}

fn run(ast_book: &ast::Book, hvm_book: &hvm::Book) {
    let net = hvm::GNet::new(1 << 29, 1 << 29);
    let mut tm = hvm::TMem::new(0, 1);

    let init_id = hvm_book.defs.iter().position(|def| def.name == "init").unwrap();
    let tick_id = hvm_book.defs.iter().position(|def| def.name == "tick").unwrap();

    // Want to evaluate:
    // @init ~ ROOT
    assert!(tm.get_resources(&net, 1, 0, 1));
    net.vars_create(hvm::ROOT.get_val() as usize, hvm::NONE);
    tm.rbag.push_redex(hvm::Pair::new(hvm::Port::new(hvm::REF, init_id as u32), hvm::ROOT));
    tm.evaluator(&net, &hvm_book);

    let mut state: hvm::Port;
    if let Some(ret) = ast::Net::readback(&net, &hvm_book) {
        println!("state0: {:?}", u32::from_hvm(&ret));
        state = build(&ret.root, &net, &mut tm, ast_book);
    } else {
        panic!("Readback failed");
    }

    for i in 1..10 {
        // Want to evaluate:
        // @tick ~ (state ROOT)
        assert!(tm.get_resources(&net, 1, 1, 0));
        net.vars_create(hvm::ROOT.get_val() as usize, hvm::NONE);
        net.node_create(tm.nloc[1], hvm::Pair::new(state, hvm::ROOT)); // (state ROOT)
        // net.node_create(tm.nloc[1], hvm::Pair::new(state0, hvm::ROOT));
        tm.rbag.push_redex(hvm::Pair::new(hvm::Port::new(hvm::REF, tick_id as u32), hvm::Port::new(hvm::CON, tm.nloc[1] as u32))); // _update ~ (state {state' ROOT})
        tm.evaluator(&net, &hvm_book);

        if let Some(ret) = ast::Net::readback(&net, &hvm_book) {
            println!("state{}: {:?}", i, u32::from_hvm(&ret));
            state = build(&ret.root, &net, &mut tm, ast_book);
        } else {
            panic!("Readback failed");
        }
    }
}

fn main() {
    let path = "game/main.hvm";
    let code = std::fs::read_to_string(path).expect("Unable to read file");
    let ast_book = ast::Book::parse(&code).unwrap();
    let hvm_book = ast_book.build();
    run(&ast_book, &hvm_book);
}
