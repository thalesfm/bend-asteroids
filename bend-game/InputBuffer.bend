import ./util/List

object InputBuffer { keys, down }

def new():
  return InputBuffer([], [])

def clear_key_down(input):
  open InputBuffer: input
  return InputBuffer(input.keys, [])

def get_key(key, input):
  open InputBuffer: input
  return List/elem(key, input.keys)

def get_key_down(key, input):
  open InputBuffer: input
  return List/elem(key, input.down)

def register_key_up(key, input):
  open InputBuffer: input
  keys = List/delete(key, input.keys)
  return InputBuffer(keys, input.down)

def register_key_down(key, input):
  open InputBuffer: input
  keys = List/Cons(key, input.keys)
  down = List/Cons(key, input.down)
  return InputBuffer(keys, down)