from ./actions import *
from ./api/Color import *
import ./Transform

object Asteroid { xform, r }

def new(x, y):
  xform = Transform(x, y, 0.0)
  return Asteroid(xform, 30.0)

def draw(asteroid):
  open Asteroid: asteroid
  xform = asteroid.xform
  open Transform: xform
  return draw_circle(xform.x, xform.y, asteroid.r, WHITE)