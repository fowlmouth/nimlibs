import g_lex

type
  TParser*[A] = object
    tkIndex*: int 
    tokens*: seq[TToken]
    lex*: T_Lexer ##lex is exposed so that you can put your own hooks into it
    when A isnot void:
      root_func: TParserRootFunc[A] ##the entry point of the parser
  TParserRootFunc*[A] = proc(P: var T_Parser[A]): A
  
  E_ParsingError* = object of E_Base


proc setRootFunc*[A] (P: var T_parser[A]; root_func: TParserRootFunc[A]) =
  P.root_func = root_func
proc newParser*[A] (root_func : TParserRootFunc[A] = nil) : TParser[A] =
  result.lex = newLex()
  when A isnot void:
    result.setRootFunc root_func

template ParsingError_lt*(msg: string): stmt =
  raise newException(E_ParsingError, msg)
template ParsingError*(msg: string): stmt = parsingError_lt(msg&" at "& $P.currentTok().pos)

proc currentTok*[A] (P: var T_Parser[A]): var TToken = P.tokens[P.tkIndex]

proc expectTok*[A]  (P: var T_Parser[A]; kinds: varargs[TTokenType]) {.inline.}=
  if P.currentTok.kind notin kinds:
    parsingError "Expected one of "&repr(kinds)&", got "&($P.currentTok())

proc consumeTok*[A] (P: var T_Parser[A]; kinds: varargs[TTokenType]): var TToken {.
  discardable.} =
  
  if kinds.len > 0:
    P.expectTok(kinds)
  
  result = P.currentTok()
  inc P.tkIndex

  
proc parse*[A] (P: var TParser[A]; input: string): A =
  ## Parse some input. If root_func was not setup this will just fill
  ## up the token buffer and return nil
  P.lex.setInput input
  P.tkIndex = 0
  P.tokens = P.lex.readTokens()
  when A isnot void:
    if not(P.root_func.isNil):
      result = P.root_func(P)

proc present*[A] (P: var T_Parser[A]; kinds: varargs[TTokenType]): bool{.
  inline.} = P.currentTok.kind in kinds

proc isStrTok*[A] (P: var T_Parser[A]; kinds: varargs[TTokenType]; strings: varargs[string]): bool = 
  result = P.currentTok.kind in StringToks
  if result and kinds.len > 0:
    result = present(P, kinds)
  if result and strings.len > 0:
    result = P.currentTok.sval in strings
proc isIdent*[A] (P: var T_Parser[A]; strs: varargs[string]): bool {.
  inline.} = isStrTok(P, tkIdent, strs)
proc isOperator*[A] (P: var T_Parser[A]; ops: varargs[string]): bool {.
  inline.} = isStrTok(P, tkOperator, ops)

proc consumeStrTok*[A] (P: var T_Parser[A]; kinds: varargs[TTokenType]; 
  strings: varargs[string]): var TToken{.discardable.} =
  if isStrTok(P, kinds, strings): result = P.consumeTok()
  else: parsingError "Expected one of "& repr(kinds) &", "&repr(strings)&", got: "&($P.currentTok())


proc skipNewlines*[A] (P: var T_Parser[A]) =
  while P.currentTok.kind == tkNewline: P.consumeTok()

