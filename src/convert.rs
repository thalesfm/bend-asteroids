// use std::fmt::Display;
use hvm::hvm;
use ::hvm::ast::*;
// use bend::diagnostics::Diagnostics;
// use bend::fun::{net_to_term::net_to_term, term_to_net::Labels, Term};
// use bend::net::hvm_to_net::hvm_to_net;

pub trait FromHvm: Sized {
    fn from_hvm(tree: &Tree) -> Option<Self>;
}

pub fn from_hvm<T: FromHvm>(net: &Net) -> Option<T> {
    // TODO: Check that rbag is empty
    return <T as FromHvm>::from_hvm(&net.root)
}

/*
pub fn hvm_to_term(net: &Net, book: &Book) -> Term {
    let net = hvm_to_net(&net);
    let mut diags = Diagnostics::default();
    return net_to_term(&net, book, &Labels::default(), false, &mut diags);
}
*/

impl FromHvm for f32 {
    fn from_hvm(tree: &Tree) -> Option<Self> {
        match tree {
            Tree::Num { val } => {
                Some(hvm::Numb(val.0).get_f24())
            }
            _ => None
        }
    }
}

impl FromHvm for u32 {
    fn from_hvm(tree: &Tree) -> Option<Self> {
        match tree {
            Tree::Num { val } => {
                Some(hvm::Numb(val.0).get_u24())
            }
            _ => None
        }
    }
}

impl<T> FromHvm for Vec<T> where T: FromHvm {
    fn from_hvm(tree: &Tree) -> Option<Self> {
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
    let (_, body) = try_decode_lam(&tree)?;
    let (_, args) = try_decode_call(&body)?;
    args.get(2).map(|x| *x)
}

type Pattern = Tree;

pub fn try_decode_lam(tree: &Tree) -> Option<(&Pattern, &Tree)> {
    match tree {
        Tree::Con { fst, snd } => {
            match **snd {
                Tree::Var { .. } => Some((snd, fst)),
                // TODO: More patterns?
                _ => None,
            }
        }
        _ => None
    }
}

pub fn try_decode_call(mut tree: &Tree) -> Option<(&Tree, Vec<&Tree>)> {
    let mut args = Vec::new();
    while let Tree::Con { fst, snd } = tree {
        args.push(fst.as_ref());
        tree = snd.as_ref();
    }
    Some((tree, args))
}