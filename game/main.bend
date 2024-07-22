from ./api import (App, Command)
from ./api import Color
from ./math import *

WHITE = (Color 1.0 1.0 1.0 1.0)

def init(): # -> State
  return 0.0

def tick(state): # State -> State
  return state + 1.0

def draw(state): # State -> [Command]
  # commands = []
  # commands = List/Cons(Command/Clear(Color(0.9, 0.3, 0.9, 1.0)), commands)
  # commands = List/Cons(Command/DrawLine(0, 0, 1, 1, WHITE))
  # return commands
  return cos(state / 60.0)

def main(): # -> App
  # return App { init: init, tick: tick, draw: draw }

  # Should return 0
  return sin(Math/radians(45.0)) - (Math/sqrt(2.0) / 2.0)