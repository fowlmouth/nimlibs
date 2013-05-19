import macros, strutils

proc newEmptyNode*(): PNimrodNode {.compileTime, noSideEffect.} =
  ## Create a new empty node 
  result = newNimNode(nnkEmpty)

proc newStmtList*(stmts: varargs[PNimrodNode]): PNimrodNode {.compileTime.}=
  ## Create a new statement list
  result = newNimNode(nnkStmtList).add(stmts)

proc newBlockStmt*(label: PNimrodNode; body: PNimrodNode): PNimrodNode {.compileTime.} =
  ## Create a new block statement with label
  return newNimNode(nnkBlockStmt).add(label, body)
proc newBlockStmt*(body: PNimrodNode): PNimrodNode {.compiletime.} =
  ## Create a new block: stmt
  return newNimNode(nnkBlockStmt).add(newEmptyNode(), body)

proc newLetStmt*(name, value: PNimrodNode): PNimrodNode{.compiletime.} =
  ## Create a new let stmt 
  return newNimNode(nnkLetSection).add(
    newNimNode(nnkIdentDefs).add(name, newNimNode(nnkEmpty), value))

proc newAssignment*(lhs, rhs: PNimrodNode): PNimrodNode {.compileTime, inline.} =
  return newNimNode(nnkAsgn).add(lhs, rhs)

proc newDotExpr* (a, b: PNimrodNode): PNimrodNode {.compileTime, inline.} = 
  ## Create new dot expression
  ## a.dot(b) ->  `a.b`
  return newNimNode(nnkDotExpr).add(a, b)


proc newIdentDefs*(name, kind: PNimrodNode; default = newEmptyNode()): PNimrodNode{.
  compileTime.} = newNimNode(nnkIdentDefs).add(name, kind, default)

proc newNilLit*(): PNimrodNode {.compileTime.} =
  ## New nil literal shortcut
  result = newNimNode(nnkNilLit)


proc high*(node: PNimrodNode): int {.compileTime.} = len(node) - 1
  ## Return the highest index available for a node
proc last*(node: PNimrodNode): PNimrodNode {.compileTime.} = node[node.high]
  ## Return the last item in nodes children. Same as `node[node.high()]` 


template ProcLikeNodes*:Expr = {nnkProcDef, nnkMethodDef, nnkDo, nnkLambda}
const NoSonsNodes = {nnkNone, nnkEmpty, nnkNilLit,
  nnkCharLit .. nnkInt64Lit, nnkFLoatLit .. nnkFloat64Lit, 
  nnkStrLit .. nnkTripleStrLit, nnkIdent, nnkSym }

proc ExpectKind*(n: PNimrodNode; k: set[TNimrodNodeKind]) {.compileTime.} =
  assert n.kind in k, "Expected one of $1, got $2".format(k, n.kind)

proc newProc*(name = newEmptyNode(); params: openarray[PNimrodNode] = [];  
    body: PNimrodNode = newStmtList(), procType = nnkProcDef): PNimrodNode {.compileTime.} =
  ## shortcut for creating a new proc
  assert procType in ProcLikeNodes
  result = newNimNode(procType).add(
    name,
    newEmptyNode(),
    newEmptyNode(),
    newNimNode(nnkFormalParams).add(params), ##params
    newEmptyNode(),  ## pragmas
    newEmptyNode(),
    body)

proc copyChildrenTo*(src, dest: PNimrodNode) {.compileTime.}=
  ## Copy all children from `src` to `dest`
  for i in 0 .. < src.len:
    dest.add src[i].copyNimTree

proc name*(someProc: PNimrodNode): PNimrodNode {.compileTime.} =
  someProc.expectKind ProcLikeNodes
  result = someProc[0]
proc `name=`*(someProc: PNimrodNode; val: PNimrodNode) {.compileTime.} =
  someProc.expectKind ProcLikeNodes
  someProc[0] = val

proc params*(someProc: PNimrodNode): PNimrodNode {.compileTime.} =
  someProc.expectKind procLikeNodes
  result = someProc[3]
proc `params=`* (someProc: PNimrodNode; params: PNimrodNode) {.compileTime.}=
  someProc.expectKind procLikeNodes
  assert params.kind == nnkFormalParams
  someProc[3] = params

proc pragma*(someProc: PNimrodNode): PNimrodNode {.compileTime.} =
  ## Get the pragma of a proc type
  ## These will be expanded
  someProc.expectKind procLikeNodes
  result = someProc[4]
proc `pragma=`*(someProc: PNimrodNode; val: PNimrodNode){.compileTime.}=
  ## Set the pragma of a proc type
  someProc.expectKind procLikeNodes
  assert val.kind in {nnkEmpty, nnkPragma}
  someProc[4] = val


template badnodekind(k; f): stmt{.immediate.} =
  assert false, "Invalid node kind $# for macros.`$2`" % [$k, f]

proc body*(someProc: PNimrodNode): PNimrodNode {.compileTime.} =
  case someProc.kind:
  of procLikeNodes:
    return someProc[6]
  of nnkBlockStmt, nnkWhileStmt:
    return someproc[1]
  of nnkForStmt:
    return someProc.last
  else: 
    badNodeKind someproc.kind, "body"

proc `body=`*(someProc: PNimrodNode, val: PNimrodNode) {.compileTime.} =
  case someProc.kind 
  of ProcLikeNodes:
    someProc[6] = val
  of nnkBlockStmt, nnkWhileStmt:
    someProc[1] = val
  of nnkForStmt:
    someProc[high(someProc)] = val
  else:
    badNodeKind someProc.kind, "body=" 
  

proc `$`*(node: PNimrodNode): string {.compileTime.} =
  ## Get the string of an identifier node
  case node.kind
  of nnkIdent:
    result = $node.ident
  of nnkStrLit:
    result = node.strval
  else: 
    badNodeKind node.kind, "$"

proc `!`*(a: TNimrodIdent): PNimrodNode {.compileTime, inline.} = newIdentNode(a)
  ## Create a new ident node from an identifier
proc `!!`*(a: string): PNimrodNode {.compileTime, inline.} = newIdentNode(a)
  ## Create a new ident node from a string
  ## The same as !(!(string))


iterator children*(n: PNimrodNode): PNimrodNode {.inline.}=
  for i in 0 .. high(n):
    yield n[i]

template findChild*(n: PNimrodNode; cond: expr): PNimrodNode {.immediate, dirty.} =
  ## Find the first child node matching condition (or nil)
  ## var res = findChild(n, it.kind == nnkPostfix and it.basename.ident == !"foo")
  
  block:
    var result: PNimrodNode
    for it in n.children:
      if cond: 
        result = it
        break
    result

proc insert*(a: PNimrodNOde; pos: int; b: PNimrodNode) {.compileTime.} =
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
proc insert*(a: PNimrodNode; b: PNimrodNode; pos: int) {.compileTime, deprecated.} =
  insert(a, pos, b)

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
  compileTime.} = newNimNode(nnkPostfix).add(!!op, node)
proc prefix*(node: PNimrodNode; op: string): PNimrodNode {.
  compileTime.} = newNimNode(nnkPrefix).add(!!op, node)
proc infix*(a: PNimrodNode; op: string; b: PNimrodNode): PNimrodNode {.
  compileTime.} = newNimNode(nnkInfix).add(!!op, a, b)

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

proc copy*(node: PNimrodNode): PNimrodNode {.compileTime.} =
  ## An alias for copyNimTree()
  return node.copyNimTree()

proc eqIdent* (a, b: string): bool = cmpIgnoreStyle(a, b) == 0
  ## Check if two idents are identical

proc hasArgOfName* (params: PNimrodNode; name: string): bool {.compiletime.}=
  ## Search nnkFormalParams for an argument 
  assert params.kind == nnkFormalParams
  for i in 1 .. <params.len: 
    template node: expr = params[i]
    if name.eqIdent( $ node[0]):
      return true

proc addIdentIfAbsent* (dest: PNimrodNode, ident: string) {.compiletime.} =
  ## Add ident to dest if it is not present. This is intended for use with pragmas
  for node in dest.children:
    case node.kind
    of nnkIdent:
      if ident.eqIdent($node): return
    of nnkExprColonExpr:
      if ident.eqIdent($ node[0]): return
    else: nil
  dest.add(!!ident)






when false:
  proc isEmpty*(someNode: PNimrodNode): bool {.
    compileTime, inline.} = someNode.kind == nnkEmpty
    ## Check if the node is empty. Try to keep up. :^)
    
  proc und*(a: PNimrodNode, b: varargs[PNimrodNode]): PNimrodNode {.
                                                    compileTime, discardable.} =
    ## Add nodes B to A and return A
    ## Allow nesting o
    a.add b
    return a

when false:
  proc `<-`*(a, b: PNimrodNode): PNimrodNode {.compiletime, inline.} =
    ## New assignment node
    ## a <- b  is equivalent to `a = b`  
    ## I might change this back to `:=`  
    return newNimNode(nnkAsgn).add(a, b)


when isMainModule:
  macro basenameTest(arg: expr): stmt {.immediate.} =
    echo repr(basename(arg))
    nil
  macro basenameTest2(p): stmt =
    echo treerepr(callsite())
    echo "name: ", basename(p[6].name)
    result = newStmtList()
    echo(treerepr(result))
  
  #should print "Foo":
  basenameTest(<Foo)
  
  ##should print "name: test":
  proc test() {.basenameTest2.} = 
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
  
  macro test22: stmt =
    result = newBlockStmt(!!"foo", newStmtList(
      newLetStmt(!!"x", newIntLitNode(42)),
      "break foo".parseStmt
    ))
    #result.repr.echo
  
  test22
  
  macro dumpbody_of_first(node): stmt =
    node[0].body.treerepr.echo
  
  dumpbody_of_first:
    for i,y,z in 0..1:
      nil