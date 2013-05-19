import tables, macros, strutils
import fowltek/macro_dsl
discard """
Copyright (c) 2012 fowlmouth
Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
THE SOFTWARE.
"""

template high(a: PNimrodNode): expr = len(a)-1

macro classimpl*(name, typp: expr; body: stmt): stmt {.immediate.} =
  ##this time I'll iterate over the body and build the object out of
  ##vars and procs defined
  result = newNimNode(nnkStmtList)
  
  var
    thisRecd = newNimNode(nnkRecList) 
    typ, parent: PNimrodNode
  if typp.kind == nnkIdent:
    typ = typp
  elif typp.kind == nnkInfix:
    if typp[0].ident == !"<":
      ## typ < parent
      typ = typp[1]
      parent = typp[2]
    elif typp[0].ident == !">":
      ## parent > typ 
      typ = typp[2]
      parent = typp[1]
    elif typp[0].ident == !"*" and typp[2][0].ident == !"<": ##This is exported
      ## typ* < parent  (typ * (< parent))
      ## I decided to just always export, but ill leave this here anyways
      typ = typp[1]
      parent = typp[2][1]
    else:
      quit "Invalid expression for type: "& $typp
    
  if typ.isNil:
    echo("typ is nil! ", treerepr(typp))
    quit(1)
  
  result.add newNimNode(nnkTypeSection).add(
    newNimNode(nnkTypeDef).add(
      newNimNode(nnkPostfix).add(!!"*", typ),
      newEmptyNode(),
      newNimNode(nnkRefTy).add(
        newNimNode(nnkObjectTy).add(
          newEmptyNode(),
          if parent.isNil: newEmptyNode()
          else: newNimNode(nnkOfInherit).add(parent),
          thisRecd))))
  
  var 
    constructorName = !("new"& $name.ident)
    constructorImplemented = false

  for i in 0 .. high(body):
    var statement = body[i]
    
    case statement.kind
    of nnkVarSection:
      for n in 0..high(statement):
        thisRecd.add statement[n]
    of nnkProcDef, nnkMethodDef:
      let procname = statement.name.baseName
      var 
        selfFoadd = false
        params = statement[3]
      
      if procname.kind == nnkIdent and procname.ident == constructorName:
        constructorImplemented = true
        selfFoadd = true
      
      if not selfFoadd and params.len > 1:
        ##try to find self
        for i in 1..params.len - 1:
          if params[i][0].ident == !"self":
            selfFoadd = true
            break
      
      if statement[4].kind == nnkPragma:
        echo "PRAGAMAMS!!"
        var pragmas = statement[4]
        var i = 0
        while i <= len(pragmas) - 1:
          echo(i)
          if pragmas[i].kind == nnkIdent:
            if pragmas[i].ident == !"constructor":
              constructorImplemented = true
              ## set self foadd to true so it wont be added to args
              selfFoadd = true
              pragmas.del i
            elif pragmas[i].ident == !"noself":
              selfFOadd = true
              pragmas.del i
            else:
              inc i
          else:
            inc i
      
      if not selfFoadd:  ##including the return type
        ##inject self: type into the params
        insert(params,
               newNimNode(nnkIdentDefs).add(!!"self", typ, newEmptyNode()), 
               1)
      result.add statement
      
    of nnkCommand:
      if statement[0].ident == !"subclass":
        #change it to classimpl(name, type < this): body
        statement[0].ident= !"classimpl"
        statement[2] = newNimNode(nnkInfix).add(!!"<", statement[2], typ)
        
      result.add statement
      
    of nnkCommentStmt:
      result.add statement
    else:
      echo "unknown call: "& treerepr(statement)
  
  var
    constructor, cbody: PNimrodNode
  if not constructorImplemented:
    constructor = newProc(
      newNimNode(nnkPostfix).add(!!"*", !constructorName),
      params = [typ])
    cbody = newNimNode(nnkStmtList).add(newCall("new", !!"result"))
  
  for i in 0 .. high(thisRecd):
    ##iterate over each field
    if not constructorImplemented:
      ##add each field to the constructor params
      ##in the future, handle branching types here
      var 
        arg = copyNimTree(thisRecd[i])
        name = if thisRecd[i][0].kind == nnkPostfix: thisRecd[i][0][1]
               else: thisRecd[i][0]
      arg[0] = name
      constructor[3].add arg
      cbody.add((!!"result").newDotExpr(name).newAssignment(name))
    ##clear any default values
    thisRecd[i][2] = newEmptyNode()
    
  if not constructorImplemented:
    constructor[6] = cbody
    insert(result, constructor, 1)
  
  when defined(debug):
    echo repr(result)
  


when isMainModule:
  classimpl Animal, PAnimal < TObject:
    var
      howAnnoyingItIs*: int ##exported
      howmuchNoiseItMakes: int ##local
    
    proc newAnimal*(): PAnimal =
      quit "Do not instance an animal directly"
      
    method annoy*(): string =
      return "generic animal says 'sup d00d'"
      
    method annoyingScore*(): int =
      return self.how_annoying_it_is * self.how_much_noise_it_makes
    
    subclass Cat, PCat:
      method annoy*(): string = return "meow"
    subclass Dog, PDog:
      method annoy*(): string = return "woof"
  classimpl Squirrel, PAnimal > PSquirrel:
    ## make sure squirrel descends from animal
    var
      foo: int
    method annoy*(): string = return "SQUEEEE"
  
  
  var c = newCat()
  var arr: array[0..2, PAnimal]
  arr[0] = newCat()
  arr[1] = newDog()
  arr[2] = newSquirrel(70)
  echo arr[0].annoy()
  echo arr[1].annoy()
  echo arr[2].annoy()
  