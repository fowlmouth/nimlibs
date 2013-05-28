import fowltek/entitty, fowltek/sdl2
import fowltek/TMaybe, math, fowltek/vector_math
type TVector2f* = TVector2[float]


proc debugSTR* (result: var seq[string]) {.multicast.}
proc debugSTR* (entity: PEntity): seq[string] =
  newseq result, 0
  entity.debugStr result
template debug_str_impl(ty; body: stmt): stmt {.immediate.}=
  msg_impl(ty, debugSTR) do (result: var seq[string]):
    body

template default_debug_str(ty): stmt {.immediate.} =
  debugStrImpl(ty):
    result.add("$1: $2".format(componentInfo(ty).name, $ entity[ty]))


proc update* (dt: float) {.multicast.}
proc getPos* : TVector2f {.unicast.}
proc draw* (R: PRenderer) {.unicast.}


proc `$`* (some: TVector2f): string = "($1, $2)" % [formatFloat(some.x, ffDecimal, 4),
  formatFloat(some.y, ffDecimal, 4) ]




type
  Pos* = TVector2f
msg_impl(Pos, get_pos) do -> TVector2f: 
  result = entity[Pos]
default_debug_str Pos

type
  Vel* = object
    vec*: TVector2f

msg_impl(Vel, update) do (dt: float):
  entity[Pos] += entity[Vel].vec * dt

msg_impl(Vel, debugSTR) do(result:var seq[string]):
  result.add "Vel: $1" % $entity[Vel].vec

from fowltek/sdl2/spritecache import newSpriteCache, get, PSprite, setImageRoot


type
  SpriteInst* = object
    sprite*: PSprite
    rect*: TRect
SpriteInst.requiresComponent Pos

msg_impl(SpriteInst, draw) do (R: PRenderer):
  #something
  var dest = entity[SpriteInst].rect
  let p = entity[Pos].addr
  dest.x = p.x.cint
  dest.y = p.y.cint
  R.copy entity[SpriteInst].sprite.tex, 
    entity[SpriteInst].rect.addr, dest.addr  


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



type
  ToroidalBounds* = object
    rect*: TRect
ToroidalBounds.requiresComponent pos

proc right* (some: TRect): cint = some.x + some.w
proc bottom*(some: TRect): cint = some.y + some.h

msg_impl(ToroidalBounds, update) do (dt: float) :
  let p = entity[Pos].addr
  if p.x.cint < entity[ToroidalBounds].rect.x:
    p.x = entity[ToroidalBounds].rect.right.float
  elif p.x.cint > entity[ToroidalBounds].rect.right:
    p.x = entity[ToroidalBounds].rect.x.float
  if p.y.cint < entity[ToroidalBounds].rect.y:
    p.y = entity[ToroidalBounds].rect.bottom.float
  elif p.y.cint > entity[ToroidalBounds].rect.bottom:
    p.y = entity[ToroidalBounds].rect.y.float


from fowltek/sdl2/engine import radians2degrees, vectorForAngle
type
  Orientation* = object
    angleRad*: float
debugStrImpl(Orientation):
  result.add "Orientation: $# degrees" % entity[Orientation].angleRad.radians2degrees.formatFloat(ffDecimal, 2)

type
  Acceleration* = object
    vec: TVector2f
Acceleration.requiresComponent Vel
defaultDebugStr Acceleration

msg_impl(Acceleration, update) do (dt: float):
  entity[Vel].vec += entity[Acceleration].vec
  reset entity[Acceleration].vec



type
  TThrustState* = enum ThrustIdle, ThrustFwd, ThrustRev
  TTurningState* = enum TurnIdle, TurnRight, TurnLeft
  InputState* = object
    thrust*: TThrustState
    turning*: TTurningState
InputState.requiresComponent Acceleration, Orientation
defaultDebugStr InputState

proc turn* (dir: TTurningState) {.unicast.}
proc stopTurn* (dir: TTurningState) {.unicast.}
proc thrust* (dir: TThrustState) {.unicast.}
proc stopThrust* (dir: TThrustState) {.unicast.}

proc roll* (dir: TTurningState) {.unicast.}


msg_impl(InputState, turn) do (dir: TTurningState):
  entity[InputState].turning = dir
msg_impl(InputState, stopTurn) do (dir: TTurningState):
  if entity[InputState].turning == dir:
    entity[InputState].turning = TurnIdle
msg_impl(InputState, thrust) do (dir: TThrustState):
  entity[InputState].thrust = dir
msg_impl(InputState, stopThrust) do (dir: TThrustState):
  if entity[InputState].thrust == dir:
    entity[InputState].thrust = ThrustIdle
msg_impl(InputState, update) do (dt: float): 
  case entity[InputState].thrust
  of ThrustFwd:
    entity[Acceleration].vec = entity[Orientation].angleRad.vectorForAngle * 0.22
  of ThrustRev:
    entity[Acceleration].vec = entity[Orientation].angleRad.vectorForAngle * -0.22
  else: nil
  case entity[InputState].turning
  of TurnRight:
    entity[Orientation].angleRad += 1.0 * dt
    entity.roll TurnRight
  of TurnLeft:
    entity[Orientation].angleRad -= 1.0 * dt
    entity.roll TurnLeft
  else:nil

type
  InputController* = object of TObject
    name*: string
    cb*: proc(X: PEntity; event: var TEvent): bool 

proc initInputController* (controller: ptr InputController) =
  controller.name = "Disconnected"
  controller.cb = proc(X: PEntity; event: var TEvent): bool = false

type
  HID_Controller* = object of InputController

HID_Controller.setInitializer proc(X: PEntity) =
  initInputController X[HID_Controller].addr

debugStrImpl(HID_Controller):
  result.add "HID Controller: $#" % entity[HID_Controller].name

## HID Dispatcher for sdl events

type
  T_HID_DispatchRec* = tuple[takenBy: TMaybe[int], setup: proc(X: PEntity)]
  T_HID_Dispatcher* = object
    devices*: TTable[string, T_HID_DispatchRec]  

var HID_Dispatcher*: T_HID_Dispatcher
HID_Dispatcher.devices =  initTable[string, T_HID_DispatchRec](8)


template HID_Device_Impl *(name_str: expr[string]; body: stmt): stmt {.immediate.} =
  block:
    var dev: T_HID_DispatchRec
    dev.setup = proc(X: PEntity) =
      body
      X[HID_Controller].name = name_str
    HID_Dispatcher.devices[name_str] = dev

proc hasDevice* (disp: var T_HID_Dispatcher; device: string): bool = disp.devices.hasKey(device)

proc requestDevice* (disp: var T_HID_Dispatcher; device: string; 
    entity: PEntity): TMaybe[string] =
  if not disp.hasDevice(device):
    return Just("Invalid device $#" % device)
  elif disp.devices[device].takenBy:
    return Just("Device is already registered.")
  
  disp.devices[device].setup(entity)
  disp.devices.mget(device).takenBy = Just(entity.id)



# RollSprite are the fake-3d sprites like the ship sprites (rotation angles are rows)
type
  RollSprite* = object
    roll: float
RollSprite.requiresComponent SpriteInst
debugStrImpl(RollSprite):
  result.add "Roll: $#" % formatFloat(entity[RollSprite].roll,ffDecimal,2)

msg_impl(RollSprite, update) do (dt: float):
  entity[RollSprite].roll *= 0.98
  
msg_impl(RollSprite, draw, 1000) do (R: PRenderer):
  var dest = entity[SpriteInst].rect
  let p = entity[Pos].addr
  dest.x = p.x.cint
  dest.y = p.y.cint 
  # set the row/col of the src rect
  # i want -1 to be 0 and 1 to be sprite.cols
  
  # so i take roll (it goes from -1 to 1), add 1 to it, divide by 2 
  # multiply by how many cols there are
  
  entity[SpriteInst].rect.x = (
    ((entity[RollSprite].roll + 1.0) / 2.0 * entity[SpriteInst].sprite.cols.float)
  ).floor.cint * entity[SpriteInst].rect.w
  entity[SpriteInst].rect.y = (
    entity[Orientation].angleRad.radians2degrees / 360.0 * entity[SpriteInst].sprite.rows.float
  ).floor.cint * entity[SpriteInst].rect.h 
  
  R.copy entity[SpriteInst].sprite.tex, entity[SpriteInst].rect.addr, dest.addr

msg_impl(RollSprite, roll) do (dir: TTurningState):
  case dir
  of TurnRight:
    entity[RollSprite].roll -= 0.2
    if entity[RollSprite].roll < -1: entity[RollSprite].roll = -1
  of TurnLeft:
    entity[RollSprite].roll += 0.2
    if entity[RollSprite].roll > 1: entity[RollSprite].roll = 1
  else:nil


