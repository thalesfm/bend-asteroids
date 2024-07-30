use std::collections::BTreeMap;

use macroquad::prelude::*;
use ::hvm::{ast, hvm};

pub struct HvmState<'a> {
    book: hvm::Book,
    fids: BTreeMap::<String, hvm::Val>,
    gnet: hvm::GNet<'a>,
    tmem: hvm::TMem,
}

impl<'a> HvmState<'a> {
    pub fn new(book: hvm::Book) -> Self {
        let gnet = hvm::GNet::new(1 << 29, 1 << 29);
        let tmem = hvm::TMem::new(0, 1);
        let mut fids = BTreeMap::<String, hvm::Val>::new();
        // fids.insert("main".to_string(), 0);
        for (fid, def) in book.defs.iter().enumerate() {
            // if def.name != "main" {
            fids.insert(def.name.clone(), fid as hvm::Val);
            // }
        }
        Self { book, fids, gnet, tmem }
    }

    fn fid(&self, name: &str) -> Option<hvm::Val> {
        self.book.defs.iter().position(|def| def.name == name)?.try_into().ok()
    }

    pub fn new_var(&mut self) -> hvm::Port {
        if !self.tmem.get_resources(&self.gnet, 0, 0, 1) {
            panic!()
        }
        self.gnet.vars_create(self.tmem.vloc[0], hvm::NONE);
        hvm::Port::new(hvm::VAR, self.tmem.vloc[0] as u32)
    }

    pub fn get_ref(&self, name: &str) -> Option<hvm::Port> {
        hvm::Port::new(hvm::REF, self.fid(name)?).into()
    }

    pub fn con(&mut self, lhs: hvm::Port, rhs: hvm::Port) -> hvm::Port {
        if !self.tmem.get_resources(&self.gnet, 0, 1, 0) {
            panic!()
        }
        self.gnet.node_create(self.tmem.nloc[0], hvm::Pair::new(lhs, rhs));
        hvm::Port::new(hvm::CON, self.tmem.nloc[0] as u32)
    }

    pub fn app(&mut self, fun: hvm::Port, arg: hvm::Port) -> hvm::Port {
        let out = self.new_var();
        let con = self.con(arg, out);
        // if !self.tmem.get_resources(&self.gnet, 1, 0, 0) {
        //     panic!()
        // }
        self.tmem.link_pair(&self.gnet, hvm::Pair::new(fun, con));
        out
    }

    pub fn call(&mut self, fun: hvm::Port, args: Vec<hvm::Port>) -> hvm::Port {
        // let out = self.new_var();
        // let tup = args.into_iter().rfold(out, |tup, arg| self.con(arg, tup));
        // if !self.tmem.get_resources(&self.gnet, 1, 0, 0) {
        //    panic!()
        // }
        // self.tmem.link_pair(&self.gnet, hvm::Pair::new(fun, tup));
        args.into_iter().fold(fun, |fun, arg| self.app(fun, arg))
    }

    /*
    pub fn run(&mut self, args: Vec<ast::Net>) -> Option<ast::Net> {
        let main = self.get_ref("main")?;
        let args = args.iter().map(|arg| self.push_net(arg)).collect();
        let out = self.call(main, args);
        self.pop_net(out)
    }
    */

    pub fn pop_net(&mut self, port: hvm::Port) -> Option<ast::Net> {
        assert!(self.tmem.get_resources(&self.gnet, 1, 0, 0));
        self.gnet.vars_create(hvm::ROOT.get_val() as usize, hvm::NONE);
        self.tmem.rbag.push_redex(hvm::Pair::new(port, hvm::ROOT));
        self.tmem.evaluator(&self.gnet, &self.book);
        ast::Net::readback(&self.gnet, &self.book)
    }

    pub fn push_net(&mut self, net: &ast::Net) -> hvm::Port {
        let mut def = hvm::Def {
            name: "".to_owned(),
            safe: true,
            root: hvm::Port(0),
            rbag: vec![],
            node: vec![],
            vars: 0,
        };
        net.build(&mut def, &self.fids, &mut BTreeMap::new());
        assert!(self.tmem.get_resources(&self.gnet, 0, def.node.len(), def.vars as usize));
        for i in 0..def.vars {
            self.gnet.vars_create(self.tmem.vloc[i], hvm::NONE);
        }
        for i in 0..def.node.len() {
            self.gnet.node_create(self.tmem.nloc[i], def.node[i].adjust_pair(&self.tmem));
        }
        // Assuming net was constructed using `Net::readback` (as in `pop_net`)
        // it shouldn't have redexes, but it sometimes does?
        // assert!(def.rbag.len() == 0);
        for pair in &def.rbag {
            self.tmem.link_pair(&self.gnet, pair.adjust_pair(&self.tmem));
        }
        def.root.adjust_port(&self.tmem)
    }
}