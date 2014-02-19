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

proc unionArea* (a, b: TBB): float {.inline.} = 
  (a.right.max(b.right) - a.left.min(b.left)) *
    (a.bottom.max(b.bottom) - a.top.min(b.top))

proc unionFast* (a, b: TBB): TBB =  
  result.left = a.left.min(b.left)
  result.top = a.top.min(b.top)
  result.width = a.right.max(b.right) - result.left
  result.height = a.bottom.max(b.bottom) - result.top

proc expandToInclude* (bb: var TBB; b: TBB) =
  bb.left = bb.left.min(b.left)
  bb.top  = bb.top.min(b.top)
  bb.width  = bb.right.max(b.right) - bb.left
  bb.height = bb.bottom.max(b.bottom) - bb.top 

proc refitFor* (bb: var TBB; a, b: TBB) =
  reset bb 
  bb.expandToInclude a
  bb.expandToInclude b

proc collidesWith* (a, b: TBB): bool {.inline.} = (
  ( (a.left >= b.left and a.left <= b.right) or (b.left >= a.left and b.left <= a.right) ) and
  ( (a.top >= b.top   and a.top <= b.bottom) or (b.top >= a.top   and b.top <= a.bottom) ) )

proc contains* (a, b: TBB): bool {.inline.} =
  ( b.left >= a.left and b.right <= a.right and
    b.top >= a.top and b.bottom <= a.bottom )

from fowltek/vector_math import TVector2
proc contains* (a: TBB; b: TVector2[float]): bool = (
  b.x >= a.left and b.x <= a.right and
  b.y >= a.top  and b.y <= a.bottom ) 

