import ./api/Command
import ./util/List
import ./util/DiffList

new = DiffList/new

push = DiffList/append

concat = DiffList/concat

def flush(buf):
  return List/map(Command/clone, DiffList/to_list(buf))