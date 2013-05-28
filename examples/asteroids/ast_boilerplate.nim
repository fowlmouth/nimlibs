## code that ties the component system to the main code in asteroids.nim

block :
  let winsize = NG.window.getSize
  ToroidalBounds.setInitializer proc(X: PEntity) =
    x[ToroidalBounds].rect.w = winSize.x
    x[ToroidalBounds].rect.h = winSize.y

Pos.setInitializer proc(X: PEntity) =
  X[Pos].x = random(640).float
  X[Pos].y = random(480).float

Orientation.setInitializer proc(X: PEntity)=
  X[Orientation].angleRad = random(360).float.degrees2radians

Vel.setInitializer proc(X: PEntity) =
  X[Vel].vec = random(360).float.degrees2radians.vectorForAngle * (1+(35* random(10)/10))

SimpleAnim.setInitializer proc(X: PEntity) =
  var frame: ast_comps.TFrame
  frame.col = 0
  frame.time = 1000.0
  X[SimpleAnim].frames = @[frame]
  X[SimpleAnim].timer = 1000.0


proc handleEvent* (disp: var T_HID_Dispatcher; device: string; event: var sdl2.TEvent): bool =
  if disp.hasDevice(device) and disp.devices[device].takenBy:  
    result = 
      activeServer.getEnt(disp.devices[device].takenBy.val)[HID_Controller].cb(
        activeServer.getEnt(disp.devices[device].takenBy.val), event)


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
      of K_UP: 
        rt: X.stopThrust ThrustFwd
      of K_Down: 
        rt: X.stopThrust  ThrustRev
      of K_Left: 
        rt: X.stopTurn TurnLeft
      of K_Right: 
        rt: X.stopTurn  TurnRight
      else:NIL
    else: nil


proc drawDebugStrings (E: PEntity; R: PRenderer) =
  mlStringRGBA R, 10,10, E.debugStr, 0,150,50,255
