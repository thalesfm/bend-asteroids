def concat(diff1, diff2):
  return lambda x: diff1(diff2(x))