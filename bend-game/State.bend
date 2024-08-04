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

# put : s -> State s ()
def put(state, _state):
  return (*, state)

# gets : (s -> a) -> State s a
def gets(fun):
  # Workaround for compiler error
  # (attempt to clone non-affine global reference)
  def run(state):
    return (fun(state), state)
  return run

# modify : (s -> s) -> State s ()
# def modify(fun, state):
#   return (*, fun(state))
def modify(fun):
  def run(state):
    return (*, fun(state))
  return run

# wrap : a -> State s a
def wrap(val, state):
  return (val, state)

# bind : State s a -> (a -> State s b) -> State s b
def bind(run, next, state):
  (val, state) = run(state)
  next = undefer(next)
  return next(val, state)