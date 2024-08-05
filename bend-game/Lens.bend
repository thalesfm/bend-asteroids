import ./State
import ./util
from ./util import const

# type Lens:
#  Getter { getter }
#  Setter { setter }
#  GetSet { getter, setter }

object Lens {
  getter, # s -> a
  modify, # (a -> a) -> s -> s
}

def new(getter, setter):
  def modify(fun, val):
    return setter(fun(getter(val)), val)
    # inner = getter(outer)
    # inner = fun(inner)
    # return setter(inner, outer)
  return Lens(getter, modify)

def compose(outerL, innerL):
  open Lens: outerL
  open Lens: innerL

  getter = util/compose(innerL.getter, outerL.getter)
  modify = util/compose(outerL.modify, innerL.modify)

  # def getter(val):
  #   return innerL.getter(outerL.getter(val))

  # def modify(fun, val):
  #   return outerL.modify(innerL.modify(fun), val)

  # def modify(fun, val):
  #   def innerFun(inner):
  #     return innerL.modify(fun, inner)
  #   return outerL.modify(innerFun, val)

  return Lens(getter, modify)

def view(lens):
  open Lens: lens
  return lens.getter

# def views(lens, fun):
#   open Lens: lens
#   return ...

def over(lens):
  open Lens: lens
  return lens.modify

def set(lens):
  open Lens: lens
  # def setter(val):
  #   return lens.modify(const(val))
  def setter(inner, outer):
    return lens.modify(const(inner), outer)
  return setter

# def mapped():
#   ...

def use_(lens):
  return State/gets(view(lens))

# def uses(lens, fun):
#   return State/gets(views(lens))

def assign(lens, val):
  return State/modify(set(lens, val))

def modifying(lens, fun):
  return State/modify(over(lens, fun))

def zoom(lens, runInner):
  def runOuter(outer):
    # TODO: Use modify instead of set
    inner = view(lens, outer)
    (val, inner) = runInner(inner)
    outer = set(lens, inner, outer)
    return (val, outer)
  return runOuter