import ast_comps, fowltek/entitty, fowltek/sdl2/engine
import_all_sdl2_modules
import os, fowltek/idgen, fowltek/vector_math
import math, tables, fowltek/tmaybe
randomize()

setImageRoot getAppDir()/"gfx"

var NG =  newSdlEngine()
var entities: seq[TEntity]

proc get_ent* (id: int): PEntity{.inline.} = entities[id]

include ast_boilerplate

var dom: TDomain
var e_id_ctr = newIDgen[int]()


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
entities = @[]

discard add_ents(10, Pos, Vel, SpriteInst, SimpleAnim, ToroidalBounds)

VAR player = dom.newEntity(Pos, Vel, SpriteInst, ToroidalBounds, 
  HID_Controller, InputState, Acceleration, Orientation, RollSprite
).add_ent

if(var (error, msg) = HID_Dispatcher.requestDevice("Keyboard", get_ent(player)); error):
  echo "Could not register keyboard: ", msg
get_ent(player)[SpriteInst].loadSprite NG, "hornet_54x54.png"


proc drawDebugStrings (E: PEntity; R: PRenderer) =
  R.mlStringRGBA 10,10,E.debugStr, 0,150,50,255


var running = true
template stopRunning = running = false

while running:
  while NG.pollHandle:
    case NG.evt.kind
    of QuitEvent: stopRunning
    of KeyDown:
      if not HID_Dispatcher.handleEvent("Keyboard", NG.evt):
        let k = NG.evt.evKeyboard.keysym.sym
        if k == K_ESCAPE: stopRunning
    of keyUp:
      discard HID_Dispatcher.handleEvent("Keyboard", NG.evt)
    else:nil
  
  let dt = NG.frameDeltaFLT
  eachEntity:
    entity.update dt
  
  NG.setDrawColor 0,0,0,255
  NG.clear
  
  eachEntity:
    entity.draw NG
  
  player.get_ent.drawDebugStrings NG
  
  NG.present

destroy NG



