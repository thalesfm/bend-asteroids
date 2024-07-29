def map(f, xs):
  match xs:
    case List/Nil:
      return List/Nil
    case List/Cons:
      return List/Cons(f(xs.head), map(f, xs.tail))

elem _ (List/Nil) = 0
elem x (List/Cons y ys) = (| (== x y) (elem x ys))

delete _ (List/Nil) = (List/Nil)
delete x (List/Cons y ys) = if (== x y) { ys } else { (List/Cons y (delete x ys)) }