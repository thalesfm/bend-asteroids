from ./actions import *
from ./api/Color import *
import ./Collider
import ./CommandWriter
import ./PhysicsBody
import ./Transform

object Asteroid { xform, pbody, r }

def new(x, y, vx, vy):
  xform = Transform(x, y, 0.0)
  pbody = PhysicsBody(vx, vy, 0.01)
  return Asteroid(xform, pbody, 30.0)

def coll(asteroid):
  open Asteroid: asteroid
  xform = asteroid.xform
  open Transform: xform
  return Collider/Circle(xform.x, xform.y, asteroid.r)

def tick(asteroid):
  open Asteroid: asteroid
  xform = asteroid.xform
  pbody = asteroid.pbody
  xform = PhysicsBody/step(1.0, xform, pbody)
  return Asteroid(xform, pbody, asteroid.r)

def draw(asteroid):
  open Asteroid: asteroid
  xform = asteroid.xform
  scale = asteroid.r / 14.0

  x0, y0 = Transform/apply(xform, -14.0 * scale,  -7.0 * scale)
  x1, y1 = Transform/apply(xform,  -5.0 * scale, -13.0 * scale)
  x2, y2 = Transform/apply(xform,  -1.0 * scale,  -7.0 * scale)
  x3, y3 = Transform/apply(xform,   2.0 * scale, -13.0 * scale)
  x4, y4 = Transform/apply(xform,  14.0 * scale,  -3.0 * scale)
  x5, y5 = Transform/apply(xform,  14.0 * scale,   6.0 * scale)
  x6, y6 = Transform/apply(xform,   4.0 * scale,  14.0 * scale)
  x7, y7 = Transform/apply(xform,  -3.0 * scale,  14.0 * scale)
  x8, y8 = Transform/apply(xform, -14.0 * scale,   6.0 * scale)
  x9, y9 = Transform/apply(xform, -14.0 * scale,   1.0 * scale)
  xf, yf = Transform/apply(xform,  -3.0 * scale,   0.0 * scale)

  with CommandWriter:
    * <- draw_line(x0, y0, x1, y1, WHITE)
    * <- draw_line(x1, y1, x2, y2, WHITE)
    * <- draw_line(x2, y2, x3, y3, WHITE)
    * <- draw_line(x3, y3, x4, y4, WHITE)
    * <- draw_line(x4, y4, x5, y5, WHITE)
    * <- draw_line(x5, y5, x6, y6, WHITE)
    * <- draw_line(x6, y6, x7, y7, WHITE)
    * <- draw_line(x7, y7, x8, y8, WHITE)
    * <- draw_line(x8, y8, x9, y9, WHITE)
    * <- draw_line(x9, y9, xf, yf, WHITE)
    * <- draw_line(xf, yf, x0, y0, WHITE)
    return wrap(*)