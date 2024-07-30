# LCG random number generator using MSVB parameters
# https://en.wikipedia.org/wiki/Linear_congruential_generator

def seed(value):
  return value

def next(state):
  state = 16598013 * state + 12820163
  return state, state

def unif(lo, hi, state):
  value, state = next(state)
  value = value % (hi - lo) + lo
  return value, state

def unit(state):
  value, state = next(state)
  value = to_f24(value >> 8) / 65536.0
  return value, state