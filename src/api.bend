object App { init, tick, draw }

object Color { r, g, b, a }

type Command:
  Clear { color }
  DrawLine { x1, y1, x2, y2, color }

CommandBuffer/new = DiffList/new

CommandBuffer/push = DiffList/append

List/map _ (List/Nil) = []
List/map f (List/Cons x xs) = (List/Cons (f x) (List/map f xs))

CommandBuffer/flush = DiffList/to_list
# CommandBuffer/flush buf = (List/map (λx x) (DiffList/to_list buf))
# CommandBuffer/flush buf = match (DiffList/to_list buf) { ...

clear buf color =
  (CommandBuffer/push buf (Command/Clear color))

draw_line buf x1 y1 x2 y2 color =
  (CommandBuffer/push buf (Command/DrawLine x1 y1 x2 y2 color))
