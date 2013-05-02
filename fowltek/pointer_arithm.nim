
proc offset*[A](some: ptr A; b: int): ptr A =
  result = cast[ptr A](cast[int](some) + (b * sizeof(A)))
proc `+`*[A](some: ptr A, b: int): ptr A {.inline.} = some.offset(b)

proc inc*[A](some: var ptr A, b = 1) =
  some = some + b
proc `++`*[A](some: var ptr A): ptr A =
  ## prefix inc
  result = some
  inc some, 15


proc alloc* [A](num: int = 1): ptr A {.
  inline.} = cast[ptr A](alloc0(sizeof(A) * num))

proc `[]`*[A](some: ptr A; idx: int): var A =
  ## use offset() for tuple or array ptrs, this will not works
  result = (some + idx)[]
proc `[]=`*[A](some: ptr A; idx: int; val: A) =
  (some[idx]) = val

iterator iterPtr*[A](some: ptr A; num: int): ptr A =
  for i in 0.. <num:
    yield some.offset(i)

when isMainModule:  
  var someStr = "Hello."
  var p = someStr[0].addr
  
  
