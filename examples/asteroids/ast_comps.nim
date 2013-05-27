import fowltek/entitty, fowltek/sdl2
entitty_imports

import fowltek/vector_math
type TVector2f* = TVector2[float]


proc update* (dt: float) {.multicast.}
proc getPos* : TVector2f {.unicast.}
proc draw* (R: PRenderer) {.unicast.}

type
  Pos* = TVector2f
msg_impl(Pos, get_pos) do -> TVector2f: 
  result = entity[Pos]

type
  Vel* = object
    v: TVector2f

msg_impl(Vel, update) do (dt: float):
  entity[Pos] *= entity[Vel].v * dt

from fowltek/sdl2/spritecache import newSpriteCache, get, PSprite, setImageRoot

type
  SpriteInst* = object
    sprite*: PSprite
    rect*: TRect
SpriteInst.requiresComponent Pos

msg_impl(SpriteInst, draw) do (R: PRenderer):
  #something
  var rect = entity[SpriteInst].rect
  let p = entity[Pos].addr
  rect.x = p.x.cint
  rect.y = p.y.cint
  R.copy entity[SpriteInst].sprite.tex, 
    entity[SpriteInst].rect.addr, rect.addr  


var imageCache* = newSpriteCache(64)
proc setImageRoot* (dir: string) {.inline.} = 
  imagecache.setImageRoot(dir)

proc loadSprite* (s: var SpriteInst, R: PRenderer; file: string) =
  s.sprite = imagecache.get(R, file)
  s.rect = s.sprite.defaultRect


type
  TFrame* = tuple[col: int, time: float] 
  SimpleAnim* = object
    frames: seq[TFrame]
    curFrame: int
    timer: float
SimpleAnim.requiresComponent SpriteInst


proc loadSimpleAnim* (ent: PEntity; R: PRenderer; file: string) =
  ent[SpriteInst].loadSprite R, file
  ent[SimpleAnim].timer = 0.2
  newSeq ent[SimpleAnim].frames, ent[SpriteInst].sprite.cols
  
  for i in 0 .. <ent[SpriteInst].sprite.cols:
    ent[SimpleAnim].frames[i].col = i
    ent[SimpleAnim].frames[i].time = 0.2
  

msg_impl(SimpleAnim, update) do (dt: float): 
  entity[SimpleAnim].timer -= dt
  if entity[SimpleAnim].timer <= 0:
    let frameIndex = (entity[SimpleAnim].curFrame+1) mod entity[SimpleAnim].frames.len
    entity[SimpleAnim].curFrame = frameIndex
    entity[SimpleAnim].timer = entity[SimpleAnim].frames[frameIndex].time
    entity[SpriteInst].rect.x =cint(
      entity[SpriteInst].rect.w * entity[SimpleAnim].frames[frameIndex].col )


