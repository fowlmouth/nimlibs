import
  gl_helpers, opengl, vector_math
type
  PNode* = ref TNode
  TNode* {.inheritable.} = object
    pos*, rot*, scale*: TVector3f
    children: seq[PNode]
  
  PScene* = ref TScene
  TScene* = object of TNode
  
  PPrimitiveNode* = ref TPrimitiveNode
  TPrimitiveNode* = object of TNode
    renderProc: proc(n: PPrimitiveNode)
    color: TColor4f

proc init*(node: PNode) =
  node.children = @[]
  node.scale.x = 1.0
  node.scale.y = 1.0
  node.scale.z = 1.0
proc add*(node: PNode; child: PNode) = 
  node.children.add(child)

method render*(node: PNode) = nil

proc renderChildren*(node: PNode) =
  for n in items(node.children):
    pushMatrixGL:
      render(n)

proc applyTransform*(n: PNode) =
  glTranslatef n.pos.x, n.pos.y, n.pos.z
  glRotatef n.rot.x, 1.0, 0.0, 0.0
  glRotatef n.rot.y, 0.0, 1.0, 0.0
  glRotatef n.rot.z, 0.0, 0.0, 1.0
  glScalef n.scale.x, n.scale.y, n.scale.z

proc getPosition*(node: PNode): var TVector3f = node.pos
proc setPosition*(node: PNode; pos: TVector3f) = node.pos = pos

proc newScene*(): PScene =
  new result
  init PNode(result)

method render*(node: PScene) = renderChildren(node)

method render*(node: PPrimitiveNode) =
  node.applyTransform()
  glColorFV node.color
  node.renderProc(node)

proc newPrimitive*(color: TColor4f): PPrimitiveNode =
  new result
  init PNode(result)
  result.color = color

proc newWireCube*(size: float; color: TColor4f): PPrimitiveNode =
  result = newPrimitive(color)
  result.renderProc = proc(n: PPrimitiveNode) =
    drawWireCube size

proc newSolidCube*(size: float; color: TColor4f): PPrimitiveNode =
  result = newPrimitive(color)
  result.renderProc = proc(n: PPrimitiveNode) =
    drawSolidCube size

proc newWireSphere*(size: float; color: TColor4f): PPrimitiveNode =
  result = newPrimitive(color)
  result.renderProc = proc(n: PPrimitiveNode) = 
    drawWireSphere size, 10, 10

when defined(UseODE):
  import ode

  type
    PPhysicsNode* = ref TPhysicsNode
    TPhysicsNode = object of TPrimitiveNode
      body: PBody
      mass: TMass
      geom: PGeom

  proc newPhysicsNode*(): PPhysicsNode =
    new result ##do free when im sure how to free the ode stuff
    init PNode(result)
  
  proc newPhysSphere*(world: PWorld, space: PSpace; pos: TVector3f; radius: dReal): PPhysicsNode =
    result = newPhysicsNode()
    result.body = world.createBody()
    result.geom = space.createSphere(radius)
    (addr result.mass).setSphere(1.0, 0.5)
    result.body.setMass(addr(result.mass))
    result.geom.setBody result.body
    result.body.setPosition(pos.x, pos.y, pos.z)
    result.color = colorf(0.0, 1.0, 0.0)
    result.renderProc = proc(n: PPrimitiveNode) =
      drawWireSphere radius, 10, 10
  


  proc setPosition*(node: PNode; pos: ptr ode.TVector3) =
    node.pos.x = pos[0]
    node.pos.y = pos[1]
    node.pos.z = pos[2]

  import strutils
  proc `$`(x: ptr ode.TMatrix3): string =
    result = """[$1 $2 $3 $4
  $5 $6 $7 $8
  $9 $10 $11 $12]""".
      format(x[0], x[1], x[2], x[3], 
             x[4], x[5], x[6], x[7], 
             x[8], x[9], x[10], x[11])
  
  proc setRotation*(node: PNode; val: ptr ode.TMatrix3) =
    ##echo($ val)#repr(val))
    ##this aint right btw
    node.rot.x = val[3]
    node.rot.y = val[3+4]
    node.rot.z = val[3+8]

