import math
type
  TBB* = tuple[
    left, top, width, height: float]



proc bb* [T: TNumber] (x, y, w, h: T): TBB {.
  inline.} = (x.float, y.float, w.float, h.float) 
proc bb* (x, y, w, h: float): TBB {.
  inline.} = (x,y,w,h) 

proc right* (a: TBB): float {.inline.} = a.left + a.width
proc bottom*(a: TBB): float {.inline.} = a.top + a.height
proc area*  (a: TBB): float {.inline.} = a.width * a.height

proc contains* (a, b: TBB): bool = (
  a.left <= b.left and a.right <= b.right and
  a.top <= b.top and a.bottom <= b.bottom )

proc unionArea* (a, b: TBB): float {.inline.} = (
  (a.right.max(b.right) - a.left.min(b.left)) *
  (a.bottom.max(b.bottom) - a.top.min(b.top))    )

proc unionFast* (a, b: TBB): TBB =
  let
    rleft = a.left.min(b.left)
    rtop = a.top.min(b.top)
  return (rleft, rtop, a.right.max(b.right) - rleft, a.bottom.max(b.bottom) - rtop)

proc expandToInclude* (bb: var TBB; b: TBB) =
  let 
    left = bb.left.min(b.left)
    top = bb.top.min(b.top)
  bb.left = left
  bb.top = top
  bb.width = bb.right.max(b.right) - left
  bb.height = bb.bottom.max(b.bottom) - top 

proc refitFor* (bb: var TBB; a, b: TBB) =
  reset bb 
  bb.expandToInclude a
  bb.expandToInclude b

proc collidesWith* (a, b: TBB): bool {.inline.} = (
  ( (a.left >= b.left and a.left <= b.right) or (b.left >= a.left and b.left <= a.right) ) and
  ( (a.top >= b.top and a.top <= b.bottom) or (b.top >= a.top and b.top <= a.bottom) ) )


