from ./app import App

def init():
  return 10

def tick(state):
  return state + 1

def draw(state):
  return [1, 2, 3, 4]

def main():
  return App { init: init, tick: tick, draw: draw }

# def main():
#   state0 = init_
#   state1 = tick(state0)
#   return draw(state1)
