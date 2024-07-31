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

PLAYER_WIDTH  = 17.0
PLAYER_HEIGHT = 22.0
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

  if InputBuffer/get_key(input, KeyCode/UP):
    open PhysicsBody: pbody
    fx, fy = Transform/front(xform)
    vx = pbody.vx + PLAYER_ACCEL * fx
    vy = pbody.vy + PLAYER_ACCEL * fy
    pbody, thrust = PhysicsBody(vx, vy, 0.0), TRUE
  else:
    pbody, thrust = pbody, FALSE

  xform = PhysicsBody/step(1.0, pbody, xform)
  
  if InputBuffer/get_key(input, KeyCode/RIGHT):
    xform = Transform/rotate(PLAYER_TURN, xform)
  else:
    xform = xform

  if InputBuffer/get_key(input, KeyCode/LEFT):
    xform = Transform/rotate(-1.0 * PLAYER_TURN, xform)
  else:
    xform = xform

  # Workaround for compiler error (can't find Player constructor)
  return Player(xform, pbody, thrust)


def draw(player):
  open Player: player
  xform = player.xform
  open Transform: xform
  px, py = xform.x, xform.y
  fx, fy = Transform/front(xform)
  rx, ry = Transform/right(xform)
  cx = px - fx * PLAYER_HEIGHT / 3.0
  cy = py - fy * PLAYER_HEIGHT / 3.0
  x1 = cx + fx * PLAYER_HEIGHT
  y1 = cy + fy * PLAYER_HEIGHT
  x2 = cx - rx * PLAYER_WIDTH / 2.0
  y2 = cy - ry * PLAYER_WIDTH / 2.0
  x3 = cx + rx * PLAYER_WIDTH / 2.0
  y3 = cy + ry * PLAYER_WIDTH / 2.0
  x4 = x2 + 0.3 * (x2 - x1)
  y4 = y2 + 0.3 * (y2 - y1)
  x5 = x3 + 0.3 * (x3 - x1)
  y5 = y3 + 0.3 * (y3 - y1)

  with CommandWriter:
    * <- draw_line(x1, y1, x4, y4, WHITE)
    * <- draw_line(x1, y1, x5, y5, WHITE)
    cw = draw_line(x2, y2, x3, y3, WHITE)
  
  if player.thrust:
    x1 = cx - fx * PLAYER_HEIGHT / 2.0
    y1 = cy - fy * PLAYER_HEIGHT / 2.0
    x2 = cx - rx * PLAYER_WIDTH  / 4.0
    y2 = cy - ry * PLAYER_WIDTH  / 4.0
    x3 = cx + rx * PLAYER_WIDTH  / 4.0
    y3 = cy + ry * PLAYER_WIDTH  / 4.0

    with CommandWriter:
      * <- cw
      * <- draw_line(x1, y1, x2, y2, WHITE)
      * <- draw_line(x2, y2, x3, y3, WHITE)
      * <- draw_line(x3, y3, x1, y1, WHITE)
      return wrap(*)
  else:
    return cw