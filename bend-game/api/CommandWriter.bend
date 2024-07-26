import ./CommandBuffer

object CommandWriter { val, buf }

def wrap(val):
  return CommandWriter(val, CommandBuffer/new)

def tell(buf):
  return CommandWriter(0, buf)

def bind(cw1, nxt):
  open CommandWriter: cw1
  nxt = undefer(nxt)
  cw2 = nxt(cw1.val)
  open CommandWriter: cw2
  buf = CommandBuffer/concat(cw1.buf, cw2.buf)
  return CommandWriter(cw2.val, buf)
