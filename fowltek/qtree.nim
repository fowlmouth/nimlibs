import fowltek/vector_math
type
  TVector2f* = TVector2[float]
  TBounds* = tuple[x, y, w, h: float]

type
  TCorner* = enum TopLeft, TopRight, BottomLeft, BottomRight
  PNode*[T] = ref TNode[T]
  TNode*[T] = object
    bounds: TBounds
    maxChildren, maxDepth, depth: int
    nodes: array[TCorner, PNode[T]]
    children: seq[TItem[T]]
  
  TItem[T] = tuple[pos: TBounds, val: T]
  
  TQuadTree*[T] = object
    root: PNode[T]

proc newNode*[T] (bounds: TBounds; depth, maxDepth, maxChildren: int) : PNode[T] =
  result = PNode[T](
    bounds: bounds,
    maxChildren: maxChildren,
    maxDepth: maxDepth,
    depth: depth,
    children: @[]
  )

proc QuadTree*[T](bounds: TBounds; maxDepth = 4; maxChildren = 1): TQuadTree[T] =
  result = TQuadTree[T](root: newNode[T](bounds, 0, maxDepth, maxChildren))

proc findNodeFor*[T] (node: PNode[T]; pos: TVector2f): PNode[T] =
  let left = (if pos.x > node.bounds.x + node.bounds.w / 2: false else: true)
  let top  = (if pos.y > node.bounds.y + node.bounds.h / 2: false else: true)

  return node.nodes[(
    if left: (if top: TopLeft else: BottomLeft) else: (if top: TopRight else: BottomRight) )]
proc findNodeFor*[T] (node: PNode[T]; bounds: TBounds): PNode[T] = findNodeFor(node, (bounds.x, bounds.y))

proc divide* [T](node: PNode[T]) =
  let
    depth = node.depth + 1
    bounds_half_w = node.bounds.w / 2
    bounds_half_h = node.bounds.h / 2
  
  template nn(b): expr = newNode[T](b, depth, node.maxDepth, node.maxChildren)
  
  node.nodes[TopLeft] = nn((
    node.bounds.x, node.bounds.y,
    bounds_half_w, bounds_half_h  ))
  node.nodes[TopRight] = nn((
    node.bounds.x + bounds_half_w,   node.bounds.y,
    bounds_half_w, bounds_half_h  ))
  node.nodes[BottomLeft] = nn((
    node.bounds.x, node.bounds.y + bounds_half_h,
    bounds_half_w, bounds_half_h  ))
  node.nodes[BottomRight]= nn((
    node.bounds.x + bounds_half_w, node.bounds.y + bounds_half_h,
    bounds_half_w, bounds_half_h  ))


proc isPartitioned* [T](node: PNode[T]): Bool {.
  inline.} = not node.nodes[0.TCorner].isNil

proc insert* [T] (node: PNode[T]; item: TItem[T] ) =
  if node.isPartitioned:
    node.findNodeFor(item.pos).insert(item)
    return

  node.children.add item
  if node.children.len > node.maxChildren and node.depth < node.maxDepth :
    node.divide
    for i in 0.. <node.children.len: node.insert node.children[i]
    node.children.setLen 0

proc insert* [T] (tree: var TQuadTree[T]; items: varargs[TItem[T]]) {.inline.} =
  for it in items:  tree.root.insert it
proc insert* [T] (tree: var TQuadTree[T]; pos: TBounds; item: T) {.inline.} = tree.root.insert((pos, item))

proc clear* [T] (node: PNode[T]) = 
  node.children.setLen 0
  if node.isPartitioned:
    for corner in TCorner:
      {.unroll.}
      node.nodes[corner].clear
    reset node.nodes
proc clear* [T] (tree: var TQuadTree[T]) {.inline.} = tree.root.clear

proc retrieve* [T] (node: PNode[T]; bounds: TBounds, result: var seq[TItem[T]]) =
  if node.isPartitioned:
    node.findNodeFor(bounds).retrieve(bounds, result)
  result.add node.children

proc retrieve* [T] (tree: var TQuadTree[T]; bounds: TBounds): seq[TItem[T]] =
  result.newSeq 0
  tree.root.retrieve bounds, result

proc bounds* [T](x, y, w, h: T): TBounds {.inline.} = (x.float, y.float, w.float, h.float)
proc right* (some: TBounds): float {.inline.} = some.x + some.w
proc bottom*(some: TBounds): float {.inline.} = some.y + some.h
proc top* (some: TBounds): float {.inline.} = some.y
proc left*(some: TBounds): float {.inline.} = some.x


when isMainModule:
  
  import fowltek/sdl2/engine, colors
  import_all_sdl2_modules
  import math, os, strutils
  randomize()
  
  let 
    NUM_TO_TRY = if paramCount() == 1: paramStr(1).parseInt.int else: 30
    depthColors = [
      colGreen.toSDLcolor, colBlue.toSDLcolor, colYellow.toSDLcolor, colRed.toSDLcolor, colWhite.toSDLcolor] 
    borderColors: array[TCorner, sdl2.TColor] = [
      colRed.toSDLcolor, colGreen.toSDLcolor, colBlue.toSDLcolor, colYellow.toSDLcolor]
   
    colWHITE = colWHite.toSDLcolor
  
  
  proc rectangleRGBA* (R: PRenderer; Rect: TBounds; color: sdl2.TColor) {.inline.} =
    rectangleRGBA(R, Rect.x.int16, rect.y.int16, rect.right.int16, rect.bottom.int16, color.r, color.g, color.b, color.a)
  
  proc debugDraw* (item: int, pos: TBounds; R: PRenderer) {.inline.} =
    R.stringRGBA pos.x.int16, pos.y.int16, $item, 0,255,0,255
  
  proc debugDraw* [T](items: seq[TItem[T]]; R: PRenderer) {.inline.} =
    for i in 0 .. <items.len: debugDraw items[i].val, items[i].pos, R
  
  proc debugDraw* [T](node: PNode[T]; R: Prenderer) {.inline.}=
    if node.isPartitioned:
      for c in TCorner:
        {.unroll.}
        debugDraw node.nodes[c], R
    
    template col: expr = depthColors[node.depth mod 5]
    R.rectangleRGBA node.bounds.x.int16, node.bounds.y.int16, 
      node.bounds.right.int16, node.bounds.bottom.int16,
      col.r, col.g, col.b, col.a
    
    debugDraw node.children, R
    
  proc debugDraw* [T](tree: var TQuadTree[T]; R: Prenderer) {.inline.} = tree.root.debugDraw(R) 

  var engy = newSdlEngine(sizeX = 800, sizeY = 800)
  let winSize = engy.window.getSize()
  var quad = QuadTree[int]((x: 0.0, y: 0.0, w: winsize.x.float, h: winsize.y.float),
    10, 3)
  
  var ID = 0
  while ID < NUM_TO_TRY:
    let bounds = bounds(winSize.x.random, winSize.y.random, ($ID).len * 8, 10)
    quad.insert bounds, ID
    ID.inc
  
  var running = true
  var mousePos: TBounds
  while running:
    while engy.pollHandle:
      case engy.evt.kind
      of QuitEvent: running = false
      of MouseMotion:
        let m = evMouseMotion(engy.evt)
        mousePos.x = m.x.float
        mousePos.y = m.y.float
      of KeyDown:
        if evKeyboard(Engy.evt).keysym.sym == K_Escape: running = false
      else: nil
  
    let dt = engy.frameDeltaFlt()
    
    engy.setDrawColor 0,0,0,255
    engy.clear
    
    quad.debugDraw engy
    let res = quad.retrieve(bounds(mousePos.x, mousePos.y, 0.0,0.0))
    for i in 0 .. <res.len:
      engy.rectangleRGBA res[i][0], colWhite
      
    engy.present
    
  for it in items(quad.retrieve((11.0, 13.0, 10.0, 20.0))):
    echo($it)
    
