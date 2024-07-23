object App { init, tick, draw }

object Color { r, g, b, a }

type Command
  = (Clear color)
  | (DrawLine x1 y1 x2 y2 color)