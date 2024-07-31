# object CircleCollider { r }

def check_point(x, y, r, px, py):
  d2 = (px - x)**2.0 + (py - y)**2.0
  return d2 <= (r**2.0)