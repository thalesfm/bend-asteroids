import ./State

object Lens { get, set }

# get : Lens a b -> a -> b
def get(lens):
  open Lens: lens
  return lens.get

# set : Lens a b -> b -> a -> a
def set(lens):
  open Lens: lens
  return lens.set

def over(lens, fun, val):
  open Lens: lens
  return set(lens, fun(get(lens, val)), val)

def compose(outerL, innerL):
  def get_(val):
    return get(innerL, get(outerL, val))
  def set_(inner, val):
    outer = get(outerL, val)
    outer = set(innerL, inner, outer)
    return set(outerL, outer, val)
  return Lens(get_, set_)

# zoom : Lens a b -> State b c -> State a c
def zoom(lens, run, outer):
  inner = get(lens, outer)
  (val, inner) = run(inner)
  outer = set(lens, inner, outer)
  return (val, outer)