from ./api import (App, Color, Command)
from ./math import *

WHITE = (Color 1.0 1.0 1.0 1.0)

def init(): # -> State
  return 0.0

def tick(state): # State -> State
  return state + 1.0

def draw(state): # State -> [Command]
  white = Color(1.0, 1.0, 1.0, 1.0)
  return [ Command/Clear(Color(0.9, 0.3, 0.9, 1.0))
         , Command/DrawLine(50.0, 50.0, 100.0, 100.0, white)
         ]

def main(): # -> App
  return App { init: init, tick: tick, draw: draw }