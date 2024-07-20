
use hvm::hvm;
use ::hvm::ast;

pub trait FromHVM: Sized {
    fn from_hvm(net: &ast::Net) -> Option<Self>;
}

impl FromHVM for u32 {
    fn from_hvm(net: &ast::Net) -> Option<Self> {
        match &net.root {
            ast::Tree::Num { val } => {
                let numb = hvm::Numb(val.0);
                Some(numb.get_u24())
            }
            _ => None,
        }
    }
}

impl<'a, T> FromHVM for Vec<T> where T: FromHVM {
    fn from_hvm(_net: &ast::Net) -> Option<Self> {
        unimplemented!()
    }
}