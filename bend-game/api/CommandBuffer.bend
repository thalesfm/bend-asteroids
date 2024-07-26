import ./Command

new = DiffList/new

push = DiffList/append

concat = DiffList/concat

def flush(buf):
  return List/map(Command/clone, DiffList/to_list(buf))

def List/map(f, xs):
  match xs:
    case List/Nil:
      return List/Nil
    case List/Cons:
      return List/Cons(f(xs.head), List/map(f, xs.tail))
  
def DiffList/concat(diff1, diff2):
  return lambda x: diff1(diff2(x))
