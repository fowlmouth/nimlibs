import macros


proc newEmptyNode*(): PNimrodNode {.compileTime, noSideEffect.} =
  ## Create a new empty node 
  result = newNimNode(nnkEmpty)


proc und*(a: PNimrodNode, b: varargs[PNimrodNode]): PNimrodNode {.
                                                  compileTime, discardable.} =
  ## Add nodes B to A and return A
  ## Allow nesting o
  a.add b
  return a

proc newStmtList*(stmts: varargs[PNimrodNode]): PNimrodNode {.compileTime.}=
  ## Create a new statement list
  result = newNimNode(nnkStmtList).und(stmts)

proc newNilLit*(): PNimrodNode {.compileTime.} =
  ## New nil literal shortcut
  result = newNimNode(nnkNilLit)

proc isEmpty*(someNode: PNimrodNode): bool {.
  compileTime, inline.} = someNode.kind == nnkEmpty
  ## Check if the node is empty. Try to keep up. :^)

template ProcLikeNodes:Expr = {nnkProcDef, nnkMethodDef, nnkDo} #nnkLambda ?
template ExpectKind*(n: PNimrodNode; k: set[TNimrodNodeKind]) =
  assert n.kind in k

proc newProc*(name = newEmptyNode(); params: varargs[PNimrodNode] = [];  
    body: PNimrodNode = newStmtList(), procType = nnkProcDef): PNimrodNode {.compileTime.} =
  ## shortcut for creating a new proc
  assert procType in ProcLikeNodes
  result = newNimNode(procType).und(
    name,
    newEmptyNode(),
    newEmptyNode(),
    newNimNode(nnkFormalParams).und(params), ##params
    newEmptyNode(),  ## pragmas
    newEmptyNode(),
    body)
 
proc name*(someProc: PNimrodNode): PNimrodNode {.compileTime.} =
  assert someProc.kind in ProcLikeNodes
  result = someProc[0]
proc `name=`*(someProc: PNimrodNode; val: PNimrodNode) {.compileTime.} =
  assert someProc.kind in ProcLikeNodes
  someProc[0] = val

proc params*(someProc: PNimrodNode): PNimrodNode {.compileTime.} =
  assert someProc.kind in ProcLikeNodes
  result = someProc[3]

proc pragma*(someProc: PNimrodNode): PNimrodNode {.compileTime.} =
  ## Get the pragma of a proc type
  ## These will be expanded
  assert someProc.kind in ProcLikeNodes
  result = someProc[4]
proc `pragma=`*(someProc: PNimrodNode; val: PNimrodNode){.compileTime.}=
  ## Set the pragma of a proc type
  assert someProc.kind in procLikeNodes
  assert val.kind in {nnkEmpty, nnkPragma}
  someProc[4] = val

proc body*(someProc: PNimrodNode): PNimrodNode {.compileTime.} =
  assert someProc.kind in ProcLikeNodes
  result = someProc[6]
proc `body=`*(someProc: PNimrodNode, val: PNimrodNode) {.compileTime.} =
  assert someProc.kind in ProcLikeNodes
  someProc[6] = val

proc `$`*(node: PNimrodNode): string {.compileTime.} =
  ## Get the string of an identifier node
  assert node.kind == nnkIdent
  result = $node.ident
proc high*(node: PNimrodNode): int {.compileTime.} = len(node) - 1
  ## Return the highest index available for a node
proc last*(node: PNimrodNode): PNimrodNode {.compileTime.} = node[node.high]
  ## Return the last item in nodes children. Same as `node[node.high()]` 

proc `!`*(a: TNimrodIdent): PNimrodNode {.compileTime, inline.} = newIdentNode(a)
  ## Create a new ident node from an identifier
proc `!!`*(a: string): PNimrodNode {.compileTime, inline.} = newIdentNode(a)
  ## Create a new ident node from a string
  ## The same as !(!(string))

proc newIdentDefs*(name, kind: PNimrodNode; default = newEmptyNode()): PNimrodNode{.
  compileTime.} = newNimNode(nnkIdentDefs).und(name, kind, default)

iterator children*(n: PNimrodNode): PNimrodNode {.inline.}=
  for i in 0 .. high(n):
    yield n[i]
    
template first*(n: PNimrodNode; cond: expr): PNimrodNode {.immediate, dirty.} =
  ## Find the first node matching condition (or nil)
  ## first(n, it.kind == nnkPostfix and it.basename.ident == !"foo")
  block:
    var result: PNimrodNode
    when false:
      for i in 0.. <len(n):
        let it = n[i]
        if cond:
          result = it
          break
    else:
      for it in n.children:
        if cond: 
          result = it
          break
    result

proc insert*(a: PNimrodNode; b: PNimrodNode; pos: int) {.compileTime.} =
  ## Insert node B into A at pos
  if high(a) < pos:
    ## add some empty nodes first
    for i in high(a)..pos-2:
      a.add newEmptyNode()
    a.add b
  else:
    ## push the last item onto the list again
    ## and shift each item down to pos up one
    a.add(a[a.high])
    for i in countdown(high(a) - 2, pos):
      a[i + 1] = a[i]
    a[pos] = b


proc dot*(a, b: PNimrodNode): PNimrodNode {.compileTime, inline.} = 
  ## Create new dot expression
  ## a.dot(b) ->  `a.b`
  return newNimNode(nnkDotExpr).und(a, b)
proc `<-`*(a, b: PNimrodNode): PNimrodNode {.compiletime, inline.} =
  ## New assignment node
  ## a <- b  is equivalent to `a = b`  
  ## I might change this back to `:=`  
  return newNimNode(nnkAsgn).und(a, b)

proc basename*(a: PNimrodNode): PNimrodNode {.compiletime.} =
  ## Pull an identifier from prefix/postfix expressions
  case a.kind
  of nnkIdent: return a
  of nnkPostfix, nnkPrefix: return a[1]
  else: 
    quit "Do not know how to get basename of ("& treerepr(a) &")\n"& repr(a)
proc `basename=`*(a: PNimrodNode; val: TNimrodIdent) {.compileTime.}=
  case a.kind
  of nnkIdent: a.ident = val
  of nnkPostfix, nnkPrefix: a[1] = !val
  else:
    quit "Do not know how to get basename of ("& treerepr(a)& ")\n"& repr(a)

proc postfix*(node: PNimrodNode; op: string): PNimrodNode {.
  compileTime.} = newNimNode(nnkPostfix).und(!!op, node)
proc prefix*(node: PNimrodNode; op: string): PNimrodNode {.
  compileTime.} = newNimNode(nnkPrefix).und(!!op, node)
proc infix*(a: PNimrodNode; op: string; b: PNimrodNode): PNimrodNode {.
  compileTime.} = newNimNode(nnkInfix).und(!!op, a, b)

proc unpackPostfix*(node: PNimrodNode): tuple[node: PNimrodNode; op: string] {.
  compileTime.} =
  node.expectKind nnkPostfix
  result = (node[0], $node[1])
proc unpackPrefix*(node: PNimrodNode): tuple[node: PNimrodNode; op: string] {.
  compileTime.} =
  node.expectKind nnkPrefix
  result = (node[0], $node[1])
proc unpackInfix*(node: PNimrodNode): tuple[left: PNimrodNode; op: string; right: PNimrodNode] {.
  compileTime.} =
  assert node.kind == nnkInfix
  result = (node[0], $node[1], node[2])

when isMainModule:
  macro basenameTest(arg: expr): stmt {.immediate.} =
    echo repr(basename(arg))
    nil
  macro basenameTest2(): stmt =
    echo treerepr(callsite())
    #echo "name: ", basename(p[0])
    result = newStmtList()
    echo(treerepr(result))
  
  #should print "Foo":
  basenameTest(<Foo)
  
  ##should print "name: test":
  proc test*() {.basenameTest2.} = 
    nil
  
  macro insertTest(): stmt = 
    result = newStmtList()
    insert(result, newintlitnode(2), 2)
    assert len(result) == 3 and result[2].intval == 2
    
    insert(result, newintlitnode(0), 0)
    assert len(result) == 4 and result[0].intval == 0 and result[3].intval == 2
    
    echo "Should be stmtlist(int(0), empty, empty, int(2)): "
    echo(lisprepr(result))
    
    result = newNilLit()
    
  
  insertTest()
