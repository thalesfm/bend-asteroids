mod convert;

// use bend::{compile_book, load_file_to_book, run_book, CompileOpts, RunOpts};
// use bend::fun::{Book, Name, Term};
// use bend::diagnostics::{Diagnostics, DiagnosticsConfig};
use crate::convert::FromHVM;
use hvm::hvm;
use ::hvm::ast;

fn run(book: &hvm::Book) {
    let net = hvm::GNet::new(1 << 29, 1 << 29);
    let mut tm = hvm::TMem::new(0, 1);
    let main_id = book.defs.iter().position(|def| def.name == "main").unwrap();
    net.vars_create(hvm::ROOT.get_val() as usize, hvm::NONE);
    tm.rbag.push_redex(hvm::Pair::new(hvm::Port::new(hvm::REF, main_id as u32), hvm::ROOT));
    tm.evaluator(&net, &book);

    if let Some(net) = ast::Net::readback(&net, &book) {
        // let val = Vec::<u32>::try_parse(&net);
        let val = Vec::<u32>::from_hvm(&net);
        println!("Result: {:?}\n", val);
        println!("Result: {}\n", net.show());
        println!("Result: {:?}", net);
    } else {
        panic!("Readback failed");
    }
}

fn run_init_update(book: &hvm::Book) {
    let net = hvm::GNet::new(1 << 29, 1 << 29);
    let mut tm = hvm::TMem::new(0, 1);

    let init_id = book.defs.iter().position(|def| def.name == "init").unwrap();
    let tick_id = book.defs.iter().position(|def| def.name == "tick").unwrap();

    // Want to evaluate:
    // b & _init ~ a & _update ~ (a b)

    // Get resources
    assert!(tm.get_resources(&net, 2, 1, 1));

    let var_a = hvm::Port::new(hvm::VAR, tm.vloc[0] as u32);
    let var_b = hvm::ROOT;

    // Init a, b
    net.vars_create(var_a.get_val() as usize, hvm::NONE);
    net.vars_create(var_b.get_val() as usize, hvm::NONE);

    // Create node (a b)
    let node_id = tm.nloc[0];
    let con_a_b = hvm::Port::new(hvm::CON, node_id as u32);
    net.node_create(node_id, hvm::Pair::new(var_a, hvm::ROOT));

    // Push redex _init ~ a
    let ref_init = hvm::Port::new(hvm::REF, init_id as u32);
    tm.rbag.push_redex(hvm::Pair::new(ref_init, var_a));

    // Push redex tick ~ (a ROOT)
    let ref_tick = hvm::Port::new(hvm::REF, tick_id as u32);
    tm.rbag.push_redex(hvm::Pair::new(ref_tick, con_a_b));

    // tm.rbag.push_redex(hvm::Pair::new(hvm::Port::new(hvm::REF, main_id as u32), hvm::ROOT));
    // net.vars_create(hvm::ROOT.get_val() as usize, hvm::NONE);
    tm.evaluator(&net, &book);

    if let Some(net) = ast::Net::readback(&net, &book) {
        println!("Result: {}", net.show());
        println!("Result (debug): {:?}", net);
    } else {
        panic!("Readback failed");
    }
}

fn main() {
    let path = "game/main.hvm";
    let code = std::fs::read_to_string(path).expect("Unable to read file");
    let book = ast::Book::parse(&code).unwrap().build();
    run(&book);
}
