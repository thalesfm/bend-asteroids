object GameState { mode, player, bullets, asteroids, input }

def set_mode(mode, state):
  open GameState: state
  return GameState(mode, state.player, state.bullets, state.asteroids, state.input)

def set_input(input, state):
  open GameState: state
  return GameState(state.mode, state.player, state.bullets, state.asteroids, input)