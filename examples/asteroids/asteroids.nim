import ast_comps, fowltek/entitty, fowltek/sdl2/engine
import_all_sdl2_modules
import os, fowltek/idgen, fowltek/vector_math
import math
randomize()

setImageRoot getAppDir()/"gfx"

var NG: TSdlEngine 
NG =  newSdlEngine()

block :
  let winsize = NG.window.getSize
  ToroidalBounds.setInitializer proc(X: PEntity) =
    x[ToroidalBounds].rect.w = winSize.x
    x[ToroidalBounds].rect.h = winSize.y

Pos.setInitializer proc(X: PEntity) =
  X[Pos].x = random(640).float
  X[Pos].y = random(480).float

Vel.setInitializer proc(X: PEntity) =
  X[Vel].v = random(360).float.degrees2radians.vectorForAngle * (1+(35* random(10)/10))

SimpleAnim.setInitializer proc(X: PEntity) =
  X.loadSimpleAnim NG, "Rock32a_32x32.png"


var dom: TDomain

var entities: seq[TEntity] = @[]
var e_id_ctr = newIDgen[int]()

proc get_ent* (id: int): PEntity{.inline.} = entities[id]

proc add_ent* (ent: TEntity): int =
  result = e_id_ctr.get
  entities.ensureLen result+1
  entities[result] = ent
  get_ent(result).id = result

proc add_ents* (num: int, components: varargs[int, `componentID`]): seq[int] =
  var ty = dom.getTypeinfo(components)
  
  newSeq result, 0
  for i in 1 .. num:
    let id = ty.NewEntity.add_ent
    result.add id


template eachEntity* (body: stmt): stmt {.immediate,dirty.}=
  for idx in 0 .. high(entities):  
    template entity: expr  = entities[idx]
    if entity.id > -1:
      body

dom = newDomain()

discard add_ents(10, Pos, Vel, SpriteInst, SimpleAnim, ToroidalBounds)

VAR player = dom.newEntity(Pos, Vel, SpriteInst, ToroidalBounds, HID_Controller, InputState).add_ent
get_ent(player)[SpriteInst].loadSprite NG, "hornet_54x54.png"


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



