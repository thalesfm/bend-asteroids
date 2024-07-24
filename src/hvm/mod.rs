pub mod decode;

pub use hvm::ast::Tree;
pub use hvm::hvm::{Book, Port};
use hvm::hvm::{Pair, GNet, TMem};

pub use self::decode::FromHvm;

use std::collections::BTreeMap;
// use std::marker::PhantomData;

pub struct HvmState<'a> {
    pub gnet: GNet<'a>,
    pub tmem: TMem,
    pub book: Book,
    // defs: ...
}

/*
pub struct HvmValue<'a> {
    _hvm: PhantomData<&'a HvmState<'a>>,
    port: Port,
}
*/

pub fn load_book_from_file(path: &str) -> Option<Book> {
    let code = std::fs::read_to_string(path).expect("Unable to read file");
    let book = hvm::ast::Book::parse(&code).unwrap();
    book.build().into()
}

impl<'a> HvmState<'a> {
    pub fn new(book: Book) -> Self {
        // let hvm_book = book.build();
        let gnet = GNet::new(1 << 29, 1 << 29);
        let tmem = TMem::new(0, 1);
        HvmState { gnet, tmem, book }
    }

    pub fn run(&mut self) -> Option<Tree> {
        self.pop_raw(self.get_ref("main")?)
    }

    // Slow!!
    fn fid(&self, name: &str) -> Option<u32> {
        let fid = self.book.defs.iter().position(|def| def.name == name)?;
        Some(fid as u32)
    }

    pub fn get_ref(&self, name: &str) -> Option<Port> {
        Some(Port::new(hvm::hvm::REF, self.fid(name)?))
    }

    pub fn pop<T: FromHvm>(&mut self, port: Port) -> Option<T> {
        FromHvm::from_hvm(&self.pop_raw(port)?)
    }

    pub fn pop_raw(&mut self, port: Port) -> Option<Tree> {
        // assert!(self.tmem.get_resources(&self.gnet, 1, 0, 0));
        // self.gnet.vars_create(hvm::hvm::ROOT.get_val() as usize, hvm::hvm::NONE);
        // self.tmem.rbag.push_redex(Pair::new(port, hvm::hvm::ROOT));
        // self.tmem.evaluator(&self.gnet, &self.book);
        // self.readback(hvm::hvm::ROOT)
        self.readback(port)
    }

    pub fn app(&mut self, fun: Port, arg: Port) -> Option<Port> {
        assert!(self.tmem.get_resources(&self.gnet, 1, 1, 1));
        let ret = Port::new(hvm::hvm::VAR, self.tmem.vloc[0] as u32);
        self.gnet.vars_create(self.tmem.vloc[0], hvm::hvm::NONE);
        self.gnet.node_create(self.tmem.nloc[0], Pair::new(arg, ret));
        self.tmem.rbag.push_redex(Pair::new(fun, Port::new(hvm::hvm::CON, self.tmem.nloc[0] as u32)));
        Some(ret)
    }

    pub fn apply(&mut self, fun: Port, args: &[Port]) -> Option<Tree> {
        /*
        let mut acc = fun;
        for arg in args {
            acc = self.app(acc, *arg)?;
        }
        Some(acc)
        */
        // /*
        assert!(self.tmem.get_resources(&self.gnet, 1, args.len(), 1));

        // let out = Port::new(hvm::hvm::VAR, self.tmem.vloc[0] as u32);
        // self.gnet.vars_create(self.tmem.vloc[0], hvm::hvm::NONE);
        let out = hvm::hvm::ROOT;
        self.gnet.vars_create(hvm::hvm::ROOT.get_val() as usize, hvm::hvm::NONE);

        let mut snd = out;
        for (i, arg) in args.into_iter().enumerate() {
            self.gnet.node_create(self.tmem.nloc[i], Pair::new(*arg, snd));
            snd = Port::new(hvm::hvm::CON, self.tmem.nloc[i] as u32);
        }

        self.tmem.rbag.push_redex(Pair::new(fun, snd));
        // self.tmem.evaluator(&self.gnet, &self.book);
        // self.pop_raw(hvm::hvm::ROOT)

        // Some(out)

        self.tmem.evaluator(&self.gnet, &self.book);
        self.readback(hvm::hvm::ROOT)
        // */
    }

    fn readback(&self, port: Port) -> Option<Tree> {
        let mut name_to_fid = BTreeMap::new();
        for (fid, def) in self.book.defs.iter().enumerate() {
            name_to_fid.insert(fid as hvm::hvm::Val, def.name.clone());
        }
        // let tree = Tree::readback(&self.gnet, port, &name_to_fid)?;
        let root = self.gnet.enter(port);
        let tree = Tree::readback(&self.gnet, root, &name_to_fid)?;
        Some(tree)
    }

    pub fn push_raw(&mut self, tree: &Tree) -> Port {
        let mut name_to_fid = BTreeMap::new();
        name_to_fid.insert("main".to_string(), 0); // ?????
        for (fid, def) in self.book.defs.iter().enumerate() {
            if def.name != "main" {
                name_to_fid.insert(def.name.clone(), fid as hvm::hvm::Val);
            }
        }

        let mut def = hvm::hvm::Def {
            name: "".to_string(),
            safe: true,
            root: Port(0),
            rbag: vec![],
            node: vec![],
            vars: 0,
        };
        let port = tree.build(&mut def, &name_to_fid, &mut BTreeMap::new());

        // Allocates needed nodes and vars.
        if !self.tmem.get_resources(&self.gnet, def.rbag.len() + 1, def.node.len(), def.vars as usize) {
            panic!()
        }

        // Stores new vars.
        for i in 0..def.vars {
            self.gnet.vars_create(self.tmem.vloc[i], hvm::hvm::NONE);
        }

        // Stores new nodes.
        for i in 0..def.node.len() {
            self.gnet.node_create(self.tmem.nloc[i], def.node[i].adjust_pair(&self.tmem));
        }

        // Links.
        for pair in &def.rbag {
            self.tmem.link_pair(&self.gnet, pair.adjust_pair(&self.tmem));
        }
        // tm.link_pair(net, hvm::Pair::new(def.root.adjust_port(tm), b));

        return port;
    }
}