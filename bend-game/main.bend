from ./actions import *
from ./api import *
from ./api/Color import *
from ./config import *
from ./util import *
from ./util/Bool import (TRUE, FALSE)
import ./CommandBuffer
import ./CommandWriter
import ./InputBuffer
import ./Player
import ./Random
import ./Star

object State { paused, player, input }

def init():
  px = to_f24(SCREEN_WIDTH)  / 2.0
  py = to_f24(SCREEN_HEIGHT) / 2.0
  player = Player/new(px, py)
  return State(TRUE, player, InputBuffer/new)

def tick(state):
  open State: state

  if InputBuffer/get_key(state.input, KeyCode/SPACE):
    paused = FALSE
  else:
    paused = state.paused

  if paused:
    player = state.player
  else:
    player = Player/tick(state.player, state.input)

  return State(paused, player, state.input)

def draw(state):
  open State: state
  with CommandWriter:
    * <- clear(BLACK)
    * <- draw_stars(Random/seed(5678))
    if state.paused:
      cw = draw_text("Press SPACE to start", 230.0, 300.0, WHITE)
    else:
      cw = Player/draw(state.player)
  open CommandWriter: cw
  return CommandBuffer/flush(cw.buf)

def draw_stars(rgen):
  bend i = 0, rgen = rgen:
    when i < 20:
      star, rgen = Star/random(rgen)
      with CommandWriter:
        * <- fork(i + 1, rgen)
        * <- Star/draw(star)
        # return wrap(*) # Not working for some reason
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

# def CommandWriter/wrap(val):
#   return CommandWriter(val, CommandBuffer/new)

# def CommandWriter/bind(cw1, nxt):
#   open CommandWriter: cw1
#   nxt = undefer(nxt)
#   cw2 = nxt(cw1.val)
#   open CommandWriter: cw2
#   buf = CommandBuffer/concat(cw1.buf, cw2.buf)
#   return CommandWriter(cw2.val, buf)

