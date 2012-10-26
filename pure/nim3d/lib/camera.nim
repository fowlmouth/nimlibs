import gl_helpers, opengl, vector_math, nodes
type
  PCamera* = ref TCamera
  TCamera* = object
    pos*, target, up: TVector3f
    moveSpeed: TVector3f
    targetNode: PNode

proc newCamera*(): PCamera =
  new result
  result.up = vec3f(0.0, 1.0, 0.0)
  result.moveSpeed.z = -1.0

proc lookAt*(c: PCamera; n: PNode) =
  c.target = n.getPosition()
proc target*(c: PCamera; n: PNode) =
  c.targetNode = n

method apply*(c: PCamera) =
  if not(c.targetNode.isNil):
    c.lookAt(c.targetNode)
  
  glMatrixMode GL_MODELVIEW
  glLoadIdentity()
  
  gluLookat(c.pos.x, c.pos.y, c.pos.z, c.target.x, c.target.y, c.target.z,
            c.up.x, c.up.y, c.up.z)

proc getPosition*(c: PCamera): TVector3f = c.pos
proc setPosition*(c: PCamera; pos: TVector3f) = c.pos = pos
proc getTarget*(c: PCamera): var TVector3f = c.target
proc setTarget*(c: PCamera; pos: TVector3f){.inline.} = c.getTarget() = pos

proc moveForward*(c: PCamera; by: float) =
  let dir = (c.target - c.pos).normalize * -by
  c.pos += dir
  c.target += dir

proc strafeRight*(c: PCamera; by: float) =
  let dir = (c.target - c.pos).normalize.cross(c.up) * -by
  c.pos += dir
  c.target += dir
