from ./actions import *
from ./api/Color import *
import ./PhysicsBody
import ./Transform

object Asteroid { xform, pbody, r }

def new(x, y, vx, vy):
  xform = Transform(x, y, 0.0)
  pbody = PhysicsBody(vx, vy, 0.0)
  return Asteroid(xform, pbody, 30.0)

def tick(asteroid):
  open Asteroid: asteroid
  xform = asteroid.xform
  pbody = asteroid.pbody
  xform = PhysicsBody/step(1.0, xform, pbody)
  return Asteroid(xform, pbody, asteroid.r)

def draw(asteroid):
  open Asteroid: asteroid
  xform = asteroid.xform
  open Transform: xform
  return draw_circle(xform.x, xform.y, asteroid.r, WHITE)