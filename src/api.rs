use bend::fun::{Name, Num, Pattern, Term};
use macroquad::color::*;
use crate::from_term::FromTerm;

/*
pub struct App {
    init: Port,
    tick: Port,
    draw: Port,
}
*/

/*
impl FromHvm for App {
    fn from_hvm(tree: &Tree) -> Option<App> {
        todo!()
    }
}
*/

#[derive(Debug)]
pub enum Command {
    Clear { color: Color },
    DrawLine { x1: f32, y1: f32, x2: f32, y2: f32, color: Color },
}

// FIME: Doesn't work unless the constructor is fully expanded!
// i.e. this function will be parse (λa (a @api/Color/tag r g b a)))
// but WON'T be able to parse (@api/Color r g b a), for example
impl FromTerm for Color {
    fn from_term(term: &Term) -> Option<Color> {
        let Term::Lam { tag: _, pat: _, bod } = term else {
            return None;
        };
        let (_, args) = try_decode_call(bod.as_ref())?;
        let Term::Ref { nam: tag } = args.get(0)? else {
            return None;
        };
        if tag != "Color/tag" {
            return None;
        }
        let r = FromTerm::from_term(args.get(1)?)?;
        let g = FromTerm::from_term(args.get(2)?)?;
        let b = FromTerm::from_term(args.get(3)?)?;
        let a = FromTerm::from_term(args.get(4)?)?;
        Some(Color { r, g, b, a })
    }
}

impl FromTerm for Command {
    fn from_term(term: &Term) -> Option<Command> {
        let Term::Lam { tag: _, pat: _, bod } = term else {
            return None;
        };
        let (_, args) = try_decode_call(bod.as_ref())?;
        let Term::Ref { nam: tag } = args.get(0)? else {
            return None;
        };
        // Can't use `match` here because 'tag.0' is private
        if tag == "Command/Clear/tag" {
            let color = FromTerm::from_term(args.get(1)?)?;
            Some(Command::Clear { color })
        } else if tag == "Command/DrawLine/tag" {
            let x1 = FromTerm::from_term(args.get(1)?)?;
            let y1 = FromTerm::from_term(args.get(2)?)?;
            let x2 = FromTerm::from_term(args.get(3)?)?;
            let y2 = FromTerm::from_term(args.get(4)?)?;
            let color = FromTerm::from_term(args.get(5)?)?;
            Some(Command::DrawLine { x1, y1, x2, y2, color })
        } else {
            None
        }
    }
}

fn try_decode_call(mut term: &Term) -> Option<(&Term, Vec<&Term>)> {
    match term {
        Term::App { tag: _, fun, arg } => {
            let (fun, mut args) = try_decode_call(fun)?;
            args.push(arg);
            Some((fun, args))
        }
        _ => Some((term, vec![])),
    }
}
