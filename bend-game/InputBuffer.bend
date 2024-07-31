import ./util/List

object InputBuffer { keys, down }

def new():
  return InputBuffer([], [])

def clear_key_down(input):
  open InputBuffer: input
  return InputBuffer(input.keys, [])

def get_key(input, keycode):
  open InputBuffer: input
  return List/elem(keycode, input.keys)

def get_key_down(input, keycode):
  open InputBuffer: input
  return List/elem(keycode, input.down)

def register_key_up(input, keycode):
  open InputBuffer: input
  keys = List/delete(keycode, input.keys)
  return InputBuffer(keys, input.down)

def register_key_down(input, keycode):
  open InputBuffer: input
  keys = List/Cons(keycode, input.keys)
  down = List/Cons(keycode, input.down)
  return InputBuffer(keys, down)