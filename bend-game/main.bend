from ./api import *
from ./api/actions import *
from ./api/Color import *
from ./utils import *

SCREEN_WIDTH  = 640
SCREEN_HEIGHT = 480
SHIP_WIDTH  = 22.0
SHIP_HEIGHT = 25.0

object Player { px, py, dx, dy, angle }

type State:
  Paused
  Playing { player }

def init():
  return State/Paused

def tick(state):
  match state:
    case State/Paused:
      return state
    case State/Playing:
      player = Player/tick(state.player)
      return State/Playing(player)

def draw(state):
  match state:
    case State/Paused:
      with CommandWriter:
        * <- clear(BLACK)
        * <- draw_text("Press SPACE to start", 240.0, 300.0, WHITE)
        cw = wrap(*)
    case State/Playing:
      with CommandWriter:
        * <- clear(BLACK)
        * <- Player/draw(state.player)
        cw = wrap(*)
  open CommandWriter: cw
  return CommandBuffer/flush(cw.buf)

def when(key, state):
  match state:
    case State/Paused:
      if key == KeyCode/SPACE:
        return State/Playing(Player/init)
      else:
        return state
    case State/Playing:
      return state

def main():
  return App(init, tick, draw, when)

def main_(f):
  return f(10.0)

def Player/init():
  return Player {
    px: to_f24(SCREEN_WIDTH)  / 2.0,
    py: to_f24(SCREEN_HEIGHT) / 2.0,
    dx: 0.0,
    dy: 0.0,
    angle: 0.0,
  }

def Player/tick(player):
  open Player: player
  return Player {
    px: player.px + 2.0,
    py: player.py - 1.0,
    dx: 0.0,
    dy: 0.0,
    angle: player.angle + 0.2,
  }

def Player/draw(player):
  open Player: player
  fx = sin(player.angle)
  fy = -1.0 * cos(player.angle)
  rx = -1.0 * fy
  ry = fx
  x1 = player.px + fx * SHIP_HEIGHT
  y1 = player.py + fy * SHIP_HEIGHT
  x2 = player.px - rx * SHIP_WIDTH / 2.0
  y2 = player.py - ry * SHIP_WIDTH / 2.0
  x3 = player.px + rx * SHIP_WIDTH / 2.0
  y3 = player.py + ry * SHIP_WIDTH / 2.0

  with CommandWriter:
    * <- draw_line(x1, y1, x2, y2, WHITE)
    * <- draw_line(x2, y2, x3, y3, WHITE)
    * <- draw_line(x3, y3, x1, y1, WHITE)
    return wrap(*)

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

