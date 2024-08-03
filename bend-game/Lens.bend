object Lens { get, set }

def get(lens):
  open Lens: lens
  return lens.get

def set(lens):
  open Lens: lens
  return lens.set