from ./actions import *
from ./api import *
from ./api/Color import *
from ./config import *
from ./util import *
from ./util/Bool import (TRUE, FALSE)
import ./Asteroid
import ./Bullet
import ./Collider
import ./CommandBuffer
import ./CommandWriter
import ./InputBuffer
import ./Player
import ./Random
import ./Star
import ./Transform

object State { paused, player, bullets, asteroids, input }

def init():
  px = to_f24(SCREEN_WIDTH)  / 2.0
  py = to_f24(SCREEN_HEIGHT) / 2.0
  player = Player/new(px, py)
  bullets = []
  asteroids = [Asteroid/new(30.0, 30.0, 1.0, 1.0)]
  return State(TRUE, player, bullets, asteroids, InputBuffer/new)

def tick(state):
  open State: state

  if state.paused:
    if InputBuffer/get_key_down(state.input, KeyCode/SPACE):
      return State(FALSE, state.player, state.bullets, state.asteroids, state.input)
    else:
      return state
  else:
    player = Player/tick(state.player, state.input)
    bullets = List/map(Bullet/tick, state.bullets)
    asteroids = List/map(Asteroid/tick, state.asteroids)

    if InputBuffer/get_key_down(state.input, KeyCode/DOWN):
      open Player: player
      px, py = Transform/apply(player.xform, 0.0, -14.0)
      vx, vy = Transform/front(player.xform)
      vx, vy = 10.0 * vx, 10.0 * vy
      bullets = List/Cons(Bullet/new(px, py, vx, vy), bullets)
    else:
      bullets = bullets
    
    fold asteroids:
      case List/Nil:
        asteroids = List/Nil
      case List/Cons:
        if check_collision(asteroids.head, bullets):
          asteroids = asteroids.tail
        else:
          asteroids = List/Cons(asteroids.head, asteroids.tail)
    
    input = InputBuffer/clear_key_down(state.input)
    return State(FALSE, player, bullets, asteroids, input)

def check_collision(asteroid, bullets):
  fold bullets:
    case List/Nil:
      return FALSE
    case List/Cons:
      if Collider/check(Asteroid/coll(asteroid), Bullet/coll(bullets.head)):
        return TRUE
      else:
        return bullets.tail

def draw(state):
  open State: state
  with CommandWriter:
    * <- clear(BLACK)
    # * <- draw_stars(Random/seed(5678))
    if state.paused:
      cw = draw_text("Press SPACE to start", 230.0, 300.0, WHITE)
    else:
      * <- draw_asteroids(state.asteroids)
      * <- draw_bullets(state.bullets)
      cw = Player/draw(state.player)
  open CommandWriter: cw
  return CommandBuffer/flush(cw.buf)

# TODO: Simplify using List/map, etc.
def draw_asteroids(asteroids):
  match asteroids:
    case List/Nil:
      return CommandWriter/tell(CommandBuffer/new)
    case List/Cons:
      with CommandWriter:
        * <- Asteroid/draw(asteroids.head)
        * <- draw_asteroids(asteroids.tail)
        return wrap(*)

# TODO: Simplify using List/map, etc.
def draw_bullets(bullets):
  match bullets:
    case List/Nil:
      return CommandWriter/tell(CommandBuffer/new)
    case List/Cons:
      with CommandWriter:
        * <- Bullet/draw(bullets.head)
        * <- draw_bullets(bullets.tail)
        return wrap(*)

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
  return State(state.paused, state.player, state.bullets, state.asteroids, input)

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

