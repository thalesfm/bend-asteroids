use std::fmt::Display;
use hvm::hvm;
use ::hvm::ast::*;

pub trait FromHVM<T>: Sized {
    fn from_hvm(value: T) -> Option<Self>;
}

impl<'a, T> FromHVM<&'a Net> for T where T: FromHVM<&'a Tree> {
    fn from_hvm(net: &'a Net) -> Option<Self> {
        // TODO: Check that rbag is empty
        return <T as FromHVM<&Tree>>::from_hvm(&net.root)
    }
}

impl FromHVM<&Tree> for u32 {
    fn from_hvm(tree: &Tree) -> Option<Self> {
        match tree {
            Tree::Num { val } => {
                let numb = hvm::Numb(val.0);
                Some(numb.get_u24())
            }
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

fn open_list_cons(tree: &Tree) -> (&Tree, &Tree) {
    match tree {
        Tree::Con { fst, snd: _ } => {
            match fst.as_ref() {
                Tree::Con { fst: _, snd } => {
                    match snd.as_ref() {
                        Tree::Con { fst: head, snd } => {
                            match snd.as_ref() {
                                Tree::Con { fst: tail, snd: _ } => (head.as_ref(), tail.as_ref()),
                                _ => panic!()
                            }
                        }
                        _ => panic!()
                    }
                }
                _ => panic!()
            }
        }
        _ => panic!()
    }
}

impl<'a, T> FromHVM<&'a Tree> for Vec<T> where T: FromHVM<&'a Tree> {
    fn from_hvm(tree: &'a Tree) -> Option<Self> {
        if !is_list(tree) {
            return None
        }
        let mut vec = Vec::new();
        let mut tree = tree;
        while is_list_cons(tree) {
            let (head, tail) = open_list_cons(tree);
            vec.push(T::from_hvm(head)?);
            tree = tail;
            // println!("tail: {}", tree.show());
            // println!("debg: {:?}", tree);
        }
        Some(vec)
    }
}