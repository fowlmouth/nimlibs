from parseutils import parseWhile, skipWhile, skipWhitespace
import os, strutils

## Implements a generic tokenizer 
type
  TTokenType* = enum
    TkNoToken,TkParenOpen, TkParenClose,
    TkBracketOpen, TkBracketClose, TkBraceOpen, TkBraceClose, 
    TkNewline, TkComma, TkSemicolon,  
    TkRightArrow, TkLeftArrow, TkPeriod, TkEquals, TkColon,
    TkInt, TkFloat, 
    TkIdent, TkOperator, TkSqString, TkDqString, 
    TkUser1,TkUser2,TkUser3,TkUser4,TkUser5,TkUser6,TkUser7,TkUser8,TkUser9,
    tkUser10,tkUser11,tkUser12,tkUser13,tkUser14,tkUser15,tkUser16,tkUser17,
    tkUser18,tkUser19,tkUser20,
    TkEOF
  
  TLexPosition* = tuple[index: int, line, col: int]

const
  StringToks* = {TkIdent, TkOperator, TkSqString, TkDqString, tkUser1 .. tkUser20}
  identChars* = {'A'..'Z','a'..'z','_','0'..'9'}
type

  TLexer* = object
    pos*: TLexPosition
    input*: string
    pre_hooks*, post_hooks*: seq[TLexHook]
    trackIndentation: bool
    indentStack: seq[int]
  
  TLexHook* = proc(L: var TLexer; tok: var TToken): bool{.nimcall.}
    ## Hooks before and after a token is read. You can 
    ## ex:
    ##    const tkKeyword = tkUser1
    ##    const keywords = {"if", "elseif", "else", "while"}
    ##    myLex.addPostHook proc(L: var TLexer; tok: var TToken): bool =
    ##      if tok.kind == tkIdent and tok.sval in keywords:
    ##        result.kind = tkKeyword
    
  TToken* = object
    pos*: TLexPosition
    case kind*: TTokenType
    of StringToks:
      sval*: string
    of TkInt:
      ival*: int
    of TkFLoat:
      fval*: float
    else:
      nil

proc `$`*(tok: TToken): string =
  result = "("
  result.add repr(tok.kind)
  case tok.kind
  of StringToks:
    result.add ' '
    result.add tok.sval
  of TkInt:
    result.add ' '
    result.add($tok.ival)
  of TkFloat:
    result.add ' '
    result.add(FormatFloat(tok.fval, ffDecimal))
  else: nil
  result.add ' '
  result.add($tok.pos)
  result.add ')'

proc setInput*(L: var T_Lexer; input: string) =
  L.input = input
  reset L.pos
  L.pos.line = 1
proc newLex*(input = ""): TLexer =
  result.Pre_hooks = @[]
  result.post_hooks = @[]
  result.setInput input
proc add_PreHook*(L: var TLexer; hooks: varargs[TLexHook]) =
  for h in hooks: L.pre_hooks.add(h)
proc add_postHook*(L: var TLexer; hooks: varargs[TLexHook]) =
  for h in hooks: L.post_hooks.add h

proc currentChar*(L: var TLexer): char = L.input[L.pos.index]
proc nextChar*(L: var TLexer, n: int = 1): char = L.input[L.pos.index + n]
proc nextChars*(L: var TLexer, n: int): string = L.input[L.pos.index .. L.pos.index+n-1]
proc hasCharacters*(L: var TLexer; n: int): bool =
  result = (L.pos.index + n < L.input.high)

proc `+=`(some: var TLexPosition, by: int) =
  inc some.index, by
  inc some.col, by

proc inc*(P: var TLexPosition; by = 1) =  P += by
proc inc*(L: var TLexer, by: int = 1) =  L.pos += by

proc zomg*[A](some: A): A =
  echo($some)
  return some

proc readIdent(L: var TLexer): TToken =
  let start = L.pos
  var
    ident: string
    next = parseWhile(L.input, ident, identChars, L.pos.index)
  L.pos += next
  result.kind = TkIdent
  result.sval = ident
  
  result.pos = start

proc readString(L: var TLexer): TToken =
  var capt = ""
  let endStr = L.currentChar()
  if L.currentChar() == '"':
    result.kind = TkDqString
  elif L.currentChar() == '\'':
    result.kind = TkSqString
  L.inc()
  
  while true:
    let c = L.currentChar()
    case c
    of '\\':
      case L.nextChar()
      of 'n':
        capt.add '\L'
      else:
        if L.nextChar() == endStr:
          capt.add EndStr
        
      L.inc 1
    else:
      if c == endStr:
        L.inc 1
        break
      capt.add c
    L.inc 1
  result.sval = capt 

proc readNumber(L: var TLexer): TToken =
  const digits = {'0'..'9'}
  let start = L.pos
  var 
    pos = start
    capt = ""
    hasDecimal = false
  while true:
    if L.input[pos.index] in digits:
      capt.add(L.input[pos.index])
      pos += 1
    elif L.input[pos.index] == '.':
      if not hasDecimal and L.input[pos.index+1] in digits:
        hasDecimal = true
        capt.add(L.input[pos.index])
        pos += 1
      else: 
        break
    else:
      break
  L.pos = pos
  
  if hasDecimal:
    result.kind = TkFloat
    result.fval = parseFloat(capt)
  else:
    result.kind = TkInt
    result.ival = parseInt(capt)
  result.pos = start

type E_LexError = object of E_Base
template LexAbort(msg: string): stmt =
  raise newException(E_LexError, msg)



const operatorChars = {'~','!','@','#','$','%','^','&','*','-','+','=',
  '/','.','>','<',':','|'}

proc readOperator(L: var TLexer): TToken =
  var str: string
  var next = parseWhile(L.input, str, operatorChars, L.pos.index)
  case str
  of "->": 
    result.kind = tkRightArrow
  of "<-", ":=":
    result.kind = tkLeftArrow
  of "=": 
    result.kind = tkEquals
  of ".":
    result.kind = tkPeriod
  of ":": 
    result.kind = tkColon
  else:
    result.kind = TkOperator
    result.sval = str
  result.pos = L.pos
  inc L, next



proc readToken*(L: var TLexer): TToken =
  const
    identStartChars = {'A'..'Z', 'a'..'z', '_'}
    whitespaceNonterm = {' ', '\t'}
    whitespaceTerminal = {'\L'}
  
  L.inc skipWhile(L.input, whitespaceNonterm, L.pos.index) 
  
  template eofCheck : stmt {.immediate.} = 
    if L.pos.index > L.input.high:
      result.kind = tkEOF
      result.pos = L.pos
      return
  
  template saveTok(tok: TTokenType, size = 1): stmt {.immediate, dirty.} =
    result.pos = L.pos
    result.kind = tok
    inc L.pos, size
  
  eofCheck
  for hook in L.pre_hooks:
    if hook(L, result): return
  eofCheck
  
  case L.currentChar()
  of identStartChars: result = L.readIdent()
  of '0'..'9': result = L.readNumber()
  of '\'', '"': result = L.readString()
  of '\\':
    L.inc
    if L.currentChar() == '\L':
      ## \ at the end of the line to discard this newline
      inc L
      inc L.pos.line
      L.pos.col = 0
    else:
      LexAbort("Unknown token \"\\"&(L.currentChar()))
  of '{': saveTok TkBraceOpen
  of '}': saveTok TkBraceClose
  of '[': saveTok TkBracketOpen
  of ']': saveTok TkBracketClose
  of '(': saveTok tkParenOpen
  of ')': saveTok TkParenClose
  of ',': saveTok TkComma
  of ';': saveTok TkSemicolon
  of operatorChars: 
    result = L.readOperator()
  of '\L':
    result.kind = TkNewline
    inc L.pos.line, 1
    inc L
    L.pos.col = 0
    #L.pos += parseWhile(L.input, s, whitespaceTerminal, L.pos)
  else:
    echo "Unknown input! \"", L.input[L.pos.index .. L.pos.index+10], "\""
    result.kind = tkEOF
  
  for h in L.post_hooks:
    if h(L, result): return

proc readTokens*(L: var TLexer): seq[TToken] =
  result = @[]
  var t = L.readToken()
  result.add t
  while t.kind != tkEOF:
    if t.kind == tkNoToken:
      discard result.pop()
    t = L.readToken()
    result.add t
  
  when false:
    result.add L.readToken()
    while result[result.high].kind != tkEOF:
      let t = L.readToken()
      if t.kind != tkNoToken:
        result.add L.readToken()

proc isIdent*(t: var TToken; idents: varargs[string]): bool =
  result = t.kind == tkIdent
  if result and idents.len > 0: result = t.sval in idents
proc isOperator*(t: var TToken; ops: varargs[string]): bool =
  result = t.kind == tkOperator
  if result and ops.len > 0: result = t.sval in ops



when isMainModule:
  var l = newLex(if paramCount() == 0: "foo bar, bum" else: paramStr(1))
  var t = l.readToken()
  while t.kind != tkEOF:
    echo($t)
    t = l.readToken()

















