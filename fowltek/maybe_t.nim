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

proc `or`* [T] (a,b: TMaybe[T]): TMaybe[T] {.inline.} =
  if a.has: a else: b

proc `or`* [T] (some:TMaybe[T]; right:T): T {.inline.} =
  if some.has: some.val else: right



let
  a = just 3
  b = just 2
  c = nothing[int]()

template echoCode(xpr):stmt =
  echo astToStr(xpr),": ", xpr

echoCode a or c or 5 == 3
echoCode c or 1      == 1
echoCode c or b      == just(2)





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
  
  s.assign "Foo"
  if s: echo s.val
  
  s.unset
  if s: echo s.val
  else: echo "good"
  
  
  var x = Maybe("fux")
  if x: echo "x: ", x.val
  x = Maybe[string](nil)
  if x: echo "x: ", x.val
  
  var su = 32
  ## fatal error because int has no isNil()
  #echo(maybe(su))
  
  
  
