use hvm::ast::*;
use macroquad::color::*;
use crate::hvm::FromHvm;
use crate::hvm::decode::*;

#[derive(Debug)]
pub enum Command {
    Clear { color: Color },
    DrawLine { x1: f32, y1: f32, x2: f32, y2: f32, color: Color },
}

impl FromHvm for Color {
    fn from_hvm(tree: &Tree) -> Option<Color> {
        let (_, body) = try_decode_lam(&tree)?;
        let (_, args) = try_decode_call(body)?;
        match args.get(0)? {
            Tree::Ref { nam } => match nam.as_str() {
                "api/Color/tag" => {
                    let r = f32::from_hvm(args.get(1)?)?;
                    let g = f32::from_hvm(args.get(2)?)?;
                    let b = f32::from_hvm(args.get(3)?)?;
                    let a = f32::from_hvm(args.get(4)?)?;
                    Some(Color { r, g, b, a })
                }
                _ => None,
            }
            _ => None,
        }
    }
}

impl FromHvm for Command {
    fn from_hvm(tree: &Tree) -> Option<Command> {
        let (_, body) = try_decode_lam(&tree)?;
        let (_, args) = try_decode_call(body)?;
        match args.get(0)? {
            Tree::Ref { nam } => match nam.as_str() {
                "api/Command/Clear/tag" => {
                    let color = Color::from_hvm(args.get(1)?)?;
                    Some(Command::Clear { color })
                }
                "api/Command/DrawLine/tag" => {
                    let x1 = f32::from_hvm(args.get(1)?)?;
                    let y1 = f32::from_hvm(args.get(2)?)?;
                    let x2 = f32::from_hvm(args.get(3)?)?;
                    let y2 = f32::from_hvm(args.get(4)?)?;
                    let color = Color::from_hvm(args.get(5)?)?;
                    Some(Command::DrawLine { x1, y1, x2, y2, color })
                }
                _ => None,
            }
            _ => None,
        }
    }
}