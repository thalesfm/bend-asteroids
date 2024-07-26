from ./api import *
from ./api/Color import *
from ./util import *

SCREEN_WIDTH  = 640
SCREEN_HEIGHT = 480
SHIP_WIDTH  = 22.0
SHIP_HEIGHT = 25.0

object Ship { px, py, dx, dy, angle }

object State { player, pressed }

def init():
  player = Ship {
    px: to_f24(SCREEN_WIDTH)  / 2.0,
    py: to_f24(SCREEN_HEIGHT) / 2.0,
    dx: 0.0,
    dy: 0.0,
    angle: 0.0,
  }
  return State(player, 0)

def tick(state):
  open State: state
  player = state.player
  open Ship: player
  player = Ship {
    px: player.px + 1.0,
    py: player.py,
    dx: 0.0,
    dy: 0.0,
    angle: player.angle + 0.1,
  }
  return State(player, state.pressed)

def do_draw(state):
  open State: state
  with CommandWriter:
    * <- clear(BLACK)
    * <- draw_ship(state.player)
    if state.pressed != 0:
      cw = draw_text("Key pressed", 300.0, 300.0, WHITE)
    else:
      cw = wrap(0)
  return cw

def draw(state):
  cw = do_draw(state)
  open CommandWriter: cw
  return CommandBuffer/flush(cw.buf)

def when(key, state):
  open State: state
  return State(state.player, key)

def main(): # App
  return App(init, tick, draw, when)

def draw_ship(ship):
  open Ship: ship
  fx = sin(ship.angle)
  fy = -1.0 * cos(ship.angle)
  rx = -1.0 * fy
  ry = fx
  x1 = ship.px + fx * SHIP_HEIGHT
  y1 = ship.py + fy * SHIP_HEIGHT
  x2 = ship.px - rx * SHIP_WIDTH / 2.0
  y2 = ship.py - ry * SHIP_WIDTH / 2.0
  x3 = ship.px + rx * SHIP_WIDTH / 2.0
  y3 = ship.py + ry * SHIP_WIDTH / 2.0

  with CommandWriter:
    * <- draw_line(x1, y1, x2, y2, WHITE)
    * <- draw_line(x2, y2, x3, y3, WHITE)
    * <- draw_line(x3, y3, x1, y1, WHITE)
    return wrap(0)

################################################################################
# API
################################################################################

# HACK: Workaround for a bug in the import system!

def CommandWriter/wrap(val):
  return CommandWriter(val, CommandBuffer/new)

def CommandWriter/bind(cw1, nxt):
  open CommandWriter: cw1
  nxt = undefer(nxt)
  cw2 = nxt(cw1.val)
  open CommandWriter: cw2
  buf = CommandBuffer/concat(cw1.buf, cw2.buf)
  return CommandWriter(cw2.val, buf)

