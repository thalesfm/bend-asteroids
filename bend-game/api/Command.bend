import ./Color

type Command:
  Clear { color }
  DrawLine { x1, y1, x2, y2, thickness, color }
  DrawCircle { x, y, r, thickness, color }
  DrawText { text, x, y, font_size, color }

def clone(cmd):
  match cmd:
    case Command/Clear:
      color = Color/clone(cmd.color)
      return Command/Clear(color)
    case Command/DrawLine:
      color = Color/clone(cmd.color)
      return Command/DrawLine(cmd.x1, cmd.y1, cmd.x2, cmd.y2, cmd.thickness, color)
    case Command/DrawCircle:
      color = Color/clone(cmd.color)
      return Command/DrawCircle(cmd.x, cmd.y, cmd.r, cmd.thickness, color)
    case Command/DrawText:
      color = Color/clone(cmd.color)
      return Command/DrawText(cmd.text, cmd.x, cmd.y, cmd.font_size, color)
