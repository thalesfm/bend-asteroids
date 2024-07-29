import ./util/List

# TODO: Key press, down, and up

def new():
  return List/Nil

def get_key(input, key):
  return List/elem(key, input)

def register_key_down(input, key):
  return List/Cons(key, input)

def register_key_up(input, key):
  return List/delete(key, input)