import g_lex

type
  TNodeKind* = enum
    nEmpty, nEmptyUser1,nEmptyUser2, 
    nLiteral,
    nInt, nIntUser1,nIntUser2,nIntUser3,nIntUser4,nIntUser5,
    nFloat, nFltUser1,nFltUser2,nFltUser3,nFltUser4,nFltUser5,
    nIdent, nString,  nStrUser1,nStrUser2,nStrUser3,nStrUser4,nStrUser5,
    
    nBinExpr, nPrefixExpr, nPostfixExpr,
    nPostfixParens, nPostfixBrackets, nCall,
    nStmts, nIfStmt, nWhileStmt, nTypeDecl, nTypedName, nAssignment,
    nChildUser1, nChildUser2, nChildUser3, nChildUser4, nChildUser5
const 
  EmptyNodeKinds* = {nEmpty .. nEmptyUser2 }
  ChildNodeKinds* = {nBinExpr .. nChildUser5}
  StringNodeKinds* = {nIdent  .. nStrUser5}
  IntNodeKinds* = {nInt .. nIntUser5}
  FloatNodeKinds* = {nFloat .. nFltUser5}
type
  PNode* = ref TNode
  TNode* = object
    case kind*: TNodeKind
    of EmptyNodeKinds: nil
    of nLiteral: tok*: TToken
    of StringNodeKinds:
      sval*: string
    of IntNodeKinds:
      ival*: int
    of FloatNodeKinds:
      fval*: float
    of ChildNodeKinds:
      children*: seq[PNode]
    else: nil


proc newNode*(ty: TNodeKind; kids: varargs[PNode]): PNode =
  new result
  result.kind = ty
  if result.kind in ChildNodeKinds:
    result.children = @kids
  elif kids.len > 0:
    echo "Warning: Passed children were discarded for ", ty, " node"
proc add*(n: PNode; children: varargs[PNode]) =
  assert n.kind in ChildNodeKinds
  for c in children: n.children.add(c)
 
proc ident*(some: string): PNode = 
  result = newNode(nIdent)
  result.sval = some
proc intNode*(i: int; kind = nInt): PNode = 
  result = newNode(kind)
  result.ival = i
proc emptyNode*: PNode = newNode(nEmpty)


proc ident*(some: var TToken): PNode =
  assert some.kind in StringToks
  result = ident(some.sval)

proc `$`* (some: PNode): string =
  result = "("
  result.add($some.kind)
  
  case some.kind
  of nLiteral: 
    result.add ' '
    result.add($some.tok)
  of StringNodeKinds: 
    result.add " '"
    result.add some.sval
    result.add '\''
  of IntNodeKinds:
    result.add ' '
    result.add($some.ival)
  of ChildNodeKinds:
    for c in some.children: 
      result.add ' '
      result.add($c)
  else:
    result.add "??"
  result.add ')'

