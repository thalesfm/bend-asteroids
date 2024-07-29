def rem(x, y):
  return x % y

def mod(x, y):
  if x > 0:
    return x % y
  else:
    return x % y + y

def sin_(x):
  x = mod(x, 2.0*Math/PI) - Math/PI
  return -1.0*x + x**3.0/6.0 - x**5.0/120.0 + x**7.0/5040.0

def cos_(x):
  x = mod(x, 2.0*Math/PI) - Math/PI
  return -1.0 + x**2.0/2.0 - x**4.0/24.0 + x**6.0/720.0 - x**8.0/40320.0