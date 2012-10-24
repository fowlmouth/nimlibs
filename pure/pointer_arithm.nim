
proc offset*[A](some: ptr A; b: int): ptr A =
  result = cast[ptr A](cast[int](some) + (b * sizeof(A)))
proc `+`*[A](some: ptr A, b: int): ptr A {.inline.} = some.offset(b)

proc inc*[A](some: var ptr A, b = 1) =
  some = some + b
proc `++`*[A](some: var ptr A): ptr A =
  ## prefix inc
  result = some
  inc some, 1

proc `[]`*[A](some: ptr A; idx: int): var A =
  ## use offset() for tuple or array ptrs, this will not works
  result = (some + idx)[]
proc `[]=`*[A](some: ptr A; idx: int; val: A) =
  (some[idx]) = val

iterator iterPtr*[A](some: ptr A; num: int): ptr A =
  for i in 0.. <num:
    yield some.offset(i)

when isMainModule:  
  var xx = [1,2,3,4]
  var zz = addr xx[0]
  echo(zz[0], " ", (zz + 0)[])
  echo(zz[1], " ", (zz + 1)[])
  
  type ttesttup = tuple[a, b: int]
  var x = cast[ptr ttesttup](alloc0(sizeof(ttesttup) * 5))
  (x + 0).a = 50
  (x + 1).a = 60
  (x + 2).a = 70
  
  for it in iterPtr(x, 5):
    echo($ it)


when false:
  var s = "hello"
  var cs = addr s[0]

  while cs[] != '\0':
    echo((++cs)[])

  var ints = [1'i16, 5'i16, 20'i16]
  var iss = addr ints[0]

  for i in 0..high(ints):
    echo($ (iss+i)[])

  cs = addr s[0]
  inc(cs)
  echo($ cs[])

  cs = addr s[0]
  var test = ""
  var i = 0
  while cs[i] != '\0':
    test.add(cs[i])
    cs[i] = '5'
    inc i
  echo test
  echo s
  
  var x = cast[ptr int16](alloc0(sizeof(int16) * 10))
  x[0] = 40
  x[1] = 20
  x[2] = 10
  x[3] = 5
  x[4] = 3
  x[5] = 2
  x[6] = 1
  
  for it in iterPtr(x, 10):
    echo($it)
    
  dealloc x
