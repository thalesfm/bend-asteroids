object Color { r, g, b, a }

WHITE = (Color 1.0 1.0 1.0 1.0)
BLACK = (Color 0.0 0.0 0.0 1.0)

def clone(color):
  open Color: color
  r = color.r + 0.0
  g = color.g + 0.0
  b = color.b + 0.0
  a = color.a + 0.0
  return Color(r, g, b, a)