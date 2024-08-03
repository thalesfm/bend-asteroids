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

# zoom : Lens a b -> State b c -> State a c
def zoom(lens, run, outer):
  inner = get(lens, outer)
  (val, inner) = run(inner)
  outer = set(lens, inner, outer)
  return (val, outer)