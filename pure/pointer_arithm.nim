
proc `+`*[A](some: ptr A, b: int): ptr A =
  result = cast[ptr A](cast[int](some) + (b * sizeof(A)))
proc inc*[A](some: var ptr A, b = 1) =
  some = some + b
proc `++`*[A](some: var ptr A): ptr A =
  ## prefix inc
  result = some
  inc some, 1
proc `[]`*[A](some: ptr A; idx: int): var A =
  result = (some + idx)[]
proc `[]=`*[A](some: ptr A; idx: int; val: A) =
  (some[idx]) = val

when isMainModule:
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
