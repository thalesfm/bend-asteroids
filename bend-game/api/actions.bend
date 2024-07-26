import ./Command
import ./CommandBuffer
import ./CommandWriter

def push_command(cmd):
  return CommandWriter/tell(CommandBuffer/push(CommandBuffer/new, cmd))

def clear(color):
  return push_command(Command/Clear(color))

def draw_line(x1, y1, x2, y2, color):
  return push_command(Command/DrawLine(x1, y1, x2, y2, 1.0, color))

def draw_text(text, x, y, color):
  return push_command(Command/DrawText(text, x, y, 20.0, color))
