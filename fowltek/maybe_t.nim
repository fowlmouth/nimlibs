import typetraits

type
  TMaybe*[T] = tuple[has: bool, val: T]

converter toBool*[T] (some: TMaybe[T]): bool = some.has
proc Just*[T] (some: T): TMaybe[T] {.inline.}= (true, some)
proc Nothing*[T]: TMaybe[T] {.inline.} = nil

proc Maybe*[T] (some: T): TMaybe[T] =
  when not compiles(isNil(some)):
    # how to stringify `A` ? 
    {.fatal: "Maybe["& name(T) &"]() requires an implementation of isNil("& name(T) &")".}
  result.has = not isNil(some)
  result.val = some 

proc `$`* [T] (some: TMaybe[T]): string =
  if some: result = $some.val
  else: result = "Nothing"

template `?`* (T:typedesc): typedesc = TMaybe[T]
  #shortcut for maybe types: ?int #=> TMaybe[int]

template `or`* [T] (a,b: TMaybe[T]): TMaybe[T] =
  if a.has: a else: b

template `or`* [T] (some:TMaybe[T]; right:T): T =
  if some.has: some.val else: right


template `.?` [T] (a:TMaybe[T]; b): expr =
  ## maybe-access operator
  ## var my = just(TFoo(x: 1))
  ## my.?x #=> just(1)
  if a.has: just(a.val.b) else: nothing[type(a.val.b)]()






when false:
  #also since we have mutability we should be able to do these
  proc assign*[T] (some: var TMaybe[T]; val: T){.inline.}= 
    some.val = val
    when compiles(isNil(val)):
      some.has = not isNil(val)
    else:
      some.has = true
  proc unset* [T] (some: var TMaybe[T]){.inline.} = 
    reset some.val
    some.has = false


when isMainModule:
  var s = Just("String")
  if s:
    echo "s is ", s.val
  else:
    echo "s is nothing"
  
  var x = Maybe("fux")
  if x: echo "x: ", x.val
  x = Maybe[string](nil)
  if x: echo "x: ", x.val
  
  var su = 32
  ## fatal error because int has no isNil()
  #echo(maybe(su))
    
  block:
    let
      a = just 3
      b = just 2
      c = nothing[int]()

    template echoCode(xpr):stmt =
      echo astToStr(xpr),": ", xpr

    echoCode a or c or 5 == 3
    echoCode c or 1      == 1
    echoCode c or b      == just(2)

  type
    TFoo = object
      zz: int

  proc zoo (some:TFoo): int =
    42

  template ec (xpr): expr =
    astToStr(xpr)&" #=> "&($ xpr)

  block:
    var x = just(TFoo(zz: 101))
    echo "should be 42: ", ec(x.?zoo)
    echo "should be 101: ", ec(x.?zz)

    x = nothing[TFoo]()
    echo "should be Nothing: ", ec(x.?zz)

    let foo = x or TFoo(zz:100)
    echo "should be 100: ", ec(foo.zz)

  
  proc test (): TMaybe[TFoo] = 
    echo "test() called"
    return just(TFoo(zz:33))
  echo ec(just(TFoo()) or test())
  echo ec(nothing[TFoo]() or nothing[TFoo]() or test())
