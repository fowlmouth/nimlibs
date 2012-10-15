
proc `+`[A](some: ptr A, b: int): ptr A =
  result = cast[ptr A](cast[int](some) + (b * sizeof(A)))
proc inc[A](some: var ptr A, b = 1) =
  some = some + b
proc `++`[A](some: var ptr A): ptr A =
  ## prefix inc
  result = some
  inc some, 1

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