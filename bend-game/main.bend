from ./actions import *
from ./api import *
from ./api/Color import *
from ./util import *
import ./CommandBuffer
import ./CommandWriter
import ./InputBuffer
import ./Random

SCREEN_WIDTH  = 640
SCREEN_HEIGHT = 480
PLAYER_WIDTH  = 22.0
PLAYER_HEIGHT = 25.0
PLAYER_ACCEL  = 0.05
PLAYER_TURN   = 0.1

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
      * <- draw_stars(Random/seed(45))
      cw = draw_text("Press SPACE to start", 240.0, 300.0, WHITE)
    else:
      cw = Player/draw(state.player)
  open CommandWriter: cw
  return CommandBuffer/flush(cw.buf)

def draw_stars(rgen):
  bend i = 0, rgen = rgen:
    when i < 20:
      x, rgen = Random/unif(0, SCREEN_WIDTH, rgen)
      y, rgen = Random/unif(0, SCREEN_HEIGHT, rgen)
      r, rgen = Random/unit(rgen)
      g, rgen = Random/unit(rgen)
      b, rgen = Random/unit(rgen)
      cw = fork(i + 1, rgen)
      x = to_f24(x)
      y = to_f24(y)
      with CommandWriter:
        * <- cw
        * <- draw_line(x, y, x + 3.0, y + 3.0, Color(r, g, b, 1.0))
        return CommandWriter/wrap(*)
    else:
      return CommandWriter/wrap(*)

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

  with CommandWriter:
    * <- draw_line(x1, y1, x2, y2, WHITE)
    * <- draw_line(x2, y2, x3, y3, WHITE)
    cw = draw_line(x3, y3, x1, y1, WHITE)
  
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

# def CommandWriter/wrap(val):
#   return CommandWriter(val, CommandBuffer/new)

# def CommandWriter/bind(cw1, nxt):
#   open CommandWriter: cw1
#   nxt = undefer(nxt)
#   cw2 = nxt(cw1.val)
#   open CommandWriter: cw2
#   buf = CommandBuffer/concat(cw1.buf, cw2.buf)
#   return CommandWriter(cw2.val, buf)

