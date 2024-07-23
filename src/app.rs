// use crate::convert::FromHvm;
// use ::hvm::{ast, hvm};
use std::collections::BTreeMap;
use crate::hvm;

type State = hvm::Tree;

pub struct App<'a> {
    hvm: hvm::HvmState<'a>,
}

impl<'a> App<'a> {
    pub fn load_from_file(path: &str) -> Option<App> {
        let book = hvm::load_book_from_file(path)?;
        let hvm = hvm::HvmState::new(book);
        Some(App { hvm })
    }

    pub fn init(&mut self) -> Option<State> {
        let init = self.hvm.get_ref("init")?;
        self.hvm.pop_raw(init)
        // let state = self.hvm.apply(init, &[])?;
        // self.hvm.pop_raw(state)
    }

    pub fn tick(&mut self, state: State) -> Option<State> {
        let update = self.hvm.get_ref("tick")?;
        let state0 = self.hvm.push_raw(&state);
        let state1 = self.hvm.app(update, state0)?;
        self.hvm.pop_raw(state1)
    }

    pub fn draw(&mut self, state: State) -> Option<State> {
        let draw = self.hvm.get_ref("draw")?;
        let state = self.hvm.push_raw(&state);
        let result = self.hvm.app(draw, state)?;
        self.hvm.pop_raw(result)
    }
}