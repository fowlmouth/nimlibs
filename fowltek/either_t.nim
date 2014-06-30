
type
  TEither* [L,R] = object
    case isLeft*: bool
    of true: left*: L
    of false:right*:R

proc Left* (L: any; R: typedesc): auto =
  TEither[type(L), R](isLeft: true, left: L)
proc Right*(L: typedesc, R: any): auto =
  TEither[L, type(R)](isLeft: false,right:R)

proc isRight* [L,R] (this:TEither[L,R]): bool {.inline.} = not this.isLeft

proc match* [L,R] (this:TEither[L,R]; le:proc(x:L); ri:proc(x:R)) =
  case this.isLeft
  of true: le(this.left)
  of false: ri(this.right)

proc Either* (L:any; R:typedesc): auto =
  TEither[type(L),R](isLeft: true, left: L)
proc Either* (L:typedesc; R:any): auto =
  TEither[L,type(R)](isLeft: false,right:R)

when isMainModule:

  var y = either("Foo", int)
  echo y
  y = either(string,42)
  quit 0

  template test_match [l,r] (x: TEither[l,r]): stmt =
    match(x)
    do(msg):
      echo "msg: ", msg
    do(num):
      echo "num: ", num


  var x = Left("Foo", int)
  test_match x

  x = Right(string, 42)
  echo x
  try:
    echo x.left
  except EInvalidField:
    echo "EInvalidField raised on x.left (good)"
  test_match x  
  
