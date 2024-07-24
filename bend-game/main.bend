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

# object Bullet { ... }

# object Asteroid { ... }

object State {
  player,
  # bullets
  # last_shot
  # asteroids
  # gameover
}

def init(): # -> State
  return 0.0

  # player = Ship {
  #   x: to_f24(SCREEN_WIDTH)/2.0,
  #   y: to_f24(SCREEN_HEIGHT)/2.0,
  #   r: 0.0,
  #   dx: 0.0,
  #   dy: 0.0,
  # }
  # return State(player)

def tick(state): # State -> State
  return state + 1.0

  # open State: state
  # return State(state.player)

def draw_ship(buf, ship): # (CommandBuffer, Ship) -> CommandBuffer
  open Ship: ship
  use white = Color(1.0, 1.0, 1.0, 1.0)
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
  # return state + 10.0

  open State: state
  use white = Color(1.0, 1.0, 1.0, 1.0)
  buf = CommandBuffer/new
  buf = clear(buf, Color(0.9, 0.3, 0.9, 1.0))
  buf = draw_ship(buf, state.player)
  return CommandBuffer/flush(buf)
  # return state.player

def main_(): # -> App
  return App(init, tick, draw)

def main():
  # white = Color(1.0, 1.0, 1.0, 1.0)
  state = init
  state = tick(state)
  state = tick(state)
  return draw(state)

  # Works:
  # return [ Command/Clear(Color(0.9, 0.3, 0.9, 1.0))
  #        , Command/DrawLine(50.0, 50.0, 100.0, 100.0, white)
  #        ]

  # Works:
  # return List/Cons(
  #   Command/Clear(Color(0.9, 0.3, 0.9, 1.0)),
  #   List/Cons(Command/DrawLine(50.0, 50.0, 100.0, 100.0, white), List/Nil))
  
  # Works:
  # def my_cons(head, tail):
  # return List/Cons(head, tail)
  # return my_cons(
  #   Command/Clear(Color(0.9, 0.3, 0.9, 1.0)),
  #   my_cons(Command/DrawLine(50.0, 50.0, 100.0, 100.0, white), List/Nil))
  
  # Works:
  # def prepend(tail, head):
  #   return List/Cons(head, tail)
  # return prepend(
  #   prepend(List/Nil, Command/Clear(Color(0.9, 0.3, 0.9, 1.0))),
  #   Command/DrawLine(50.0, 50.0, 100.0, 100.0, white))

  # Works:
  # def prepend(tail, head):
  #   return List/Cons(head, tail)
  # list = List/Nil
  # list = prepend(list, Command/Clear(Color(0.9, 0.3, 0.9, 1.0)))
  # list = prepend(list, Command/DrawLine(50.0, 50.0, 100.0, 100.0, white))
  # return list

  # Works:
  # def what(x):
  #   fold list = x:
  #     case List/Nil:
  #       return List/Nil
  #     case List/Cons:
  #       return List/Cons(list.head, list.tail)
  # return what(draw(init))