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
import ./GameMode
import ./GameState
import ./InputBuffer
import ./Player
import ./Random
import ./Star
import ./Transform

def init():
  px = to_f24(SCREEN_WIDTH)  / 2.0
  py = to_f24(SCREEN_HEIGHT) / 2.0
  player = Player/new(px, py)
  bullets = []
  asteroids = [Asteroid/new(30.0, 30.0, 1.0, 1.0, 30.0)]
  return GameState(GameMode/Paused, player, bullets, asteroids, InputBuffer/new)

def tick(state):
  open GameState: state
  match state.mode:
    case GameMode/Paused:
      if InputBuffer/get_key_down(state.input, KeyCode/SPACE):
        return GameState/set_mode(GameMode/Playing, state)
      else:
        return state
    case GameMode/Playing:
      player = Player/tick(state.player, state.input)
      bullets = List/map(Bullet/tick, state.bullets)
      asteroids = List/map(Asteroid/tick, state.asteroids)
      asteroids, bullets = check_collisions(asteroids, bullets)
  
      if InputBuffer/get_key_down(state.input, KeyCode/DOWN):
        open Player: player
        px, py = Transform/apply(player.xform, 0.0, -14.0)
        vx, vy = Transform/front(player.xform)
        vx, vy = 10.0 * vx, 10.0 * vy
        bullets = List/Cons(Bullet/new(px, py, vx, vy), bullets)
      else:
        bullets = bullets
      
      input = InputBuffer/clear_key_down(state.input)
      return GameState(GameMode/Playing, player, bullets, asteroids, input)
    case GameMode/GameOver:
      return state

def check_collisions(asteroids, bullets):
  match asteroids:
    case List/Nil:
      return List/Nil, bullets
    case List/Cons:
      asteroid_pieces, bullets = check_asteroid_collisions(asteroids.head, bullets)
      asteroids, bullets = check_collisions(asteroids.tail, bullets)
      return List/concat(asteroid_pieces, asteroids), bullets

def check_asteroid_collisions(asteroid, bullets):
  match bullets:
    case List/Nil:
      return [asteroid], List/Nil
    case List/Cons:
      if Collider/check(Asteroid/coll(asteroid), Bullet/coll(bullets.head)):
        return Asteroid/split(asteroid), bullets.tail
      else:
        asteroid_pieces, bullets_tail = check_asteroid_collisions(asteroid, bullets.tail)
        return asteroid_pieces, List/Cons(bullets.head, bullets_tail)

def draw(state):
  open GameState: state

  with CommandWriter:
    * <- clear(BLACK)
    # * <- draw_stars(Random/seed(5678))
    cw = wrap(*)

  match state.mode:
    case GameMode/Paused:
      with CommandWriter:
        * <- cw
        cw = draw_text("Press SPACE to start", 230.0, 300.0, WHITE)
    case GameMode/Playing:
      with CommandWriter:
        * <- cw
        * <- draw_asteroids(state.asteroids)
        * <- draw_bullets(state.bullets)
        cw = Player/draw(state.player)
    case GameMode/GameOver:
      with CommandWriter:
        * <- cw
        cw = draw_text("GAME OVER", 300.0, 300.0, WHITE)

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
  open GameState: state
  match event:
    case Event/KeyDown:
      input = InputBuffer/register_key_down(state.input, event.keycode)
    case Event/KeyUp:
      input = InputBuffer/register_key_up(state.input, event.keycode)
  return GameState/set_input(input, state)

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

