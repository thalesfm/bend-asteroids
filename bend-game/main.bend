from ./actions import *
from ./api import *
from ./api/Color import *
from ./util import *
import ./CommandBuffer
import ./CommandWriter
import ./InputBuffer

SCREEN_WIDTH  = 640
SCREEN_HEIGHT = 480
SHIP_WIDTH  = 22.0
SHIP_HEIGHT = 25.0

object Player { px, py, dx, dy, angle, thrust }

object State { paused, player, input }

def Player/init():
  return Player {
    px: to_f24(SCREEN_WIDTH)  / 2.0,
    py: to_f24(SCREEN_HEIGHT) / 2.0,
    dx: 0.0,
    dy: 0.0,
    angle: 0.0,
    thrust: 0,
  }

def init():
  return State(1, Player/init, InputBuffer/new)

def tick(state):
  open State: state

  if InputBuffer/get_key(state.input, KeyCode/SPACE):
    paused = 0
  else:
    paused = state.paused

  if paused:
    player = state.player
  else:
    player = Player/tick(state.player, state.input)

  # return State(paused, player, InputBuffer/new)
  return State(paused, player, state.input)

def draw(state):
  open State: state
  with CommandWriter:
    * <- clear(BLACK)
    if state.paused:
      cw = draw_text("Press SPACE to start", 240.0, 300.0, WHITE)
    else:
      cw = Player/draw(state.player)
  open CommandWriter: cw
  return CommandBuffer/flush(cw.buf)

def when(event, state):
  open State: state
  match event:
    case Event/KeyDown:
      input = InputBuffer/register_key_down(state.input, event.keycode)
    case Event/KeyUp:
      input = InputBuffer/register_key_up(state.input, event.keycode)
  return State(state.paused, state.player, input)

def main():
  return App(init, tick, draw, when)

def forward(angle):
  fx = Math/sin_(angle)
  fy = -1.0 * Math/cos_(angle)
  return fx, fy

def Player/tick(player, input):
  open Player: player
  fx, fy = forward(player.angle)

  if InputBuffer/get_key(input, KeyCode/UP):
    dx, dy, thrust = player.dx + 0.05 * fx, player.dy + 0.05 * fy, 1
  else:
    dx, dy, thrust = player.dx, player.dy, 0
  
  if InputBuffer/get_key(input, KeyCode/RIGHT):
    angle = player.angle + 0.07
  else:
    angle = player.angle
  if InputBuffer/get_key(input, KeyCode/LEFT):
    angle = angle - 0.07
  else:
    angle = angle


  return Player {
    px: player.px + dx,
    py: player.py + dy,
    dx: dx,
    dy: dy,
    angle: angle,
    thrust: thrust,
  }

def Player/draw(player):
  open Player: player
  fx, fy = forward(player.angle)
  rx, ry = -1.0 * fy, fx
  x1 = player.px + fx * SHIP_HEIGHT
  y1 = player.py + fy * SHIP_HEIGHT
  x2 = player.px - rx * SHIP_WIDTH / 2.0
  y2 = player.py - ry * SHIP_WIDTH / 2.0
  x3 = player.px + rx * SHIP_WIDTH / 2.0
  y3 = player.py + ry * SHIP_WIDTH / 2.0

  with CommandWriter:
    * <- draw_line(x1, y1, x2, y2, WHITE)
    * <- draw_line(x2, y2, x3, y3, WHITE)
    cw = draw_line(x3, y3, x1, y1, WHITE)
  
  if player.thrust:
    x1 = player.px - fx * SHIP_HEIGHT / 2.0
    y1 = player.py - fy * SHIP_HEIGHT / 2.0
    x2 = player.px - rx * SHIP_WIDTH / 4.0
    y2 = player.py - ry * SHIP_WIDTH / 4.0
    x3 = player.px + rx * SHIP_WIDTH / 4.0
    y3 = player.py + ry * SHIP_WIDTH / 4.0

    with CommandWriter:
      * <- cw
      * <- draw_line(x1, y1, x2, y2, WHITE)
      * <- draw_line(x2, y2, x3, y3, WHITE)
      * <- draw_line(x3, y3, x1, y1, WHITE)
      return wrap(*)
  else:
    return cw

# def CommandWriter/wrap(val):
#   return CommandWriter(val, CommandBuffer/new)

# def CommandWriter/bind(cw1, nxt):
#   open CommandWriter: cw1
#   nxt = undefer(nxt)
#   cw2 = nxt(cw1.val)
#   open CommandWriter: cw2
#   buf = CommandBuffer/concat(cw1.buf, cw2.buf)
#   return CommandWriter(cw2.val, buf)

