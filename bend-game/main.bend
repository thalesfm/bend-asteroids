# from ./api import * # HACK: File inlined at the end to avoid import system bugs
# from ./math import *

SCREEN_WIDTH  = 640
SCREEN_HEIGHT = 480
SHIP_WIDTH  = 22.0
SHIP_HEIGHT = 25.0

object Ship { px, py, dx, dy, angle }

object State { player }

def init(): # State
  player = Ship {
    px: to_f24(SCREEN_WIDTH)  / 2.0,
    py: to_f24(SCREEN_HEIGHT) / 2.0,
    dx: 0.0,
    dy: 0.0,
    angle: 0.0,
  }
  return State(player)

def tick(state): # State -> State
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
  return State(player)

def do_draw(state): # State -> (CommandWriter *)
  open State: state
  with CommandWriter:
    * <- clear(BLACK)
    * <- draw_ship(state.player)
    return wrap(0)

def draw(state):
  cw = do_draw(state)
  open CommandWriter: cw
  return CommandBuffer/flush(cw.buf)

def main(): # App
  return App(init, tick, draw)

def draw_ship(ship): # Ship -> (CommandWriter *)
  # use WHITE = Color(1.0, 1.0, 1.0, 1.0) # HACK: Ensures that the color is fully expanded

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

object App { init, tick, draw }

object Color { r, g, b, a }

type Command:
  Clear { col }
  DrawLine { x1, y1, x2, y2, col }

object CommandWriter { val, buf }

WHITE = (Color 1.0 1.0 1.0 1.0)
BLACK = (Color 0.0 0.0 0.0 1.0)

def Color/copy(col):
  open Color: col
  r = col.r + 0.0
  g = col.g + 0.0
  b = col.b + 0.0
  a = col.a + 0.0
  return Color(r, g, b, a)

def Command/copy(cmd):
  match cmd:
    case Command/Clear:
      return Command/Clear(Color/copy(cmd.col))
    case Command/DrawLine:
      x1 = cmd.x1 + 0.0
      y1 = cmd.y1 + 0.0
      x2 = cmd.x2 + 0.0
      y2 = cmd.y2 + 0.0
      col = Color/copy(cmd.col)
      return Command/DrawLine(x1, y1, x2, y2, col)

CommandBuffer/new = DiffList/new

CommandBuffer/push = DiffList/append

def CommandBuffer/flush(buf):
  return List/map(Command/copy, DiffList/to_list(buf))

CommandBuffer/concat = DiffList/concat

def CommandWriter/wrap(val):
  return CommandWriter(val, CommandBuffer/new)

def CommandWriter/tell(buf):
  return CommandWriter(0, buf)

def CommandWriter/bind(cw1, nxt):
  open CommandWriter: cw1
  nxt = undefer(nxt)
  cw2 = nxt(cw1.val)
  open CommandWriter: cw2
  buf = CommandBuffer/concat(cw1.buf, cw2.buf)
  return CommandWriter(cw2.val, buf)

def clear(col):
  buf = CommandBuffer/new
  buf = CommandBuffer/push(buf, Command/Clear(col))
  return CommandWriter(0, buf)

def draw_line(x1, y1, x2, y2, col):
  buf = CommandBuffer/new
  buf = CommandBuffer/push(buf, Command/DrawLine(x1, y1, x2, y2, col))
  return CommandWriter(0, buf)

################################################################################
# Misc
################################################################################

def List/map(f, xs):
  match xs:
    case List/Nil:
      return List/Nil
    case List/Cons:
      return List/Cons(f(xs.head), List/map(f, xs.tail))
  
def DiffList/concat(diff1, diff2):
  return lambda x: diff1(diff2(x))

def sin(x):
  x = x % (2.0*Math/PI) - Math/PI
  return -1.0*x + x**3.0/6.0 - x**5.0/120.0 + x**7.0/5040.0

def cos(x):
  x = x % (2.0*Math/PI) - Math/PI
  return -1.0 + x**2.0/2.0 - x**4.0/24.0 + x**6.0/720.0 - x**8.0/40320.0