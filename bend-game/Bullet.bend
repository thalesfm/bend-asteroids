from ./actions import *
from ./api/Color import *
import ./Collider
import ./CommandWriter
import ./PhysicsBody
import ./Transform

object Bullet { xform, pbody }

def new(x, y, vx, vy):
  xform = Transform(x, y, 0.0)
  pbody = PhysicsBody(vx, vy, 0.0)
  return Bullet(xform, pbody)

def coll(bullet):
  open Bullet: bullet
  xform = bullet.xform
  open Transform: xform
  return Collider/Point(xform.x, xform.y)

def tick(bullet):
  open Bullet: bullet
  xform = PhysicsBody/step(1.0, bullet.xform, bullet.pbody)
  return Bullet(xform, bullet.pbody)

def draw(bullet):
  open Bullet: bullet
  x, y = Transform/apply(bullet.xform, 0.0, 0.0)
  return draw_circle(x, y, 1.0, WHITE)