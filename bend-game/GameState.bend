import ./Lens

object GameState {
  _mode,
  _input,
  _player,
  _bullets,
  _asteroids,
}

def get_mode(state):
  open GameState: state
  return state._mode
  
def get_input(state):
  open GameState: state
  return state._input

def get_player(state):
  open GameState: state
  return state._player

def get_bullets(state):
  open GameState: state
  return state._bullets

def get_asteroids(state):
  open GameState: state
  return state._asteroids

def set_mode(_mode, state):
  open GameState: state
  return GameState(_mode, state._input, state._player, state._bullets, state._asteroids)

def set_input(_input, state):
  open GameState: state
  return GameState(state._mode, _input, state._player, state._bullets, state._asteroids)

def set_player(_player, state):
  open GameState: state
  return GameState(state._mode, state._input, _player, state._bullets, state._asteroids)

def set_bullets(_bullets, state):
  open GameState: state
  return GameState(state._mode, state._input, state._player, _bullets, state._asteroids)

def set_asteroids(_asteroids, state):
  open GameState: state
  return GameState(state._mode, state._input, state._player, state._bullets, _asteroids)

def modeL():
  return Lens/new(get_mode, set_mode)

def inputL():
  return Lens/new(get_input, set_input)

def playerL():
  return Lens/new(get_player, set_player)

def bulletsL():
  return Lens/new(get_bullets, set_bullets)

def asteroidsL():
  return Lens/new(get_asteroids, set_asteroids)