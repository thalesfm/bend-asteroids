from ./actions import *
from ./api import *
from ./api/Color import *
from ./config import *
from ./util import *
from ./util/Bool import (TRUE, FALSE)
import ./CommandWriter
import ./InputBuffer
import ./PhysicsBody
import ./Transform

PLAYER_ACCEL  = 0.05
PLAYER_TURN   = 0.1

object Player { xform, pbody, thrust }

def new(x, y):
  # Workaround for compiler error (can't find Player constructor)
  xform = Transform(x, y, 0.0)
  pbody = PhysicsBody(0.0, 0.0, 0.0)
  return Player(xform, pbody, FALSE)

def tick(player, input):
  open Player: player
  xform = player.xform
  pbody = player.pbody

  # Accelerate w/ up key
  if InputBuffer/get_key(input, KeyCode/UP):
    open PhysicsBody: pbody
    fx, fy = Transform/front(xform)
    vx = pbody.vx + PLAYER_ACCEL * fx
    vy = pbody.vy + PLAYER_ACCEL * fy
    pbody, thrust = PhysicsBody(vx, vy, 0.0), TRUE
  else:
    pbody, thrust = pbody, FALSE

  # Rotate w/ left/right keys
  if InputBuffer/get_key(input, KeyCode/RIGHT):
    xform = Transform/rotate(-1.0 * PLAYER_TURN, xform)
  else:
    xform = xform

  if InputBuffer/get_key(input, KeyCode/LEFT):
    xform = Transform/rotate(PLAYER_TURN, xform)
  else:
    xform = xform
  
  xform = PhysicsBody/step(1.0, pbody, xform)
  xform = wrap(xform)

  # Workaround for compiler error (can't find Player constructor)
  return Player(xform, pbody, thrust)


def wrap(xform):
  open Transform: xform
  x = Math/mod(xform.x, to_f24(SCREEN_WIDTH))
  y = Math/mod(xform.y, to_f24(SCREEN_HEIGHT))
  return Transform(x, y, xform.rot)

def draw(player):
  open Player: player
  xform = player.xform

  x1, y1 = Transform/apply(xform,   0.0, -14.0)
  x2, y2 = Transform/apply(xform, -12.0,  14.0)
  x3, y3 = Transform/apply(xform,  12.0,  14.0)
  x4, y4 = Transform/apply(xform,  -9.0,   7.0)
  x5, y5 = Transform/apply(xform,   9.0,   7.0)
  x6, y6 = Transform/apply(xform,   0.0,  19.0)
  x7, y7 = Transform/apply(xform,  -4.5,   7.0)
  x8, y8 = Transform/apply(xform,   4.5,   7.0)

  with CommandWriter:
    * <- draw_line(x1, y1, x2, y2, WHITE)
    * <- draw_line(x1, y1, x3, y3, WHITE)
    * <- draw_line(x4, y4, x5, y5, WHITE)
    cw = wrap(*)
  
  if player.thrust:
    with CommandWriter:
      * <- cw
      * <- draw_line(x6, y6, x7, y7, WHITE)
      * <- draw_line(x6, y6, x8, y8, WHITE)
      return wrap(*)
  else:
    return cw