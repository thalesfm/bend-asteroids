import ./Lens

object GameState { mode, player, bullets, asteroids, input }

def get_mode(state):
  open GameState: state
  return state.mode
  
def set_mode(mode, state):
  open GameState: state
  return GameState(mode, state.player, state.bullets, state.asteroids, state.input)

def get_input(state):
  open GameState: state
  return state.input

def set_input(input, state):
  open GameState: state
  return GameState(state.mode, state.player, state.bullets, state.asteroids, input)

def input():
  return Lens(get_input, set_input)