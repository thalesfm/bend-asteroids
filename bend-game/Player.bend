from ./actions import *
from ./api import *
from ./api/Color import *
from ./config import *
from ./util import *
import ./InputBuffer
import ./CommandWriter

PLAYER_WIDTH  = 17.0
PLAYER_HEIGHT = 22.0
PLAYER_ACCEL  = 0.05
PLAYER_TURN   = 0.1

object Player { px, py, dx, dy, angle, thrust }

def forward(angle):
  fx = Math/sin_(angle)
  fy = -1.0 * Math/cos_(angle)
  return fx, fy

def new(x, y):
  # return Player {
  #   px: to_f24(SCREEN_WIDTH)  / 2.0,
  #   py: to_f24(SCREEN_HEIGHT) / 2.0,
  #   dx: 0.0,
  #   dy: 0.0,
  #   angle: 0.0,
  #   thrust: 0,
  # }

  # Workaround for compiler error (can't find Player constructor)
  # x = to_f24(SCREEN_WIDTH)  / 2.0
  # y = to_f24(SCREEN_HEIGHT) / 2.0
  return Player(x, y, 0.0, 0.0, 0.0, 0)

def tick(player, input):
  open Player: player
  fx, fy = forward(player.angle)

  if InputBuffer/get_key(input, KeyCode/UP):
    dx = player.dx + PLAYER_ACCEL * fx
    dy = player.dy + PLAYER_ACCEL * fy
    dx, dy, thrust = dx, dy, 1
  else:
    dx, dy, thrust = player.dx, player.dy, 0
  
  if InputBuffer/get_key(input, KeyCode/RIGHT):
    angle = player.angle + PLAYER_TURN
  else:
    angle = player.angle
  if InputBuffer/get_key(input, KeyCode/LEFT):
    angle = angle - PLAYER_TURN
  else:
    angle = angle

  # return Player {
  #   px: player.px + dx,
  #   py: player.py + dy,
  #   dx: dx,
  #   dy: dy,
  #   angle: angle,
  #   thrust: thrust,
  # }

  # Workaround for compiler error (can't find Player constructor)
  return Player(player.px + dx, player.py + dy, dx, dy, angle, thrust)


def draw(player):
  open Player: player
  fx, fy = forward(player.angle)
  rx = -1.0 * fy
  ry = fx
  cx = player.px - fx * PLAYER_HEIGHT / 3.0
  cy = player.py - fy * PLAYER_HEIGHT / 3.0
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