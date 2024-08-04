import ./bend-game/Lens
from ./bend-game/Lens import (over, view, set)

object Foo { val }

object Bar { foo }

def main():
  foo = Foo(10.0)
  bar = Bar(foo)

  # Working
  # val = view(Lens/compose(Bar/fooL, Foo/valL), bar)
  # val = val + 1.0
  # bar = set(Lens/compose(Bar/fooL, Foo/valL), val, bar)

  # Borken: lambda keeps going!
  # bar = over(Lens/compose(Bar/fooL, Foo/valL), lambda x: x + 1.0, bar)

  # Working
  # def fun(foo):
  #   return Foo(12.0)
  # bar = over(Bar/fooL, fun, bar)

  # Working
  def add1(x):
    return x + 1.0
  bar = over(Lens/compose(Bar/fooL, Foo/valL), add1, bar)

  val = view(Lens/compose(Bar/fooL, Foo/valL), bar)
  return val

def Foo/valL():
  def getter(foo):
    open Foo: foo
    return foo.val
  def setter(val, foo):
    return Foo(val)
  return Lens/new(getter, setter)

def Bar/fooL():
  def getter(bar):
    open Bar: bar
    return bar.foo
  def setter(foo, bar):
    return Bar(foo)
  return Lens/new(getter, setter)
