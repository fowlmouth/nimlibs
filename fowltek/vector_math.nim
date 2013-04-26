import math
type
  TVector2*[A] = tuple[x: A, y: A]
  
  TVector3*[A] = tuple[x: A, y: A, z: A]
  
  TVector4*[A] = tuple[x: A, y: A, z: A, w: A]

proc vec2*[A](x, y: A): TVector2[A] =
  result.x = x
  result.y = y 
proc vec3*[A](x, y, z: A): TVector3[A] =
  result.x = x
  result.y = y
  result.z = z
proc vec4*[A](x, y, z, w: A): TVector4[A] =
  result.x = x
  result.y = y
  result.z = z
  result.w = w

proc `+`*[T](a, b: TVector2[T]): TVector2[T] {.inline.} =
  result.x = a.x + b.x
  result.y = a.y + b.y
proc `-`*[T](a: TVector2[T]): TVector2[T] {.inline.} =
  result.x = -a.x
  result.y = -a.y
proc `-`*[T](a, b: TVector2[T]): TVector2[T] {.inline.}=
  result.x = a.x - b.x
  result.y = a.y - b.y
proc `*`*[T](a: TVector2[T], b: T): TVector2[T] {.inline.} =
  result.x = a.x * b
  result.y = a.y * b
proc `*`*[T](a, b: TVector2[T]): TVector2[T] {.inline.} =
  result.x = a.x * b.x
  result.y = a.y * b.y

proc `/`*[T](a: TVector2[T], b: cfloat): TVector2[T] {.inline.} =
  result.x = a.x / b
  result.y = a.y / b
proc `+=`*[T](a: var TVector2[T], b: TVector2[T]) {.inline, noSideEffect.} =
  a = a + b
proc `-=`*[T](a: var TVector2[T], b: TVector2[T]) {.inline, noSideEffect.} =
  a = a - b
proc `*=`*[T](a: var TVector2[T], b: float) {.inline, noSideEffect.} =
  a = a * b
proc `*=`*[T](a: var TVector2[T], b: TVector2[T]) {.inline, noSideEffect.} =
  a = a * b
proc `/=`*[T](a: var TVector2[T], b: float) {.inline, noSideEffect.} =
  a = a / b
proc `<`*[T](a, b: TVector2[T]): bool {.inline, noSideEffect.} =
  return a.x < b.x or (a.x == b.x and a.y < b.y)
proc `<=`*[T](a, b: TVector2[T]): bool {.inline, noSideEffect.} =
  return a.x <= b.x and a.y <= b.y
proc `==`*[T](a, b: TVector2[T]): bool {.inline, noSideEffect.} =
  return a.x == b.x and a.y == b.y
proc length*[T](a: TVector2[T]): float {.inline.} =
  return sqrt(pow(a.x, 2.0) + pow(a.y, 2.0))
proc lengthSq*[T](a: TVector2[T]): float {.inline.} =
  return pow(a.x, 2.0) + pow(a.y, 2.0)
proc distanceSq*[T](a, b: TVector2[T]): float {.inline.} =
  return pow(a.x - b.x, 2.0) + pow(a.y - b.y, 2.0)
proc distance*[T](a, b: TVector2[T]): float {.inline.} =
  return sqrt(pow(a.x - b.x, 2.0) + pow(a.y - b.y, 2.0))
proc permul*[T](a, b: TVector2[T]): TVector2[T] =
  result.x = a.x * b.x
  result.y = a.y * b.y
proc rotate*[T](a: TVector2[T], phi: float): TVector2[T] =
  var c = cos(phi)
  var s = sin(phi)
  result.x = a.x * c - a.y * s
  result.y = a.x * s + a.y * c
proc perpendicular*[T](a: TVector2[T]): TVector2[T] =
  result.x = -a.x
  result.y =  a.y
proc cross*[T](a, b: TVector2[T]): float =
  return a.x * b.y - a.y * b.x
proc dot*[T](a, b: TVector2[T]): float = a.x*b.x + a.y*b.y

proc `+`*[T](a, b: TVector3[T]): TVector3[T] {.inline, noSideEffect.} =
  result.x = a.x + b.x
  result.y = a.y + b.y
  result.z = a.z + b.z
proc `-`*[T](a, b: TVector3[T]): TVector3[T] {.inline, noSideEffect.} =
  result.x = a.x - b.x
  result.y = a.y - b.y
  result.z = a.z - b.z
proc `-`*[T](a: TVector3[T]): TVector3[T] {.inline, noSideEffect.} =
  result.x = -a.x
  result.y = -a.y
  result.z = -a.z
proc `*`*[T](a, b: TVector3[T]): TVector3[T] {.inline, noSideEffect.} =
  result.x = a.x * b.x
  result.y = a.y * b.y
  result.z = a.z * b.z
proc `*`*[T](a: TVector3[T]; b: T): TVector3[T] {.inline, noSideEffect.}=
  result.x = a.x * b
  result.y = a.y * b
  result.z = a.z * b
proc `/`*[T](a: TVector3[T]; b: T): TVector3[T] {.inline, noSideEffect.}=
  result.x = a.x / b
  result.y = a.y / b
  result.z = a.z / b
proc `+=`*[T](a: var TVector3[T]; b: TVector3[T]) {.inline, noSideEffect.} =
  a = a + b
proc `-=`*[T](a: var TVector3[T]; b: TVector3[T]) {.inline, noSideEffect.} =
  a = a - b
proc `*=`*[T](a: var TVector3[T]; b: TVector3[T]) {.inline, noSideEffect.} =
  a = a * b
proc `*=`*[T](a: var TVector3[T]; b: T) {.inline, noSideEffect.} =
  a = a * b
proc `/=`*[T](a: var TVector3[T]; b: T) {.inline, noSideEffect.} =
  a = a / b

proc cross*[T](a, b: TVector3[T]): TVector3[T] =
  result.x = a.y * b.z - a.z * b.y
  result.y = a.z * b.x - a.x * b.z
  result.z = a.x * b.y - a.y * b.x
proc dot*[T](a, b: TVector3[T]): float =
  result = (a.x * b.x + a.y * b.y + a.z * b.z)
proc length*[T](a: TVector3[T]): float =
  result = sqrt(float(a.x * a.x + a.y * a.y + a.z * a.z))
proc lengthSq*[T](a: TVector3[T]): float =
  result = a.x * a.x + a.y * a.y + a.z * a.z
proc distance*[T](a, b: TVector3[T]): float {.inline.} = 
  result = (a - b).length()
proc distanceSq*[T](a, b: TVector3[T]): float {.inline.} =
  result = (a - b).lengthSq()

proc normalize*[T](a: TVector3[T]): TVector3[T] =
  result = a / length(a)

proc `+`*[T](a: TVector4[T]; b: TVector4[T]):TVector4[T] {.inline.} =
  result.x = a.x + b.x
  result.y = a.y + b.y
  result.z = a.z + b.z
  result.w = a.w + b.w
proc `*`*[T, U](a: TVector4[T]; b: U): TVector4[T] {.inline, noSideEffect.}=
  result.x = T(U(a.x) * b)
  result.y = T(U(a.y) * b)
  result.z = T(U(a.z) * b)
  result.w = T(U(a.w) * b)
