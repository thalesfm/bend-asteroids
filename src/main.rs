// use bend::{compile_book, load_file_to_book, run_book, CompileOpts, RunOpts};
// use bend::fun::{Book, Name, Term};
// use bend::diagnostics::{Diagnostics, DiagnosticsConfig};
use hvm::hvm;
use ::hvm::ast;
use std::path::Path;

fn run(book: &hvm::Book) {
    let net = hvm::GNet::new(1 << 29, 1 << 29);
    let mut tm = hvm::TMem::new(0, 1);

    /*
    let port: hvm::Port = hvm::Port::new(0, hvm::ROOT.get_val() + 1);
    tmem.rbag.push_redex(hvm::Pair::new(hvm::Port::new(hvm::REF, main_id as u32), port));
    gnet.vars_create(port.get_val() as usize, hvm::NONE);
    tmem.evaluator(&gnet, &book);

    tmem.rbag.push_redex(hvm::Pair::new(hvm::Port::new(hvm::REF, port.get_val()), hvm::ROOT));
    gnet.vars_create(hvm::ROOT.get_val() as usize, hvm::NONE);
    tmem.evaluator(&gnet, &book);
    */

    /*
    let init_id = book.defs.iter().position(|def| def.name == "init_").unwrap();
    let update_id = book.defs.iter().position(|def| def.name == "update").unwrap();

    let var1 = hvm::Port(0xFFFFFFE8);
    let var2 = hvm::Port(0xFFFFFFF0);
    let root = hvm::ROOT;

    assert!(net.is_vars_free(var1.get_val() as usize));
    assert!(net.is_vars_free(var2.get_val() as usize));

    net.vars_create(var1.get_val() as usize, hvm::NONE);
    net.vars_create(var2.get_val() as usize, hvm::NONE);
    net.vars_create(root.get_val() as usize, hvm::NONE);

    // Reduce @init_ ~ var1
    let redex = hvm::Pair::new(hvm::Port::new(hvm::REF, init_id as u32), var1);
    tmem.rbag.push_redex(redex);
    tmem.evaluator(&net, &book);

    // Reduce @update ~ (var1 root)
    hvm::Port::new(hvm::CON, )
    let redex = hvm::Pair::new(root, var1);
    tmem.rbag.push_redex(redex);
    tmem.evaluator(&net, &book);
    */

    // Allocates needed nodes and vars.
    // let got = tmem.get_resources(&net, 0, 0, 0);
    // assert!(got);

    // Checks availability
    /*
    if net.node_load(a.get_val() as usize).0 == 0 || net.node_load(b.get_val() as usize).0 == 0 {
      panic!()
    }
    */

    // Stores new vars.
    // net.vars_create(tmem.vloc[0], hvm::NONE);
    // net.vars_create(tmem.vloc[1], hvm::NONE);
    // etc.

    // Stores new nodes.
    // net.node_create(tmem.nloc[0], Pair::new(Port::new(VAR, self.vloc[0] as u32), Port::new(VAR, self.vloc[1] as u32)));
    // net.node_create(tmem.nloc[1], Pair::new(Port::new(VAR, self.vloc[2] as u32), Port::new(VAR, self.vloc[3] as u32)));
    // etc.

    // Links.
    // tmem.link_pair(&net, Pair::new(Port::new(b.get_tag(), self.nloc[0] as u32), a1));
    // tmem.link_pair(&net, Pair::new(Port::new(b.get_tag(), self.nloc[1] as u32), a2));
    // etc.

    let main_id = book.defs.iter().position(|def| def.name == "main").unwrap();
    tm.rbag.push_redex(hvm::Pair::new(hvm::Port::new(hvm::REF, main_id as u32), hvm::ROOT));
    net.vars_create(hvm::ROOT.get_val() as usize, hvm::NONE);
    // tm.link_pair(&net, hvm::Pair::new(hvm::Port::new(hvm::REF, main_id as u32), hvm::ROOT));
    tm.evaluator(&net, &book);

    if let Some(net) = ast::Net::readback(&net, &book) {
        println!("Result: {}", net.show());
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
