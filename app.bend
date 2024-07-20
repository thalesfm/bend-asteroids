object App { init, update } # render

def init_():
  return 10

def tick(state):
  return state + 2

# def main():
#   return App { init: init_, update: update }

def main():
  state = init_
  return tick(state)