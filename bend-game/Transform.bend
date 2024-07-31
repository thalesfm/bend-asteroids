import ./util/Math

object Transform { x, y, rot }

def apply(xform, x, y):
  open Transform: xform
  xp = (       Math/cos_(xform.rot) * x) + (Math/sin_(xform.rot) * y) + xform.x
  yp = (-1.0 * Math/sin_(xform.rot) * x) + (Math/cos_(xform.rot) * y) + xform.y
  return xp, yp

def translate(dx, dy, xform):
  open Transform: xform
  return Transform(xform.x + dx, xform.y + dy, xform.rot)

def rotate(rot, xform):
  open Transform: xform
  return Transform(xform.x, xform.y, xform.rot + rot)

def front(xform):
  open Transform: xform
  x = -1.0 * Math/sin_(xform.rot)
  y = -1.0 * Math/cos_(xform.rot)
  return x, y

def right(xform):
  open Transform: xform
  x = Math/cos_(xform.rot)
  y = -1.0 * Math/sin_(xform.rot)
  return x, y

# object Transform { pos, rot, vel }
# xform = Transform