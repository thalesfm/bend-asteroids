def compose(f, g):
  def fog(x):
    return f(g(x))
  return fog

def const(x):
  def fun(_):
    return x
  return fun