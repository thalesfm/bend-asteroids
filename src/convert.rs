use bend::fun::{Num, Pattern, Term};

pub trait FromTerm: Sized {
    fn from_term(term: &Term) -> Option<Self>;
}

pub trait IntoTerm {
    fn into_term(value: Self) -> Term;
}

impl FromTerm for Term {
    fn from_term(term: &Term) -> Option<Self> {
        Some(term.clone())
    }
}

impl IntoTerm for Term {
    fn into_term(term: Term) -> Term {
        term
    }
}

impl FromTerm for u32 {
    fn from_term(term: &Term) -> Option<Self> {
        match *term {
            Term::Num { val: Num::U24(val) } => Some(val),
            _ => None,
        }
    }
}

impl IntoTerm for u32 {
    fn into_term(value: Self) -> Term {
        Term::Num { val: Num::U24(value) }
    }
}

impl FromTerm for i32 {
    fn from_term(term: &Term) -> Option<Self> {
        match *term {
            Term::Num { val: Num::I24(val) } => Some(val),
            _ => None,
        }
    }
}

impl IntoTerm for i32 {
    fn into_term(value: Self) -> Term {
        Term::Num { val: Num::I24(value) }
    }
}

impl FromTerm for f32 {
    fn from_term(term: &Term) -> Option<Self> {
        match *term {
            Term::Num { val: Num::F24(val) } => Some(val),
            _ => None,
        }
    }
}

impl IntoTerm for f32 {
    fn into_term(value: Self) -> Term {
        Term::Num { val: Num::F24(value) }
    }
}

impl FromTerm for String {
    fn from_term(term: &Term) -> Option<Self> {
        match term {
            Term::Str { val } => Some(val.to_string()),
            _ => None,
        }
    }
}

// TODO
// impl IntoTerm for String { ... }

impl<T: FromTerm> FromTerm for Vec<T> {
    fn from_term(term: &Term) -> Option<Self> {
        match term {
            Term::List { els } => {
                els.iter().map(FromTerm::from_term).collect::<Option<Vec<_>>>()
            }
            _ => None,
        }
    }
}

// TODO
// impl IntoTerm for Vec<T> { ... }