from ./actions import *
from ./api/Color import *
from ./config import *
import ./Random

object Star { x, y, r, color }

def random(rgen):
  x, rgen = Random/unif(0, SCREEN_WIDTH, rgen)
  y, rgen = Random/unif(0, SCREEN_HEIGHT, rgen)
  r, rgen = Random/unit(rgen)
  g, rgen = Random/unit(rgen)
  b, rgen = Random/unit(rgen)
  return Star(to_f24(x), to_f24(y), 2.0, Color(r, g, b, 1.0)), rgen

def draw(star):
  open Star: star
  return draw_circle(star.x, star.y, star.r, star.color)