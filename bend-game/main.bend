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
import ./Lens
import ./Player
import ./Random
import ./Star
import ./State
import ./Transform

def init():
  px = to_f24(SCREEN_WIDTH)  / 2.0
  py = to_f24(SCREEN_HEIGHT) / 2.0
  player = Player/new(px, py)
  bullets = []
  asteroids = [Asteroid/new(30.0, 30.0, 1.0, 1.0, 30.0)]
  return GameState(GameMode/Paused, player, bullets, asteroids, InputBuffer/new)

def tick(state):
  mode = Lens/get(GameState/mode, state)
  inpb = Lens/get(GameState/input, state)

  with State:
    match mode:
      case GameMode/Paused:
        if InputBuffer/get_key_down(KeyCode/SPACE, inpb):
          do_tick = State/mod(Lens/set(GameState/mode, GameMode/Playing))
        else:
          do_tick = wrap(*)

      case GameMode/Playing:
        * <- Lens/zoom(GameState/player, State/mod(Player/tick(inpb)))
        * <- Lens/zoom(GameState/bullets, State/mod(List/map(Bullet/tick)))
        * <- Lens/zoom(GameState/asteroids, State/mod(List/map(Asteroid/tick)))

        # TODO: Messy; clean up
        bullets <- State/prj(Lens/get(GameState/bullets))
        asteroids <- State/prj(Lens/get(GameState/asteroids))
        asteroids, bullets = check_collisions(asteroids, bullets)
        # * <- State/mod(Lens/set(GameState/bullets, bullets))
        * <- State/mod(Lens/set(GameState/asteroids, asteroids))
  
        if InputBuffer/get_key_down(KeyCode/DOWN, inpb):
          player <- State/prj(Lens/get(GameState/player))
          open Player: player
          px, py = Transform/apply(player.xform, 0.0, -14.0)
          vx, vy = Transform/front(player.xform)
          vx, vy = 10.0 * vx, 10.0 * vy
          bullets = List/Cons(Bullet/new(px, py, vx, vy), bullets)
          shoot = State/mod(Lens/set(GameState/bullets, bullets))
        else:
          shoot = wrap(*)

        * <- shoot
        * <- Lens/zoom(GameState/input, State/mod(InputBuffer/clear_key_down))
        do_tick = wrap(*)

      case GameMode/GameOver:
        do_tick = wrap(*)

  return State/exec(do_tick, state)

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

def when(event):
  match event:
    case Event/KeyUp:
      handle = InputBuffer/register_key_up(event.keycode)
      handle = Lens/zoom(GameState/input, State/mod(handle))
    case Event/KeyDown:
      handle = InputBuffer/register_key_down(event.keycode)
      handle = Lens/zoom(GameState/input, State/mod(handle))

  return State/exec(handle)

def main():
  return App(init, tick, draw, when)