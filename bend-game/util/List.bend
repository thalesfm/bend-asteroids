elem x (List/Nil) = 0
elem x (List/Cons y ys) = (| (== x y) (elem x ys))

def map(f, xs):
  match xs:
    case List/Nil:
      return List/Nil
    case List/Cons:
      return List/Cons(f(xs.head), map(f, xs.tail))