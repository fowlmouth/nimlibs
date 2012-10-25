import macros, macro_dsl

## Automatically apply {.importc.} to the following procs (in the future other 
## stuff too, mebbe)
## importCizzle "box2d":
##   proc Foo()
## will be changed to 
## proc Foo(){.importc: "box2dFoo".}

macro importCizzle*(prefixx: string; body: stmt): stmt = 
  result = newStmtList()
  let prefix = prefixx.strval
  
  for i in 0..(body.len - 1):
    let s = body[i]
    
    case s.kind
    of nnkProcDef:
      if s.pragma.isEmpty:
        s.pragma = newNimNode(nnkPragma)
      
      
      s[4].add(newNimNode(nnkExprColonExpr).und(
        !!"importc", newStrLitNode(prefix & $ident(basename(procname(s))))))
      
      result.add s
      
    else:
      result.add s
  
  when defined(Debug): result.repr.echo  #lul

