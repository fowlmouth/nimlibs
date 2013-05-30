import unittest, strutils

import fowltek/bbtree, fowltek/boundingbox
import tables,fowltek/tmaybe

template ff (f; prec = 16): expr = $f#formatFloat(f, ffDecimal, prec)

proc `$` (some: TBB): string = "(x,y $1,$2 w,h $3,$4)" % [
  ff(some.left), ff(some.top), ff(some.width), ff(some.height) ]

type
  TestObject = tuple[id: int, bb: TBB]
proc testobj (id: int, bb: TBB): TestObject = (id,bb)


template show (v): stmt =
  echo astToStr(v), ": ", v

let 
  one = testobj(1, bb(  0,  0, 10, 10))
  two = testobj(2, bb( 15,  0, 10, 20))
  three=testobj(3, bb(  0, 15, 20, 10))
  four =testobj(4, bb(  0, 50, 20,  5))

suite "bb tree":
  setup:
    var  tree = newBBtree[int]()

  template insert_elem (item): stmt = tree.insert(item.id, item.bb)

  test "tree.insert": 
    tree.insert one.id, one.bb
    check:
      tree.hasItem one.id
      tree.getRoot.a.isNil and tree.getRoot.b.isNil
      tree.getRoot.getObj and tree.getRoot.getObj.val == one.id
      tree.getRoot.getBB == bb(0,0,10,10)

  test "tree.itemCount":
    tree.insert one.id, one.bb
    tree.insert two.id, two.bb
    check:
      tree.itemCount == 2
      not tree.getRoot.isLeaf
  
  test "Remove an item":
    insert_elem one
    insert_elem two
    insert_elem three
    tree.remove two.id
    check tree.itemCount == 2

  test "Querying a removed item":
    insert_elem one
    insert_elem two
    insert_elem three
    tree.remove one.id
    
    #tree.query one.bb, proc(item: int) =
    tree.query(one.bb) do (item: int):
      fail

  proc `$` [T] (some: seq[T]): string = 
    result = "["
    for i in 0 .. <some.len:
      result.add ($some[i])
      if i < some.high: result.add ", "
    result.add "]"

  test "Find items":
    insert_elem two
    insert_elem three
    var result: seq[int] = @[]
    tree.query(two.bb) do (item: int): result.add item
    check result == @[2, 3]

