from ./actions import *
from ./api import *
from ./api/Color import *
from ./config import *
from ./util import *
from ./util/Bool import (TRUE, FALSE)
import ./CommandWriter
import ./InputBuffer
from ./InputBuffer import (get_key, get_key_down)
import ./Lens
import ./PhysicsBody
import ./Transform

object Player { _xform, _pbody, _thrust }

def new(x, y):
  xform = Transform(x, y, 0.0)
  pbody = PhysicsBody(0.0, 0.0, 0.0)
  return Player(xform, pbody, FALSE)

def get_xform(player):
  open Player: player
  return player._xform

def get_pbody(player):
  open Player: player
  return player._pbody

def set_xform(xform, player):
  open Player: player
  return Player(xform, player._pbody, player._thrust)

def set_pbody(pbody, player):
  open Player: player
  return Player(player._xform, pbody, player._thrust)

def xformL():
  return Lens/new(get_xform, set_xform)

def pbodyL():
  return Lens/new(get_pbody, set_pbody)

def tick(input, player):
  xform = Player/get_xform(player)
  pbody = Player/get_pbody(player)

  # Accelerate w/ up key
  if get_key(KeyCode/UP, input):
    open PhysicsBody: pbody
    fx, fy = Transform/front(xform)
    vx = pbody.vx + PLAYER_ACCEL * fx
    vy = pbody.vy + PLAYER_ACCEL * fy
    pbody, thrust = PhysicsBody(vx, vy, 0.0), TRUE
  else:
    pbody, thrust = pbody, FALSE

  # Rotate w/ left/right keys
  if get_key(KeyCode/RIGHT, input):
    xform = Transform/rotate(-1.0 * PLAYER_TURN, xform)
  else:
    xform = xform

  if get_key(KeyCode/LEFT, input):
    xform = Transform/rotate(PLAYER_TURN, xform)
  else:
    xform = xform
  
  xform = PhysicsBody/step(1.0, pbody, xform)
  xform = wrap(xform)

  return Player(xform, pbody, thrust)

def shoot(input, player):
  xform = Player/get_xform(player)

  if get_key_down(KeyCode/DOWN, input):
    px, py = Transform/apply(xform, 0.0, -14.0)
    vx, vy = Transform/front(xform)
    bullet = Bullet/new(px, py, 10.0 * vx, 10.0 * vy)
    return [bullet]
  else:
    return []

def wrap(xform):
  open Transform: xform
  x = Math/mod(xform.x, to_f24(SCREEN_WIDTH))
  y = Math/mod(xform.y, to_f24(SCREEN_HEIGHT))
  return Transform(x, y, xform.rot)

def draw(player):
  xform = Player/get_xform(player)

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
  
  open Player: player
  if player._thrust:
    with CommandWriter:
      * <- cw
      * <- draw_line(x6, y6, x7, y7, WHITE)
      * <- draw_line(x6, y6, x8, y8, WHITE)
      return wrap(*)
  else:
    return cw