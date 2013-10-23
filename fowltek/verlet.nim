discard """
http://www.gamedev.net/page/resources/_/technical/math-and-physics/a-verlet-based-approach-for-2d-game-physics-r2714

This is a small implementation of the verlet physics approach presented in the article.

The left mouse button will attach the closest vertex to the mouse,
which allows objects to be dragged around. Another mouse click will
release it. The right mouse will spawn new boxes.

The code is released under the ZLib/LibPNG license.
It basically means that you can treat the source in any way you like (including commercial applications),
but you may not claim that you wrote it.


Copyright (c) 2009 Benedikt Bitterli

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.

    3. This notice may not be removed or altered from any source
    distribution.
"""

## defines:
##   UseWorldBoundaries - adds width/height fields to TPhysics for global boundaries

import basic2d, math

type
  PVertex = ref TVertex
  TVertex = object
    position, oldPosition, acceleration: TVector2d
    parent: PBody

  PPhysics = var TPhysics
  TPhysics = object
    vertices: seq[PVertex]
    edges: seq[PEdge]
    bodies: seq[PBody]
    gravity: TVector2d
    iterations: int
    when defined(UseWorldBoundaries):
      width*, height*: int
    
  TCollisionInfo = object
    depth: float
    normal: TVector2d
    edge: PEdge
    vert: PVertex
  
  PBody = ref TBody
  TBody = object
    center: TVector2d
    vertices: seq[PVertex]
    edges: seq[PEdge]
    minX, minY, maxX, maxY: int
  
  PEdge = ref TEdge
  TEdge = object
    v1, v2: PVertex
    length: float
    boundary: bool
    parent: PBody

proc initPhysics (
    gravity = vector2d(0,0);
    iterations = 1): TPhysics =
  TPhysics(
    gravity: gravity,
    iterations: iterations,
    vertices: @[], edges: @[], bodies: @[])
          

iterator mitems[T] (some: var seq[T]): var T {.inline.} =
  for i in 0 .. < some.len:
    yield some[i]

proc updateForces (phys: PPhysics) =
  for v in phys.vertices.mitems:
    v.acceleration = phys.gravity

proc updateVerlet (phys: PPhysics; step: float) =
  for p in phys.vertices.mitems:
    let temp = p.position
    p.position += p.position - p.oldPosition + p.acceleration *
      step * step
    p.oldPosition = temp

proc updateEdges (phys: PPhysics) =
  for E in phys.edges.mitems:
    var
      v1v2 = e.v2.position - e.v1.position
    let
      diff = v1v2.len - e.length
    v1v2.normalize
    e.v1.position += v1v2 * diff * 0.5
    e.v2.position -= v1v2 * diff * 0.5

proc calculateCenter (body: PBody) =
  body.center.reset
  
  body.minX = 10000
  body.minY = 10000
  body.maxX = -10000
  body.maxY = -10000
  for V in body.vertices.mitems:
    body.center += V.position
    body.minX = min(body.minX.float, V.position.x).int
    body.minY = min(body.minY.float, V.position.y).int
    body.maxX = max(body.maxX.float, V.position.x).int
    body.maxY = max(body.maxY.float, v.position.y).int
  
  body.center /= body.vertices.len.float

proc overlaps (b1, b2: PBody): bool =
  (b1.minX <= b2.maxX and
    b1.minY <= b2.maxY and
    b1.maxX >= b2.minX and
    b2.maxY >= b2.minY)

proc projectToAxis (body: PBody; axis: TVector2d): tuple[min, max: float] =
  var dotP = axis.dot(body.vertices[0].position)
  result.min = dotP
  result.max = dotP
  
  for v in body.vertices.mitems:
    dotP = axis.dot(v.position)
    result.min = min(dotP, result.min)
    result.max = max(dotP, result.max)

proc detectCollision (b1, b2: PBody; collision: var TCollisionInfo): bool =
  var
    minDistance = 10_000.0
  let
    b1_edgeCount = b1.edges.len
  
  for I in 0 .. < (b1_edgeCount + b2.edges.len):
    let E = (if I < b1_edgeCount: b1.edges[I] else: b2.edges[I - b1_edgeCount])
    
    if not E.boundary: continue
    
    var axis = vector2d(
      E.v1.position.y - e.v2.position.y,
      E.v2.position.x - e.v1.position.x)
    
    axis.normalize
    
    var 
      (minA, maxA) = b1.projectToAxis(axis)
      (minB, maxB) = b2.projectToAxis(axis)
    
    proc intervalDistance(minA,maxA, minB,maxB: float): float =
      if minA < minB: minB - maxA else: minA - maxB
    let distance = intervalDistance(minA, maxA, minB, maxB)
    
    if distance > 0:
      return false
    elif distance.abs < minDistance:
      minDistance = distance.abs
      
      collision.normal = axis
      collision.edge = E
  
  collision.depth = minDistance
  
  var 
    b1 = b1
    b2 = b2
  if collision.edge.parent != b2:
    swap b1, b2
  
  template SGN (a): expr = (if a < 0 : -1 else: 1)
  let sign = sgn( collision.normal.dot(b1.center - b2.center))
  if sign != 1:
    collision.normal = - collision.normal
  
  let collisionV = collision.normal * collision.depth
  var smallestD = 10_000.0
  for v in b1.vertices.mitems:
    let dist = collision.normal.dot(v.position - b2.center)
    
    if dist < smallestD:
      smallestD = dist
      collision.vert = v
  
  return true

proc processCollision (phys: PPhysics; collision: var TCollisionInfo) =
  template e1 : expr = collision.edge.v1
  template e2 : expr = collision.edge.v2
  
  let collVector = collision.normal * collision.depth
  
  var T: float
  if abs(e1.position.x - e2.position.x) > abs(e1.position.y - e2.position.y):
    T = (collision.vert.position.x - collVector.X - e1.position.x) /
        (e2.position.x - e1.position.x)
  else:
    T = (collision.vert.position.y - collVector.y - e1.position.y) /
        (e2.position.y - e1.position.y)
  
  let lmbda = 1.0 / (T * T + (1.0 - T) * (1.0 - T))
  
  e1.position -= collVector * (1.0 - T) * 0.5 * lmbda
  e2.position -= collVector * T * 0.5 * lmbda
  
  collision.vert.position += collVector * 0.5

proc iterateCollisions (phys: PPhysics) =
  var collision: TCollisionInfo
  
  for i in 0 .. <phys.iterations:
    
    when defined(UseWorldBoundaries):
      for V in phys.vertices.mitems:
        V.position.x = max(min(v.position.x, phys.width.float), 0.0)
        V.position.y = max(min(v.position.y, phys.height.float),0.0)
    
    phys.updateEdges
    
    let nBodies = < phys.bodies.len
    for I in 0 .. nbodies:
      phys.bodies[I].calculateCenter
    
    for b1 in 0 .. nbodies:
      for b2 in 0 .. nbodies:
        if b1 != b2:
          if phys.bodies[b1].overlaps(phys.bodies[b2]):
            if phys.bodies[b1].detectCollision(phys.bodies[b2], collision):
              phys.processCollision collision

proc update* (phys: PPhysics; step: float) =
  phys.updateForces
  phys.updateVerlet step
  phys.iterateCollisions

proc add (body: PBody; edge: PEdge) {.inline.} = body.edges.add edge
proc add (body: PBody; vert: PVertex){.inline.}= body.vertices.add vert
proc add (phys: PPhysics; edge: PEdge) {.inline.} = phys.edges.add edge
proc add (phys: PPhysics; body: PBody) {.inline.} = phys.bodies.add body
proc add (phys: PPhysics; vert: PVertex){.inline.}= phys.vertices.add vert

proc newEdge* (
      phys: PPhysics; body: PBody; 
      v1, v2: PVertex; boundary = true): PEdge {.discardable.} =
  result = PEdge(
    v1: v1, v2: v2,
    length: (v2.position - v1.position).len,
    boundary: boundary,
    parent: body)
  
  body.add result
  phys.add result

proc newBody (phys: PPhysics): PBody {.discardable.} =
  result = PBody(edges: @[], vertices: @[])
  phys.add result

proc newVertex (phys: PPhysics; body: PBody; X,Y: float): PVertex {.discardable.}=
  let pos = vector2d(x, y)
  result = PVertex(
    position: pos, oldPosition: pos,
    parent: body)
  
  body.add result
  phys.add result

proc createBox* (phys: PPhysics; X,Y, W,H: float): PBody {.discardable.} =
  result = phys.newBody()
  
  var
    v1 = phys.newVertex(result, X, Y)
    v2 = phys.newVertex(result, X+W, Y)
    v3 = phys.newVertex(result, X+W, Y+H)
    v4 = phys.newVertex(result, X, Y+H)
  
  phys.newEdge(result, v1, v2, true)
  phys.newEdge(result, v2, v3, true)
  phys.newEdge(result, v3, v4, true)
  phys.newEdge(result, v4, v1, true)
  
  phys.newEdge(result, v1, v3, false)
  phys.newEdge(result, v2, v4, false)
  
proc findVertex* (phys: PPhysics; coord: TVector2d): PVertex =
  var minDist = 1_000.0
  
  for v in phys.vertices:
    let dist = (v.position - coord).sqrLen
    
    if dist < minDist:
      result = v
      minDist = dist

when isMainModule:
  import fowltek/sdl2/engine2
  import_all_sdl2_things
  
  const
    width = 800
    height= 600
  
  var
    ng: TGameEngine
    gs: PGameState
    draggingVertex: PVertex 
    mousePos: TPoint2d
    world = initPhysics(gravity = vector2d(0, 9.8), iterations = 10)
  
  when defined(UseWorldBoundaries):
    world.width = width
    world.height= height
  
  block setupScene:
    for x in countup(20, <width, 100):
      for y in countup(50, <height, 100):
        discard world.createBox(X.float, Y.float, 50, 50)
    
    for x in countup(50, < (width - 50), 130):
      let 
        body = world.newBody
      
        v1 = world.newVertex(body, x.float, 45)
        v2 = world.newVertex(body, (x+50).float, 0)
        v3 = world.newVertex(body, (x+100).float, 45)
      
      world.newEdge body, v1, v2
      world.newEdge body, v2, v3
      world.newEdge body, v3, v1
  
  proc draw (E: PGameEngine) =
    E.setDrawColor 255,0,0,255
    for edge in world.edges:
      E.drawLine(
        edge.v1.position.x.cint, edge.v1.position.y.cint,
        edge.v2.position.x.cint, edge.v2.position.y.cint
      )
    
    E.setDrawColor 255,255,255,255
    for vert in world.vertices:
      E.drawPoint(
        vert.position.x.cint, vert.position.y.cint
      )
    
    E.stringRGBA 100,100, "Hello, Nimrods.",
      0,240,50,255
  
  proc update(E: PGameEngine; dt: float) =
    if not draggingVertex.isNil:
      draggingVertex.position.x = mousePos.x
      draggingVertex.position.y = mousePOs.y
    world.update dt
  
  gs = newGameState(update, draw)
  gs.addHandler closeOnQuitEventOrKey(K_ESCAPE)
  gs.addHandler do(E: PGameEngine; evt: var TEvent)->bool:
    result = evt.kind in {MouseButtonDown, MouseButtonUp}
    if result:
      let m = evt.evMouseButton
      case m.button
      of BUTTON_LEFT:
        if evt.kind == mouseButtonDown and draggingVertex.isNil:
          draggingVertex = world.findVertex(vector2d(m.x.float, m.y.float))
        elif evt.kind == mouseButtonUp:
          draggingVertex = nil
      
      of BUTTON_RIGHT:
        if evt.kind == mouseButtonDown:
          world.createBox(m.x.float, m.y.float, 50,50)
      
      else: nil
  gs.addHandler do(E: PGameEngine; evt: var TEvent)->bool:
    result = evt.kind == MouseMotion
    if result:
      let m = evt.evMouseMotion
      mousePos.x = m.x.float
      mousePos.y = m.y.float
  
  ng = newGameEngine(gs, 
    sizeX = width, sizeY = height,
    imageRoot = ".")
  ng.run
