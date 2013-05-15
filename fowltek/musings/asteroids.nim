## asteroids demo
import math, os, re
import strutils, sequtils, algorithm
randomize()
import fowltek/vector_math
import fowltek/sdl2/engine
import_all_sdl2_modules

import entitty
entitty_imports

var engy: TsdlEngine

type
  TVector2f = TVector2[float]
  
template ff(some: float, precision = 3): string = formatFloat(some, ffDecimal, precision)
proc `$`*(some: TVector2f): string = "($1,$2)".format(ff(some.x), ff(some.y))


## messages 
proc takeDamage* (amount: int) {.unicast.}

proc placeAt*(pos: TVector2f) {.unicast.}
proc update*(dt: float){.multicast.}
proc onDeath* {.multicast.}

proc handleEvent* (event: var TEvent; handled: var bool) {.multicast.}

proc handleCollision*(withEntity: PEntity) {.unicast.}

proc draw(R: sdl2.PRenderer) {.multicast.}

proc debugStr* (collection: var seq[string]) {.multicast.}
proc debugDraw(R: sdl2.PRenderer) {.multicast.}

type
  Position* = TVector2[float]

proc pos*[A: TNumber](x, y: A): Position =
  result.x = x.float
  result.y = y.float

defcomponent Position
Position.setInitializer  proc(entity: PEntity) =
  entity[Position].x = random(640).float
  entity[Position].y = random(480).float
msg_impl(Position, placeAt) do (pos: TVector2f):
  entity[Position].x = pos.x
  entity[Position].y = pos.y

type
  Orientation* = object
    angleRadians: float
defComponent Orientation


proc die(entity: PEntity)

type
  Health = object
    hp, max: int

defComponent Health
Health.setInitializer proc(entity: PEntity) =
  entity[Health] = Health(hp: 100, max: 100)

msg_impl(Health, takeDamage) do(amount: int) :
  entity[Health].hp -= amount
  if entity[Health].hp <= 0:
    entity.die

type Immortal = object
defComponent Immortal

msg_impl(Immortal, takeDamage, 9001) do(amount: int):
  #nope

type
  Velocity = object
    v: TVector2[float]
    max: float

defComponent Velocity
Velocity.requiresComponent Position

msg_impl(Velocity, update) do(dt: float):
  entity[Position] += entity[Velocity].v * dt

type Friction = object
  f: float
defComponent Friction
Friction.requiresComponent Velocity
Friction.setInitializer proc(x: PEntity) = 
  x[Friction].f = 1.0
msg_impl(Friction, update) do(dt: float): 
  entity[Velocity].v *= pow(entity[Friction].f, dt)

type
  Sprite = object 
    sprite: PSprite
    rect: TRect 
  
  ## Sprite record (a cache is kept)
  PSprite = ref object
    file: string
    tex: PTexture
    defaultRect: sdl2.TRect
    rows, cols: int
    center: TPoint

proc `$`*(some: Sprite): string = (
  if some.sprite.isNil: "nil"  else: some.sprite.file )
defComponent Sprite, "Sprite"
Sprite.requiresComponent Position


var spriteCache = initTable[string, pSprite](64)
const imageRoot = "/home/fowl/projects/keineSchweine/data/gfx"
let imageFilenamePattern = re"\S+_(\d+)x(\d+)\.\S{3,4}"

proc getSprite(R: PRenderer; file: string): PSprite =
  result = spriteCache[file]
  if result.isNil:
    result = PSprite(file: file)
    var img = img_load(imageRoot / file)
    result.tex = R.createTextureFromSurface(img)
    result.defaultRect.w = img.w
    result.defaultRect.h = img.h
    if file =~ imageFilenamePattern:
      result.defaultRect.w = matches[0].parseInt.cint
      result.defaultRect.h = matches[1].parseInt.cint
    result.center.x = cint(result.defaultRect.w / 2)
    result.center.y = cint(result.defaultRect.h / 2)
    
    result.rows = int(img.h / result.defaultRect.h)
    result.cols = int(img.w / result.defaultRect.w)
    img.destroy
    
    spriteCache[file] = result
proc instanceSprite(self: var Sprite; R: PRenderer; file: string) =
  self.sprite = R.getSprite(file)
  self.rect = self.sprite.defaultRect
Sprite.setInitializer  proc(entity: PEntity) =
  instanceSprite entity[Sprite], engy, "asteroids/Rock48c_48x48.png" 
msg_impl(Sprite, draw) do (R: PRenderer):
  var rect = Entity[Sprite].rect
  let pos = entity[Position].addr
  rect.x = pos.x.cint - entity[Sprite].sprite.center.x 
  rect.y = pos.y.cint - entity[Sprite].sprite.center.y
  
  R.copy(
    Entity[Sprite].sprite.tex, 
    Entity[Sprite].rect.addr,
    rect.addr    ) 


type
  TFrameDelay* = tuple[frame: int, delay: float]
  SimpleAnimation = object
    timer: float
    index: int
    frameDelays: seq[TFrameDelay]
    animationMode: TAnimationMode 
  TAnimationMode {.pure.} = enum Loop, Bounce

proc nFrames* (some: var SimpleAnimation): int {.inline.} = len(some.frameDelays)
proc currentFrame* (some: var SimpleAnimation): var TFrameDelay{.
  inline.} = some.frameDelays[some.index]
proc nextFrame* (some: var SimpleAnimation, sprite: var Sprite) {. inline.} =
  some.index = (some.index + 1) mod some.nFrames
  some.timer = some.currentFrame.delay
  sprite.rect.x = cint(sprite.rect.w * some.currentFrame.frame)

defComponent SimpleAnimation
SimpleAnimation.requiresComponent Sprite
SimpleAnimation.setInitializer proc(x: PEntity) =
  ## sets up an animation to run through all columns
  ## could cache this in spriteCache
  let cols = x[Sprite].sprite.cols
  let SA = x[SimpleAnimation].addr
  newSeq SA.frameDelays, cols
  for i in 0.. <cols:
    SA.frameDelays[i] = (i, 0.2)

msg_impl(SimpleAnimation, update) do(dt: float): 
  entity[SimpleAnimation].timer -= dt
  if entity[SimpleAnimation].timer < 0:
    entity[SimpleAnimation].nextFrame entity.get(Sprite)

proc newSimpleAnimation* (frames: varargs[TFrameDelay]): SimpleAnimation =
  result = SimpleAnimation(frameDelays: @frames)
  result.timer = result.frameDelays[0].delay

type RollAnimation = object 
  roll: float
defComponent RollAnimation
RollAnimation.requiresComponent Sprite, Orientation
#RollAnimation.conflictsWith SimpleAnimation

proc roll(amount: float) {.unicast.}
msg_impl(RollAnimation, roll) do(amount: float):
  entity[RollAnimation].roll += amount
  if entity[RollAnimation].roll > 1: entity[RollAnimation].roll = 1
  elif entity[RollAnimation].roll < -1: entity[RollAnimation].roll = -1

msg_impl(RollAnimation, update) do(dt: float):
  let spr = entity[Sprite].addr
  # in a roll sprite the rows are angles
  let row = ((entity[Orientation].angleRadians.radians2degrees / 360.0) * entity[Sprite].sprite.rows.float).int
  entity[Sprite].rect.y = cint(row * entity[Sprite].rect.h)
  let cols = entity[Sprite].sprite.cols
  let midCol = floor(cols / 2)
  #echo "midcol is ", midcol.int
  #echo "calculated column is ", cint(midCol + (midCol * entity[RollAnimation].roll))
  #echo "roll is ", ff(entity[RollAnimation].roll) 
  entity[Sprite].rect.x = cint(midCol + (midCol * entity[RollAnimation].roll)) * entity[Sprite].sprite.defaultRect.w
  #entity[Sprite].rect.x = cint(col * entity[Sprite].rect.w)
  entity[RollAnimation].roll *= 0.9



type
  TEntCallback = proc(x: PEntity)
proc callback_nop (x: PEntity) = nil

type
  DeathCallback = object
    cb: TEntCallback

defComponent DeathCallback
DeathCallback.setInitializer proc(x: PEntity) = x[DeathCallback].cb = callback_nop

msg_impl(DeathCallback, onDeath) do:
  entity[DeathCallback].cb(entity)


type # Keeps an entity within a boundary
  Bounded = object 
    rect: sdl2.TRect
    checkEnt: proc(entity: PEntity; bounds: var Bounded)



defComponent Bounded
Bounded.requiresComponent Position, Velocity

proc right*(some: ptr TRect): cint {.inline.} = some.x + some.w
proc bottom*(some: ptr TRect): cint {.inline.} = some.y + some.h

proc newBounded(x, y, w, h: int): Bounded =
  result.rect = rect(x.cint, y.cint, w.cint, h.cint)

proc setToroidal(bounds: var Bounded) =
  bounds.checkEnt = proc(entity: PEntity; bounds: var Bounded) =
    let pos = entity[Position].addr
    let bounds = bounds.rect.addr
    if pos.x.cint < bounds.x:
      pos.x = bounds.right.float
    elif pos.x.cint > bounds.right:
      pos.x = bounds.x.float
    if pos.y.cint < bounds.y:
      pos.y = bounds.bottom.float
    elif pos.y.cint > bounds.bottom:
      pos.y = bounds.y.float
    
proc toroidalBounds(x, y, w, h: int): Bounded =
  result = newBounded(x,y,w,h)
  result.setToroidal

proc setBouncy(bounds: var Bounded) =
  bounds.checkEnt = proc(entity: PEntity; bounds: var Bounded) =
    let pos = entity[Position].addr  
    let vel = entity[Velocity].v.addr
    let bounds = bounds.rect.addr
    template flipReset(field, toVal): stmt =
      pos.field = toVal
      vel.field = - vel.field
    
    if pos.x.cint < bounds.x:
      flipReset(x, bounds.x.float)
    elif pos.x.cint > bounds.right:
      flipReset(x, bounds.right.float)
      
    if pos.y.cint < bounds.y: 
      flipReset(y, bounds.y.float)
    elif pos.y.cint > bounds.bottom:
      flipReset(y, bounds.bottom.float) # """
proc bouncyBounds(x, y, w, h: int): Bounded = 
  result = newBounded(x, y, w, h)
  result.setBouncy

msg_impl(Bounded, update) do (dt: float):
  entity[Bounded].checkEnt entity, entity[Bounded]

type
  TEventHandler* = proc(entity: PEntity; event: var TEvent; result: var bool)
  InputCB* = object
    handler: TEventHandler

proc inputNop (entity: PEntity; event: var TEvent; result: var bool) = nil

defComponent InputCB
InputCB.setInitializer proc(X: PEntity) = 
  X[InputCB].handler = inputNop
msg_impl(InputCB, handleEvent) do (event: var TEvent; result: var bool):
  entity[InputCB].handler(entity, event, result)



type CollisionHandler = object
  handler: proc(entity1, entity2: PEntity)
defComponent CollisionHandler
CollisionHandler.setInitializer proc(x: PEntity) =
  x[CollisionHandler].handler = proc(a,b: PEntity) = nil
msg_impl(CollisionHandler, handleCollision, 1000) do (withEntity: PEntity):
  entity[CollisionHandler].handler(entity, withEntity)


type
  TTurn {.pure.} = enum
    None, Right, Left
  TThrust{.pure.}= enum
    Idle, Forward, Reverse
  InputState = object
    turning: TTurn
    thrust: TThrust

proc add*(some: var Velocity; vector: TVector2f) = 
  some.v += vector
  if some.v.length > some.max:
    some.v *= (1.0 - (some.v.length - some.max))
    echo($some.v)


proc turn* (dir: TTurn; activate = true) {.unicast.}
proc thrust* (dir: TThrust; activate = true) {.unicast.}

defComponent InputState
InputState.requiresComponent Position, Velocity, Orientation
msg_impl(InputState, turn) do (dir: TTurn; activate: bool):
  let s = entity[InputState].addr
  if activate:
    s.turning = dir
  elif s.turning == dir:
    s.turning = TTurn.None
msg_impl(InputState, thrust) do(dir: TThrust; activate: bool):
  template t : expr = entity[InputState].thrust 
  if activate:
    t = dir
  elif entity[InputState].thrust == dir:
    t = TThrust.Idle

msg_impl(InputState, update) do(dt: float):
  case entity[InputState].turning
  of TTurn.Right: 
    entity[Orientation].angleRadians += 2.0.degrees2radians
    entity.roll 0.02
  of TTurn.Left:  
    entity[Orientation].angleRadians -= 2.0.degrees2radians
    entity.roll( -0.02 )
  else: nil
  case entity[InputState].thrust
  of TThrust.Forward: 
    entity[Velocity].add vectorForAngle(entity[Orientation].angleRadians)
  of TThrust.Reverse: 
    entity[Velocity].add(- vectorForAngle(entity[Orientation].angleRadians))
  else: nil


template debugStrImpl(ty): stmt =
  msg_impl(ty, debugStr) do(result: var seq[string]):
    result.add "$#: $#".format(ComponentInfo(ty).name, entity[ty])
debugStrImpl(Health)
debugStrImpl(Position)
debugStrImpl(Velocity)
debugStrImpl(Sprite)

proc debugStr*(entity: PEntity): seq[string] {.inline.}=
  result = @[]
  entity.debugStr(result)

var 
  EM = newEntityManager()
  entities = newSeq[TEntity](0)

proc `$`* [T] (some: seq[T]): string = "[$#]".format(some.map(proc(x: T): string = $x).join(", "))

var reaper: tuple[souls: seq[int]]
reaper.souls = @[]
proc reap =
  if len(reaper.souls) > 0:
    reaper.souls = distnct(reaper.souls)
    reaper.souls.sort cmp[int]
    #echo "reaping ", reaper.souls.len, " souls ", reaper.souls
    for i in countdown(<len(reaper.souls), 0):
      # go in reverse so the indexes can be deleted safely
      #echo(<reaper.souls.len, "  ", i)
      destroy entities[reaper.souls[i]]
      entities.del reaper.souls[i]
    reaper.souls.setLen 0

proc die(entity: PEntity) =
  let e = entity.addr
  for i in 0 .. < entities.len:
    if e == entities[i].addr:
      entity.onDeath
      reaper.souls.add i
      return

proc vec2short* [T](vec: TVector2[T]): TVector2[int16] {.
  inline.} = vec2[int16]( vec.x.int16, vec.y.int16)

var debugDrawDisabled: array[0 .. <100, bool]
template disableDebugDraw(ty): stmt = debugDrawDisabled[componentID(ty)] = true

disableDebugDraw Velocity
 
template debugDrawImpl (ty: expr, body: stmt): stmt {.immediate.}  =
  msg_impl(ty, debugDraw) do(R: PRenderer):
    if debugDrawDisabled[componentID(ty)]: return
    body

debugDrawImpl(Position): 
  let p = entity[Position]
  let s = $p #entity.debugStr
  R.stringRGBA(p.x.int16, p.y.int16, s, 255,0,0,255)
debugDrawImpl(Velocity): 
  let p = entity[Position]
  let v = entity[Velocity].v * 10.0
  let p_plus_v = vec2short(p + v)
  R.setDrawColor 255,0,0,255
  R.drawLine p.x.int16, p.y.int16, p_plus_v.x, p_plus_v.y
  R.stringRGBA p_plus_v.x, p_plus_v.y, "vel "& $v, 255,0,0,255  

engy = newSdlEngine()

block:
  let winsize = vec2[int](engy.window.getSize.x, engy.window.getSize.y)
  Bounded.setInitializer proc(entity: PEntity) = entity[Bounded] = ToroidalBounds(0, 0, winSize.x, winSize.y)


type DebugInfoDisp = object
  result: seq[string]
defComponent DebugInfoDisp
DebugInfoDisp.setInitializer proc(x: PEntity) =
  newSeq x[DebugInfoDisp].result, 0
debugDrawImpl( DebugInfoDisp):
  R.MLstringRGBA 0,0, entity[DebugInfoDisp].result, 255,0,0,255


type
  TLayer* = enum # entities collide if they share any of the same layers ((layers1 - layers2).card > 0)
    Layer1, Layer2, Layer3, Layer4, Layer5, Layer6
  TCollisionDiscriminant* = tuple[group: int, layers: set[TLayer]]
  
  BoundingCircle = object
    discriminant: TCollisionDiscriminant
    radius: float

defComponent BoundingCircle
BoundingCircle.requiresComponent Position

proc checkCollision*(entity2: PEntity): bool {.unicast.} 
msg_impl(BoundingCircle, checkCollision) do(entity2: PEntity) -> bool:
  result = entity[Position].distance(entity2[Position]) < entity[BoundingCircle].radius + entity2[BoundingCircle].radius
  if result:
    let disc = (e1: entity[BoundingCircle].discriminant.addr, e2: entity2[BoundingCircle].discriminant.addr)
    if(;var g1 = entity[BoundingCircle].discriminant.group; var g2 = entity2[BoundingCircle].discriminant.group; g1+g2 > 0 and g1 == g2):
      return false
    for L in entity[BoundingCircle].discriminant.layers:
      if L in entity2[BoundingCircle].discriminant.layers: return true

debugDrawImpl(BoundingCircle):
  let pos = entity[Position].addr
  let radius = entity[BoundingCircle].addr
  R.circleRGBA pos.x.int16, pos.y.int16, radius.radius.int16, 255,0,0,255

msg_impl(Health, handleCollision) do(withEntity: PEntity):
  entity.takeDamage 1




## https://github.com/Araq/Nimrod/issues/431
echo "Number of unicast messages: ", numMessages, " should be about 10 "
echo "Number of components: ", numComponents, " should be more than 10 (compile with -d:debug to see all declared)"

proc randf* (precision = 10_000): float = random(precision)/precision  

proc randomizeVelocity*(ent: PEntity, length: float) =
  ent[Velocity].v = vectorForAngle(random(360).float.degrees2radians) * length
Velocity.setInitializer proc(x: PEntity) = randomizeVelocity(x, randf() * 5.0)

type TAsteroidRecord = tuple[
      radius: float, file: string, deathSpawner: proc(x: PEntity)]

proc newAsteroidRecord (
    radius = 10.0, file = "Rock24a_24x24.png", spawnOnDeath: openarray[int] = []): TAsteroidRecord
   
let asteroids = [
  newAsteroidRecord(radius = 12.0, file = "Rock24a_24x24.png"),
  newAsteroidRecord(radius = 12.0, file = "Rock24b_24x24.png"),
  newAsteroidRecord(radius = 16.0, file = "Rock32a_32x32.png"),
  newAsteroidRecord(radius = 20.0, file = "Rock48a_48x48.png", spawnOnDeath = [0,1,2]), #3 
  newAsteroidRecord(radius = 20.0, file = "Rock48b_48x48.png", spawnOnDeath = [3,3,2]),
  newAsteroidRecord(radius = 22.0, file = "Rock48c_48x48.png", spawnOnDeath = [3,3,2]), #5
  newAsteroidRecord(radius = 26.0, file = "Rock64a_64x64.png", spawnOnDeath = [4,5,3]),
  newAsteroidRecord(radius = 24.0, file = "Rock64b_64x64.png", spawnOnDeath = [6,5,4]), #7
  newAsteroidRecord(radius = 22.0, file = "Rock64c_64x64.png", spawnOnDeath = [7,6,5])
]

proc mkAsteroid(id = asteroids.len.random): var TEntity {.discardable.} =
  entities.add(em.newEntity(
    Position, Velocity, Health, Bounded, BoundingCircle, SimpleAnimation, Sprite, DeathCallback))
  let 
    idx = asteroids.len.random
    file = "asteroids" / asteroids[idx][1]
  template lastEnt : expr = entities[< entities.len]
  result = lastEnt
  
  result[BoundingCircle].radius = asteroids[idx].radius
  result[BoundingCircle].discriminant.layers.incl Layer1
  instanceSprite(result[Sprite], engy.render, file)
  result[DeathCallback].cb = asteroids[idx].deathSpawner

proc newAsteroidRecord (
    radius: float, file: string, spawnOnDeath: openarray[int]): TAsteroidRecord =
  result.radius = radius
  result.file = file
  let spawnOnDeath = @spawnOnDeath
  result.deathSpawner = proc(x: PEntity) =
    if entities.len < 100:
      for ast_id in spawnOnDeath: 
        let ast = mkAsteroid(ast_id).addr
        ast[].place_at(x[Position])
        ast[].randomizeVelocity 4.2


var the_mouse = newEntity(em, Position, BoundingCircle, Immortal, InputCB,
  DebugInfoDisp, CollisionHandler)
the_mouse[BoundingCircle].radius = 4.0
the_mouse[InputCB].handler = proc(x: PEntity; event: var TEvent; result: var bool) = 
  if event.kind == MouseMotion:
    let m = evMouseMotion(event)
    the_mouse[Position] = pos(m.x, m.y)
    result = true
the_mouse[CollisionHandler].handler = proc(self: PEntity; withEntity: PEntity) =
  self[DebugInfoDisp].result.setLen 0
  withEntity.debugStr self[DebugInfoDisp].result
  ## the info is drawn from DebugInfoDisp#debugDraw
entities.add the_mouse


for i in 0.. <10: mkAsteroid()
var player = newEntity(em, Position, Velocity, BoundingCircle, 
  Sprite, Immortal, Bounded, RollAnimation, Orientation, InputState,
  InputCB, Friction)
#player[BoundingCircle].discriminant.layers.incl Layer1
player[Sprite].instanceSprite engy, "ships/terran/hornet_54x54.png"
player[Friction].f = 0.98

player[InputCB].handler = proc(x: PEntity; event: var sdl2.TEvent; result: var bool) =
  case event.kind
  of keyDown:
    let k = evKeyboard(Event)
    case k.keysym.sym
    of K_Left:
      x.turn TTurn.Left
    of K_Right:
      x.turn TTurn.Right
    of K_Up:
      x.thrust TThrust.Forward
    of K_Down:
      x.thrust TThrust.Reverse
    
    else: nil
  of keyUP:
    let k = evKeyboard(event)
    case k.keysym.sym
    of K_Left:
      x.turn TTurn.Left,false
    of K_Right:
      x.turn TTurn.Right,false
    of K_UP:
      x.thrust TThrust.Forward,false
    of K_DOWN:
      x.thrust TThrust.Reverse,false
    else: nil
  else: nil


entities.add player

template eachEntity(body: stmt): stmt {.immediate.} =
  for e_id in 0 .. <len(entities):
    template entity: expr = entities[e_id]
    body

var running = true
block gameLoop:
  while running:
    while engy.pollHandle():
      case engy.evt.kind
      of QuitEvent:
        break gameLoop
      else:
        block handled_check:
          var r = false
          eachEntity:
            entity.handleEvent(engy.evt, r)
            if r: break handled_check
          
          if engy.evt.kind == KeyDown and EvKeyboard(engy.evt).keySym.sym == K_Escape:
            running = false
            break
    

    let dtf = engy.frameDeltaFLT()
    eachEntity: 
      entity.update dtf
    # check collisions
    let h = < entities.len
    for e1 in 0 .. <h:
      let e1_ptr = entities[e1].addr
      for e2 in e1+1 .. h:
        #if e2 > <entities.len: quit "Bad num $# max $#"% [$e2, $entities.len]
        if e1_ptr[].checkCollision(entities[e2]):
          #sendCollisions e1_d[], entities[e2]
          handleCollision e1_ptr[], entities[e2]
          handleCollision entities[e2], e1_ptr[]
    
    reap()
    
    engy.setDrawColor 0,0,0,255
    engy.clear
    
    eachEntity:
      entity.draw engy
      entity.debugDraw engy
    
    engy.present
  
engy.destroy
