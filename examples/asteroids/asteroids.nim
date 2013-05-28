import ast_comps, fowltek/entitty, fowltek/sdl2/engine
import_all_sdl2_modules
import os, fowltek/idgen, fowltek/vector_math
import math, tables, fowltek/tmaybe
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
  X[Vel].vec = random(360).float.degrees2radians.vectorForAngle * (1+(35* random(10)/10))

SimpleAnim.setInitializer proc(X: PEntity) =
  X.loadSimpleAnim NG, "Rock32a_32x32.png"

var entities: seq[TEntity]
proc get_ent* (id: int): PEntity{.inline.} = entities[id]

proc handleEvent* (disp: var T_HID_Dispatcher; device: string; event: var sdl2.TEvent): bool =
  if disp.hasDevice(device) and disp.devices[device].takenBy:  
    result = 
      getEnt(disp.devices[device].takenBy.val)[HID_Controller].cb(
        getEnt(disp.devices[device].takenBy.val), event)


HID_DeviceImpl("Keyboard"):
  #assert X.hasComponent(HID_Controller)
  X[HID_Controller].cb = proc(X: PEntity; event: var TEvent): bool=
    template rt(body: stmt): stmt = 
      body
      return true
    
    case event.kind
    of KeyDown:
      let k = evKeyboard(event)
      case k.keysym.sym
      of K_UP: 
        rt: X.thrust ThrustFwd
      of K_DOWN: 
        rt: X.thrust ThrustRev
      of K_LEFT: 
        rt: X.turn TurnLeft
      of K_RIGHT: 
        rt: X.turn TurnRight
      else: NIL
    of keyUp:
      let k = evKeyboard(event)
      case k.keysym.sym
      of K_UP: X.stopThrust ThrustFwd
      of K_Down: X.stopThrust  ThrustRev
      of K_Left: X.stopTurn TurnLeft
      of K_Right: X.stopTurn  TurnRight
      else:NIL
    else: nil

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

if( var (error, msg) = HID_Dispatcher.requestDevice("Keyboard", get_ent(player)); error):
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



