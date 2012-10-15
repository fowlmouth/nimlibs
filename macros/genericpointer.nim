import macros, strutils
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

Lulz be with you.
""""

## When the hell would I use this?
##
## Imagine you are interfacing with a c function which takes a
## generic pointer (Pointer) one of the first things you're going
## to do is cast it to the type you're expecting, this just takes
## that step out for you, adds a 
## `var argName = cast[desiredType](arg0)`
## to the proc body for each genericpointer[] arg declared

macro genericpointer*(someProc: expr): stmt =
  assert someProc.kind == nnkProcDef
  var 
    params = someProc[3]
    body   = someProc[6]
    genericArgs = 0
    overloadedParams = newNimNode(nnkVarSection)
  for i in 1..len(params)-1:
    var 
      p = params[i]
      name = p[0]
      ty = p[1]
    
    if ty.kind == nnkBracketExpr and ($ty[0].ident).tolower == "genericpointer":
      ## this is a genericparam[sometype]
      var 
        ptype = ty[1]
        newParams = newNimNode(nnkIdentDefs)
        cst = newNimNode(nnkCast)
        fakename = newIdentNode("arg" & $genericArgs)
      cst.add ptype, fakename
      newParams.add name, ptype, cst
      overloadedParams.add newParams
      ## rename the parameter to ArgX and change it to a pointer
      p[0] = fakename
      p[1] = newIdentNode("pointer")
      inc genericArgs
  
  if overloadedParams.len > 0: 
    body.add(body[len(body)-1])
    for i in countdown(len(body)-2, 0):
      echo i
      body[i + 1] = body[i]
    body[0] = overloadedParams
  
  when defined(Debug):
    echo repr(someProc)
  
  return someProc


when isMainModule:
  proc doo(y: genericpointer[ptr int]): int {.genericpointer, cdecl.} =
    echo "y is ", y[]
    return y[] * 2

  var i = 50
  assert doo(addr i) == i * 2
  var ii = cast[ptr int](alloc(sizeof(int)))
  ii[] = 5000
  assert doo(ii) == 10_000
  assert doo(cast[pointer](ii)) == 10_000