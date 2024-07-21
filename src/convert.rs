// use std::fmt::Display;
use hvm::hvm;
use ::hvm::ast::*;

pub trait FromHvm<T>: Sized {
    fn from_hvm(value: T) -> Option<Self>;
}

pub trait TreeExt {
    // Var { nam: String },
    // fn r#ref(self: Self) -> String;
    // Era,
    // Num { val: Numb },
    // Con { fst: Box<Tree>, snd: Box<Tree> },
    fn uncon(self: &Self) -> Option<(&Tree, &Tree)>;
    // Dup { fst: Box<Tree>, snd: Box<Tree> },
    // Opr { fst: Box<Tree>, snd: Box<Tree> },
    // Swi { fst: Box<Tree>, snd: Box<Tree> },
}

impl TreeExt for Tree {
    fn uncon<'a>(self: &Tree) -> Option<(&Tree, &Tree)> {
        match self {
            Tree::Con { fst, snd } => Some((fst.as_ref(), snd.as_ref())),
            _ => None,
        }
    }
}

impl<'a, T> FromHvm<&'a Net> for T where T: FromHvm<&'a Tree> {
    fn from_hvm(net: &'a Net) -> Option<Self> {
        // TODO: Check that rbag is empty
        return <T as FromHvm<&Tree>>::from_hvm(&net.root)
    }
}

impl FromHvm<&Tree> for u32 {
    fn from_hvm(tree: &Tree) -> Option<Self> {
        let val = match tree {
            Tree::Num { val } => Some(val),
            _ => None,
        }?;
        let numb = hvm::Numb(val.0);
        numb.get_u24().into()
    }
}

impl<'a, T> FromHvm<&'a Tree> for Vec<T> where T: FromHvm<&'a Tree> {
    fn from_hvm(tree: &'a Tree) -> Option<Self> {
        if !is_list(tree) {
            return None
        }
        let mut vec = Vec::new();
        let mut lst = tree;
        while is_list_cons(lst) {
            let head = list_head(lst)?;
            vec.push(T::from_hvm(head)?);
            lst = list_tail(lst)?;
        }
        vec.into()
    }
}

fn is_list(tree: &Tree) -> bool {
    is_list_cons(tree) || is_list_nil(tree)
}

fn is_list_cons(tree: &Tree) -> bool {
    match tree {
        Tree::Con { fst, snd: _ } => {
            match fst.as_ref() {
                Tree::Con { fst, snd: _ } => {
                    match fst.as_ref() {
                        Tree::Ref { nam } => nam == "List/Cons/tag",
                        _ => false
                    }
                }
                _ => false
            }
        }
        _ => false
    }
}

fn is_list_nil(tree: &Tree) -> bool {
    match &tree {
        Tree::Ref { nam} => nam == "List/Nil",
        _ => false
    }
}

fn list_head(tree: &Tree) -> Option<&Tree> {
    if !is_list_cons(tree) {
        return None;
    }
    tree.uncon()?.0.uncon()?.1.uncon()?.0.into()
}

fn list_tail(tree: &Tree) -> Option<&Tree> {
    if !is_list_cons(tree) {
        return None;
    }
    tree.uncon()?.0.uncon()?.1.uncon()?.1.uncon()?.0.into()

}