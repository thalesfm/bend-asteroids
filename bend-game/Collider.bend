type Collider:
  Circle { x, y, r }
  Point { x, y }

def check(col1, col2):
  match col1:
    case Collider/Circle:
      x1, y1, r1 = col1.x, col1.y, col1.r
    case Collider/Point:
      x1, y1, r1 = col1.x, col1.y, 0.0

  match col2:
    case Collider/Circle:
      x2, y2, r2 = col2.x, col2.y, col2.r
    case Collider/Point:
      x2, y2, r2 = col2.x, col2.y, 0.0

  return check_circle2circle(x1, y1, r1, x2, y2, r2)

def check_circle2circle(x1, y1, r1, x2, y2, r2):
  dist2 = (x1 - x2)**2.0 + (y1 - y2)**2.0
  return dist2 <= (r1 + r2)**2.0