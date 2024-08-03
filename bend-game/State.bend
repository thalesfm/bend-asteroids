# State s a = s -> (a, s)

def eval(run, state):
  (val, *) = run(state)
  return val

def exec(run, state):
  (*, state) = run(state)
  return state

# get : State s s
def get(state):
  return (state, state)

# set : s -> State s ()
def set(state, _state):
  return (*, state)

# prj : (s -> a) -> State s a
def prj(fun, state):
  return (fun(state), state)

# mod : (s -> s) -> State s ()
def mod(fun, state):
  return (*, fun(state))

# wrap : a -> State s a
def wrap(val, state):
  return (val, state)

# bind : State s a -> (a -> State s b) -> State s b
def bind(run, next, state):
  (val, state) = run(state)
  next = undefer(next)
  return next(val, state)