import ./Transform

object PhysicsBody { vx, vy, vrot }

def step(dt, xform, pbody):
  open Transform: xform
  open PhysicsBody: pbody
  x = xform.x + pbody.vx * dt
  y = xform.y + pbody.vy * dt
  rot = xform.rot + pbody.vrot * dt
  return Transform(x, y, rot)

# def apply_impulse(...)