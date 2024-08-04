import ./State

object Lens {
  getter,
  setter,
}

def new(getter, setter):
  return Lens(getter, setter)

def view(lens):
  open Lens: lens
  return lens.getter

def set(lens):
  open Lens: lens
  return lens.setter

def over(lens, fun, val):
  open Lens: lens
  return set(lens, fun(view(lens, val)), val)

def compose(outerL, innerL):
  def getter(val):
    return view(innerL, view(outerL, val))
  def setter(inner, val):
    outer = set(innerL, inner, view(outerL, val))
    return set(outerL, outer, val)
  return Lens(getter, setter)

# zoom : Lens a b -> State b c -> State a c
def zoom(lens, run1):
  def run2(outer):
    inner = view(lens, outer)
    (val, inner) = run1(inner)
    outer = set(lens, inner, outer)
    return (val, outer)
  return run2