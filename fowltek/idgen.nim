
type
  TIDGen*[A] = object
    next: A
    free: seq[A]

proc init* [A](some: var TIDGen[A]) =
  newSeq some.free, 0
proc newIDGen*[A]: TIDGen[A] =
  init result

proc get*[A] (some: var TIDGen[A]): A =
  if some.free.len > 0:
    result = some.free.pop
  else:
    result = some.next
    inc some.next
proc release*[A] (some: var TIDgen[A]; id: A) =
  some.free.  add id


when isMainModule:
  var idg = newIDGen[int16]()
  
  
  for i in 0 .. <5:
    var i1 = idg.get
    assert i == i1.int
  for i in countdown(4, 0):
    idg.release i.int16
  
  assert idg.next == 5
  assert idg.free == @[4'i16, 3, 2, 1, 0]
  