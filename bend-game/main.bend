# from ./api import *
from ./math import *

SCREEN_WIDTH  = 640
SCREEN_HEIGHT = 480
SHIP_WIDTH  = 22.0
SHIP_HEIGHT = 25.0

object Ship { x, y, r, dx, dy }

object State { player }

def init(): # State
  player = Ship {
    x:  to_f24(SCREEN_WIDTH)  / 2.0,
    y:  to_f24(SCREEN_HEIGHT) / 2.0,
    r:  0.0,
    dx: 0.0,
    dy: 0.0,
  }
  return State(player)

def tick(state): # State -> State
  open State: state
  player = state.player
  open Ship: player
  player = Ship {
    x: player.x + 1.0,
    y: player.y,
    r: player.r + 0.1,
    dx: 0.0,
    dy: 0.0
  }
  return State(player)

def do_draw(state): # State -> (CommandWriter *)
  open State: state
  with CommandWriter:
    * <- clear(Color(0.0, 0.0, 0.0, 1.0))
    * <- draw_ship(state.player)
    return wrap(0)

def draw(state):
  cw = do_draw(state)
  open CommandWriter: cw
  return CommandBuffer/flush(cw.buf)

def main(): # App
  return App(init, tick, draw)

  # return draw(tick(init))

  # cw = foo()
  # open CommandWriter: cw
  # return CommandBuffer/flush(cw.buf)

def draw_ship(ship): # Ship -> (CommandWriter *)
  WHITE = Color(1.0, 1.0, 1.0, 1.0) # HACK: Ensures that the color is fully expanded

  open Ship: ship
  fx = sin(ship.r)
  fy = -1.0 * cos(ship.r)
  rx = -1.0 * fy
  ry = fx
  x1 = ship.x + fx * SHIP_HEIGHT
  y1 = ship.y + fy * SHIP_HEIGHT
  x2 = ship.x - rx * SHIP_WIDTH / 2.0
  y2 = ship.y - ry * SHIP_WIDTH / 2.0
  x3 = ship.x + rx * SHIP_WIDTH / 2.0
  y3 = ship.y + ry * SHIP_WIDTH / 2.0

  with CommandWriter:
    * <- draw_line(x1, y1, x2, y2, WHITE)
    * <- draw_line(x2, y2, x3, y3, WHITE)
    * <- draw_line(x3, y3, x1, y1, WHITE)
    return wrap(0)

# HACK: Workaround for import system bug

object App { init, tick, draw }

object Color { r, g, b, a }

WHITE = (Color 1.0 1.0 1.0 1.0)

type Command:
  Clear { color }
  DrawLine { x1, y1, x2, y2, color }

CommandBuffer/new = DiffList/new

CommandBuffer/push = DiffList/append

CommandBuffer/flush = DiffList/to_list

CommandBuffer/concat = DiffList/concat

object CommandWriter { val, buf }

def CommandWriter/wrap(val):
  return CommandWriter(val, CommandBuffer/new)

def CommandWriter/tell(buf): # CommandBuffer -> (CommandWriter *)
  return CommandWriter(0, buf)

def CommandWriter/bind(cw1, nxt): # (CommandWriter a) -> (a -> CommandWriter b) -> CommandWriter b
  open CommandWriter: cw1
  nxt = undefer(nxt)
  cw2 = nxt(cw1.val)
  open CommandWriter: cw2
  buf = CommandBuffer/concat(cw1.buf, cw2.buf)
  return CommandWriter(cw2.val, buf)

def clear(color): # Color -> (CommandWriter *):
  buf = CommandBuffer/new
  buf = CommandBuffer/push(buf, Command/Clear(color))
  return CommandWriter(0, buf)

def draw_line(x1, y1, x2, y2, color):
  buf = CommandBuffer/new
  buf = CommandBuffer/push(buf, Command/DrawLine(x1, y1, x2, y2, color))
  return CommandWriter(0, buf)

def DiffList/concat(diff1, diff2):
  return lambda x: diff1(diff2(x))