import tables, fowltek/tmaybe, fowltek/boundingbox
export tables, boundingbox, tmaybe

type
  PBB_Node*[T] = ref TBB_Node[T] 
  TBB_Node*[T] = object
    parent: PBB_Node[T]
    node_a, node_b: PBB_Node[T]
    bb: TBB
    obj: TMaybe[T]

  PBB_Tree*[T] = var TBB_Tree[T]
  TBB_Tree*[T] = object
    items: TTable[T, PBB_Node[T]]
    root: PBB_Node[T]


proc newBBtree* [T] : TBB_Tree[T] =
  result.items = initTable[T, PBB_Node[T]](512)
proc newBBnode* [T](obj: T; bb: TBB): PBB_Node[T] {.
  inline.} = PBB_Node[T](
    obj: Just(obj), 
    bb: bb)
proc newBBnode* [T](bb: TBB): PBB_Node[T] =
  new result
  result.bb = bb
 
proc a* [T](node: PBB_Node[T]): PBB_Node[T] {.inline.} = node.node_a
proc `a=`*[T](node, val: PBB_Node[T]) {.inline.} =
  node.node_a = val
  node.node_a.parent = node
proc b* [T](node: PBB_Node[T]): PBB_Node[T] {.inline.} = node.node_b
proc `b=`*[T](node, val: PBB_Node[T]) {.inline.} = 
  node.node_b = val
  node.node_b.parent = node 

proc isLeaf*[T] (node: PBB_Node[T]): bool {.inline.} = node.obj

template otherchild (node, child): expr = (if node.a == child: node.b else: node.a)

type E_SomeError* = object of E_Base


proc updateBB* [T] (node: PBB_Node[T]) {.inline.}=
  if not node.isLeaf:
    var n = node 
    while not n.isNil:
      n.bb.refitFor(n.a.bb, n.b.bb)
      n = n.parent


proc disownChild* [T] (node, leaf: PBB_Node[T]) =
  if node.parent.isLeaf: 
    raise newException(E_SomeError, "Cannot replace the child of a leaf")
  if not(node == node.parent.a or node == node.parent.b):
    raise newException(E_SomeError, "AABBNode is not a child of parent")
  
  template other: expr = otherChild(node, leaf)
  
  if node.parent.a == node:
    node.parent.a = other
  else: 
    node.parent.b = other

  node.parent.updateBB

proc removeSubtree*[T] (node, leaf: PBB_Node[T]): PBB_Node[T] =
  if leaf == node: return nil
  
  if leaf.parent == node:
    var oc = otherchild(node,leaf)
    oc.parent = node.parent
    return oc
  
  leaf.parent.disownChild leaf
  return node

proc proximity* [T] (node, leaf: PBB_Node[T]): float = (
  (node.bb.left + node.bb.right - leaf.bb.left - leaf.bb.right).abs +
  (node.bb.bottom + node.bb.top - leaf.bb.bottom - leaf.bb.top).abs)
 
proc insertSubtree*[T] (node, leaf: PBB_Node[T]): PBB_Node[T] =
  if node.isLeaf:
    var n_n : PBB_node[T] #= newBBnode[T](node.bb.unionFast(leaf.bb))
    new n_n
    n_n.bb = node.bb.unionFast(leaf.bb)
    n_n.a = node
    n_n.b = leaf
    return n_n

  var 
    cost_a = node.b.bb.area + node.a.bb.unionArea(leaf.bb)
    cost_b = node.a.bb.area + node.b.bb.unionArea(leaf.bb)
  
  if cost_a == cost_b :
    cost_a = node.a.proximity(leaf)
    cost_b = node.b.proximity(leaf)
  if cost_b < cost_a:
    node.b = node.b.insertSubtree(leaf)
  else:
    node.a = node.a.insertSubtree(leaf)
  
  node.bb.expandToInclude leaf.bb
  return node 

proc insertLeaf*[T] (tree: PBB_Tree[T]; leaf: PBB_Node[T]) =
  if not tree.root.isNil:
    tree.root = tree.root.insertSubtree(leaf)
  else:
    tree.root = leaf

proc remove*[T] (tree: PBB_Tree[T]; item: T) =
  if tree.items.hasKey(item):
    tree.root = tree.root.removeSubtree(tree.items[item]) 
    tree.items.del item

proc update*[T] (tree: PBB_Tree[T]; item: T; bb: TBB) =
  let node = tree.items[item]
  if not(node.isNil) and node.isLeaf:
    if bb notin node.bb:
      node.bb = bb
      tree.root = tree.root.removeSubtree(node)
      tree.insertLeaf node

proc insert*[T] (tree: PBB_Tree[T]; item: T; bb: TBB) =
  if tree.items.hasKey(item):
    update[T](tree, item, bb)
    return
  var leaf = newBBnode[T](item, bb)
  tree.items[item] = leaf
  tree.insertLeaf leaf

proc querySubtree* [T] (node: PBB_Node[T]; bb: TBB; cb: proc(item: T)) =
  if node.bb.collidesWith(bb):
    if not node.isLeaf:
      node.a.querySubtree bb, cb
      node.b.querySubtree bb, cb
    else:
      cb node.obj.val
proc query* [T] (tree: PBB_Tree[T]; bb: TBB; cb: proc(item: T)) {.inline.} =
  if tree.root.isNil: return
  tree.root.querySubtree bb, cb

proc collectCollisions* [T] (tree: PBB_Tree[T]; bb: TBB; result: var seq[T]) {.inline.} =
  if tree.root.isNil: return
  let res = result.addr
  tree.query(bb) do (item: T):
    res[].add(item)

proc collectCollisions* [T] (tree: PBB_Tree[T]; item: T; result: var seq[T]) {.inline.} =
  if tree.root.isNil: return
  let res = result.addr
  tree.query(tree.items[item].bb) do (item2: T):
    if item != item2: res[].add item2

proc collectCollisions* [T] (tree: PBB_Tree[T]; bb: TBB|T): seq[T] {.inline.}=
  result = @[]
  tree.collectCollisions bb, result


proc itemCount* [T] (tree: PBB_Tree[T]): int {.inline.} = tree.items.len

## exposed for the test, mainly
proc getObj* [T] (node: PBB_Node[T]): TMaybe[T] {.inline.} = node.obj
proc getBB*  [T] (node: PBB_Node[T]): TBB {.inline.} = node.bb
proc getRoot* [T] (tree: PBB_Tree[T]): PBB_Node[T] {.inline.} = tree.root
proc hasItem* [T] (tree: PBB_Tree[T]; item: T): bool {.inline.} = tree.items.hasKey(item)

when defined(usesdl2) or isMainModule:
  import fowltek/sdl2/engine, colors
  import_all_sdl2_modules
  import_all_sdl2_helpers
  
  let colRed = colRed.toSDLcolor
  
  proc rectangleRGBA* (R: PRenderer, BB: TBB; col: sdl2.TColor) {.inline.} =
    R.rectangleRGBA bb.left.int16, bb.top.int16, bb.right.int16, bb.bottom.int16,
      col.R, col.G, col.B, col.A 
  
  proc debugDraw* [T] (some: PBB_Node[T]; R: PRenderer; depth = 0) =
    var col = colRed
    col.a = ((depth+10).min(13) * 19).uint8  
    R.rectangleRGBA some.bb, col
    if not some.isLeaf:
      some.a.debugDraw R, depth+1
      some.b.debugDraw R, depth+1

    when compiles(debugDraw(some.bb, some.obj.val, R)):
      if some.isLeaf:
        debugDraw some.bb, some.obj.val, R
  
  proc debugDraw* [T] (some: PBB_Tree[T]; r: PRenderer) = 
    debugDraw some.root, r
  

when isMainModule:
  import unsigned
  
  import math
  randomize()
  
  var NG = newSdlEngine()
  let windowSize = NG.window.getSize
  
  var tree = newBBtree[int]()
  var id = 0
  
  proc debugDraw* (bb: TBB, item: int, R: PRenderer) =
    R.stringRGBA bb.left.int16, bb.top.int16, $item, 0,255,0,255
  
  proc insert_a_box =
    var box = bb(random(windowSize.x - 10) + 20, random(windowSize.y - 10) + 20, 
      random(400)+40, random(100)+20)
    inc id
    tree.insert id, box
  
  #insert_a_box()
  
  block:
    template ii (i, bb): stmt = tree.insert i, bb
    ii 1,  bb(0, 0, 10, 10)
    ii 2, bb(15, 0, 10, 20)
    ii 3, bb(0, 15, 20, 10)
    ii 4, bb(0, 50, 20, 5)
    
    #var bounds = tree.root.bb
    #var rect = rect(0, 0, 100, 100)#( bounds.width + 10).cint, (bounds.height + 10).cint)
    #echo rect
    #NG.setViewport rect.addr
    NG.setScale 4.0, 4.0

  
  var running = true
  while running:
    while NG.pollHandle:
      case NG.evt.kind 
      of QuitEvent:
        running = false
      of MouseButtonDown: 
        let m = evmousebutton(ng.evt)
        if m.button == Button_LEFT:
          let box = bb(m.x.int, m.y.int, 0,0)
          tree.query box, proc(x: int) = 
            echo "got ", x
      of KeyDown:
        let k = evKeyboard(NG.evt).keysym.sym
        case k
        of K_SPACE:
          #insert_a_box()
        
        else:nil
        
      else:nil
    
    let dt = NG.frameDeltaFLT
    
    NG.setDrawColor 0,0,0,255
    NG.clear
    
    tree.debugDraw NG
    
    NG.present
  
  NG.destroy

