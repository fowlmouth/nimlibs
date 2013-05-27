import ast_comps, fowltek/entitty, fowltek/sdl2/engine
import_all_sdl2_modules
import os #, fowltek/idgen
import math
randomize()

setImageRoot  "/media/fowl/Toshiba Ext HDD/projects/keineSchweine/data/gfx"

var dom = newDomain()
var ast = dom.newEntity(Pos, Vel, SpriteInst, SimpleAnim)
var NG: TSdlEngine

var entities: seq[TEntity] = @[]
#var ent_id_ctr : TIDgen[int]
#ent_id_ctr.init

proc get_ent* (id: int): PEntity{.inline.} = entities[id]

var ent_id_ctr = 0
proc next_id: int = 
  result = ent_id_ctr
  inc ent_id_ctr

proc toPTR(some: int): pointer{.inline.} = cast[pointer](some)

proc add_ent* (ent: TEntity): int =
  var id = next_id()
  entities.ensureLen id+1
  entities[id] = ent
  get_ent(id).userData = toPTR(id)
  result = id

proc add_ents* (num: int, components: varargs[int, `componentID`]): seq[int] =
  var ty = dom.getTypeinfo(components)
  if not ty.isValid: return
  
  newSeq result, 0
  for i in 1 .. num:
    let id = ty.NewEntity.add_ent
    result.add id
    if id.get_ent.hasComponent(Pos):
      id.get_ent[Pos] = (random(640).float, random(480).float)
    if id.get_ent.hasComponent(SimpleAnim):
      id.get_ent.loadSimpleAnim NG, "asteroids/Rock32a_32x32.png"

template eachEntity* (body: stmt): stmt {.immediate.}=
  for id{.inject.} in 0 .. high(entities):  
    template entity: expr {.inject.} = entities[id]
    body

NG =  newSdlEngine()

discard add_ents (10, Pos, Vel, SpriteInst, SimpleAnim)

var running = true
template stopRunning = running = false

while running:
  while NG.pollHandle:
    case NG.evt.kind
    of QuitEvent: stopRunning
    of KeyDown:
      let k = NG.evt.evKeyboard.keysym.sym
      if k == K_ESCAPE: stopRunning
    else:nil
  
  let dt = NG.frameDeltaFLT
  eachEntity:
    entity.update dt
  
  NG.setDrawColor 0,0,0,255
  NG.clear
  
  eachEntity:
    entity.draw NG
  
  NG.present

destroy NG



