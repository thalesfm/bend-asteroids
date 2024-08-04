from ./actions import (clear, draw_line, draw_circle, draw_text)
from ./api import *
from ./api/Color import *
from ./config import *
from ./util import *
from ./util/Bool import (TRUE, FALSE)
from ./util/List import (map)
import ./Asteroid
import ./Bullet
import ./Collider
import ./CommandBuffer
import ./CommandWriter
import ./GameMode
import ./GameState
from ./GameState import (modeL, inputL, playerL, bulletsL, asteroidsL)
import ./InputBuffer
from ./InputBuffer import (
  clear_key_down,
  get_key,
  get_key_down,
  register_key_down,
  register_key_up
)
import ./Lens
from ./Lens import (over, set, view, zoom)
import ./Player
import ./Random
import ./Star
import ./State
from ./State import (gets, modify)
import ./Transform

def init():
  player = Player/new(to_f24(SCREEN_WIDTH) / 2.0, to_f24(SCREEN_HEIGHT) / 2.0)
  bullets = []
  asteroids = [Asteroid/new(30.0, 30.0, 1.0, 1.0, 30.0)]
  return GameState(GameMode/Paused, InputBuffer/new, player, bullets, asteroids)

def tick():
  with State:
    mode <- gets(view(modeL))
    input <- gets(view(inputL))

    match mode:
      case GameMode/Paused:
        if get_key_down(KeyCode/SPACE, input):
          do_tick = modify(set(modeL, GameMode/Playing))
        else:
          do_tick = wrap(*)

      case GameMode/Playing:
        * <- zoom(playerL, modify(Player/tick(input)))
        * <- zoom(bulletsL, modify(map(Bullet/tick)))
        * <- zoom(asteroidsL, modify(map(Asteroid/tick)))

        new_bullets <- zoom(playerL, gets(Player/shoot(input)))
        * <- zoom(bulletsL, modify(List/concat(new_bullets)))

        # TODO: Messy; clean up
        bullets <- gets(view(bulletsL))
        asteroids <- gets(view(asteroidsL))
        asteroids, bullets = check_collisions(asteroids, bullets)
        * <- modify(set(asteroidsL, asteroids))
        * <- modify(set(bulletsL, bullets))
  
        do_tick = wrap(*)

      case GameMode/GameOver:
        do_tick = wrap(*)

    * <- do_tick
    do_tick = zoom(inputL, modify(clear_key_down))

  return State/exec(do_tick)

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
  mode = view(modeL, state)

  with CommandWriter:
    * <- clear(BLACK)
    # * <- draw_stars(Random/seed(5678))

    match mode:
      case GameMode/Paused:
        cw = draw_text("Press SPACE to start", 230.0, 300.0, WHITE)
      case GameMode/Playing:
        * <- draw_asteroids(view(asteroidsL, state))
        * <- draw_bullets(view(bulletsL, state))
        cw = Player/draw(view(playerL, state))
      case GameMode/GameOver:
        cw = draw_text("GAME OVER", 300.0, 300.0, WHITE)

  # TODO: Avoid using `open` here
  open CommandWriter: cw
  return CommandBuffer/flush(cw.buf)

# TODO: Simplify using sequence, map (or mapM)
def draw_asteroids(asteroids):
  match asteroids:
    case List/Nil:
      return CommandWriter/tell(CommandBuffer/new)
    case List/Cons:
      with CommandWriter:
        * <- Asteroid/draw(asteroids.head)
        * <- draw_asteroids(asteroids.tail)
        return wrap(*)

# TODO: Simplify using sequence, map (or mapM)
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
      handle_event = modify(register_key_up(event.key))
      handle_event = zoom(inputL, handle_event)
    case Event/KeyDown:
      handle_event = modify(register_key_down(event.key))
      handle_event = zoom(inputL, handle_event)
  return State/exec(handle_event)

def main():
  return App(init, tick, draw, when)