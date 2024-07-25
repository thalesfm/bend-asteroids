# from ./api import (App, Color, Command)
# from ./api import (CommandBuffer, push_command)
from ./api import *
from ./math import *

WHITE = (Color 1.0 1.0 1.0 1.0)

SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480
SHIP_HEIGHT = 25.0
SHIP_BASE = 22.0

object Ship { x, y, r, dx, dy }

object State { player }

def init_(): # -> State
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
  player = Ship { x: player.x + 1.0, y: player.y, r: player.r, dx: player.dx, dy: player.dy }
  return State(player)

def draw_ship(buf, ship): # (CommandBuffer, Ship) -> CommandBuffer
  white = Color(1.0, 1.0, 1.0, 1.0)
  open Ship: ship
  x1 = ship.x + sin(ship.r) * SHIP_HEIGHT / 2.0
  y1 = ship.x + cos(ship.r) * SHIP_HEIGHT / 2.0
  x2 = ship.x - cos(ship.r) * SHIP_BASE / 2.0 - sin(ship.r) * SHIP_HEIGHT / 2.0
  y2 = ship.x - sin(ship.r) * SHIP_BASE / 2.0 - cos(ship.r) * SHIP_HEIGHT / 2.0
  x3 = ship.x + cos(ship.r) * SHIP_BASE / 2.0 - sin(ship.r) * SHIP_HEIGHT / 2.0
  y3 = ship.x + sin(ship.r) * SHIP_BASE / 2.0 - cos(ship.r) * SHIP_HEIGHT / 2.0
  buf = draw_line(buf, x1, y1, x2, y2, white)
  buf = draw_line(buf, x2, y2, x3, y3, white)
  buf = draw_line(buf, x3, y3, x1, y1, white)
  return buf

def draw(state): # State -> [Command]
  open State: state
  buf = CommandBuffer/new
  buf = clear(buf, Color(0.9, 0.3, 0.9, 1.0))
  buf = draw_ship(buf, state.player)
  return CommandBuffer/flush(buf)

def main(): # -> App
  return App(init_, tick, draw)
  # return draw(init_)