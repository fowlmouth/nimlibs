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

proc newProc*(name: PNimrodNode; params: varargs[PNimrodNode] = [];  
    body: PNimrodNode = newStmtList()): PNimrodNode {.compileTime.} =
  ## shortcut for creating a new proc
  result = newNimNode(nnkProcDef).und(
    name,
    newEmptyNode(),
    newEmptyNode(),
    newNimNode(nnkFormalParams).und(params),
    newEmptyNode(),
    newEmptyNode(),
    body)


proc `$`*(a: PNimrodNode): string {.compileTime.} =
  ## Get the string of an identifier node
  assert a.kind == nnkIdent
  result = $a.ident
proc high*(a: PNimrodNode): int {.compileTime.} = return len(a)-1
  ## Return the highest index available for a node

proc `!`*(a: TNimrodIdent): PNimrodNode {.compileTime, inline.} = newIdentNode(a)
  ## Create a new ident node from an identifier
proc `!!`*(a: string): PNimrodNode {.compileTime, inline.} = newIdentNode(a)
  ## Create a new ident node from a string
  ## The same as !(!(string))


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
  return newNimNode(nnkAsgn).und(a, b)

proc basename*(a: PNimrodNode): PNimrodNode {.compiletime.} =
  ## Pull an identifier from prefix/postfix expressions
  case a.kind
  of nnkIdent: return a
  of nnkPostfix, nnkPrefix: return a[1]
  else: 
    quit "Do not know how to get basename of "& treerepr(a) &"\n"& repr(a)


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
