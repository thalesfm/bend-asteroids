// use bend::{compile_book, load_file_to_book, run_book, CompileOpts, RunOpts};
// use bend::fun::{Book, Name, Term};
// use bend::diagnostics::{Diagnostics, DiagnosticsConfig};
use hvm::hvm;
use ::hvm::ast;

fn run(book: &hvm::Book) {
    let net = hvm::GNet::new(1 << 29, 1 << 29);
    let mut tm = hvm::TMem::new(0, 1);

    let _main_id = book.defs.iter().position(|def| def.name == "main").unwrap();
    let init_id = book.defs.iter().position(|def| def.name == "init_").unwrap();
    let tick_id = book.defs.iter().position(|def| def.name == "tick").unwrap();

    // Want to evaluate:
    // b & _init ~ a & _update ~ (a b)

    // Get resources
    assert!(tm.get_resources(&net, 3, 1, 2));

    // Init a, b, ROOT
    net.vars_create(tm.vloc[0], hvm::NONE);
    net.vars_create(tm.vloc[1], hvm::NONE);
    net.vars_create(hvm::ROOT.get_val() as usize, hvm::NONE);

    // Create node (a b)
    net.node_create(tm.nloc[0],
        hvm::Pair::new(
            hvm::Port::new(hvm::VAR, tm.vloc[0] as u32),
            hvm::Port::new(hvm::VAR, tm.vloc[1] as u32)));

    // Push redex b ~ ROOT
    tm.rbag.push_redex(
        hvm::Pair::new(
            hvm::Port::new(hvm::VAR, tm.vloc[1] as u32),
            hvm::ROOT));

    // Push redex _init ~ a
    tm.rbag.push_redex(
        hvm::Pair::new(
            hvm::Port::new(hvm::REF, init_id as u32),
            hvm::Port::new(hvm::VAR, tm.vloc[0] as u32)));

    // Push redex tick ~ (a b)
    tm.rbag.push_redex(
        hvm::Pair::new(
            hvm::Port::new(hvm::REF, tick_id as u32),
            hvm::Port::new(hvm::CON, tm.nloc[0] as u32)));

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
    let path = "app.hvm";
    let code = std::fs::read_to_string(path).expect("Unable to read file");
    let book = ast::Book::parse(&code).unwrap().build();
    run(&book);
}
