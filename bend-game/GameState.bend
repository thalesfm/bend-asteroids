import ./Lens

object GameState { mode, player, bullets, asteroids, input }

def get_mode(state):
  open GameState: state
  return state.mode
  
def get_player(state):
  open GameState: state
  return state.player

def get_bullets(state):
  open GameState: state
  return state.bullets

def get_asteroids(state):
  open GameState: state
  return state.asteroids

def get_input(state):
  open GameState: state
  return state.input

def set_mode(_mode, state):
  open GameState: state
  return GameState(_mode, state.player, state.bullets, state.asteroids, state.input)

def set_player(_player, state):
  open GameState: state
  return GameState(state.mode, _player, state.bullets, state.asteroids, state.input)

def set_bullets(_bullets, state):
  open GameState: state
  return GameState(state.mode, state.player, _bullets, state.asteroids, state.input)

def set_asteroids(_asteroids, state):
  open GameState: state
  return GameState(state.mode, state.player, state.bullets, _asteroids, state.input)

def set_input(_input, state):
  open GameState: state
  return GameState(state.mode, state.player, state.bullets, state.asteroids, _input)

def mode():
  return Lens(get_mode, set_mode)

def player():
  return Lens(get_player, set_player)

def bullets():
  return Lens(get_bullets, set_bullets)

def asteroids():
  return Lens(get_asteroids, set_asteroids)

def input():
  return Lens(get_input, set_input)
