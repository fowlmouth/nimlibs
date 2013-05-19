import macros, fowltek/macro_dsl

## Automatically apply {.importc.} to the following procs (in the future other 
## stuff too, mebbe)
## importCizzle "box2d":
##   proc Foo()
## will be changed to 
## proc Foo(){.importc: "box2dFoo".}

macro importCizzle*(prefixx: string; body: stmt): stmt {.immediate.}= 
  result = newStmtList()
  let prefix = prefixx.strval
  
  for i in 0..(body.len - 1):
    let s = body[i]
    
    case s.kind
    of nnkProcDef:
      if s.pragma.kind == nnkEmpty:
        s.pragma = newNimNode(nnkPragma)
      
      
      s[4].add(newNimNode(nnkExprColonExpr).add(
        !!"importc", newStrLitNode(prefix & $ident(basename(name(s))))))
      
      result.add s
      
    else:
      result.add s
  
  when defined(Debug): result.repr.echo  #lul

