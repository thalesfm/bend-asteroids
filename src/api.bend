object App { init, tick, draw }

object Color { r, g, b, a }

WHITE = (Color 1.0 1.0 1.0 1.0)

type Command:
  Clear { color }
  DrawLine { x1, y1, x2, y2, color }

CommandBuffer/new = DiffList/new

CommandBuffer/push = DiffList/append

CommandBuffer/flush = DiffList/to_list

CommandBuffer/concat = DiffList/concat

object CommandWriter { val, buf }

# def CommandWriter/wrap(val): # a -> (CommandWriter a)
#   return Writer(val, DiffList/new)

def CommandWriter/tell(buf): # CommandBuffer -> (CommandWriter *)
  return CommandWriter(0, buf)

# def CommandWriter/bind(cw1, nxt): # (CommandWriter a) -> (a -> CommandWriter b) -> CommandWriter b
#   open CommandWriter: cw1
#   nxt = undefer(nxt)
#   cw2 = nxt(cw1.val)
#   open CommandWriter: cw2
#   buf = CommandBuffer/concat(cw1.buf, cw2.buf)
#   return CommandWriter(cw2.val, buf)

def clear(color): # Color -> (CommandWriter *):
  buf = CommandBuffer/new
  buf = CommandBuffer/push(buf, Command/Clear(color))
  return CommandWriter(0, buf)

def draw_line(x1, y1, x2, y2, color):
  buf = CommandBuffer/new
  buf = CommandBuffer/push(buf, Command/DrawLine(x1, y1, x2, y2, color))
  return CommandWriter(0, buf)

def DiffList/concat(diff1, diff2):
  return lambda x: diff1(diff2(x))