import fowltek/pointer_arithm, algorithm, sequtils
import hashes, tables, typetraits, strutils
import macros, fowltek/macro_dsl

when NimrodVersion != "0.9.1":
  {.error "Please to use the Live Nimrod off the Git Head. A thank you <3".}
  

type
  PComponentInfo* = ref object{.inheritable.}
    id: int
    name: string
    size: int
    unicast_messages: TTable[int, TWeightedUnicastFunc] ## unicast messages implemented by this component, with their weight
    multicast_messages: TTable[int, pointer] 
    initializer: proc(E: PEntity)
    requiredComponents, conflictingComponents: seq[int]
    
    
  TWeightedUnicastFunc* = tuple[weight: int, func: pointer]
  
  PTypeInfo* = ptr TTypeInfo
  TTypeInfo* = object
    components: seq[PComponentInfo]
    offsets: seq[int]
    instantiatedSize: int

    vtable: seq[pointer]
    multicast: seq[seq[pointer]] ## [msg_id][functions] 
    
    validType: bool
    whatsTheProblem: string

  PEntity* = var TEntity
  TEntity* = object
    typeInfo: ptr TTypeInfo
    data: PEntityData
  PEntityData = ptr array[0.. <1024, byte]

  ## TODO rename to something fun like World or Place, Happenin_Spot, etc 
  TEntityManager = object
    typeInfosTable: TTable[seq[int], PTypeInfo]


  E_InvalidComponent = object of E_Base
var
  allComponents: seq[PComponentInfo] = @[]
  messageTypes: array[0.. <512, bool] ## true if the message is multicast
template isMulticast(id: expr[string]): bool = (bind messageTypes)[messageID(id)]

template idCounter(name, varname): stmt =
  var varname* {.inject, global.} = 0
  proc `next name`: int =
    result = varname
    inc varname
idCounter MessageID, numMessages
idCounter ComponentID, numComponents



macro msg_impl* : stmt {.immediate.} =
  # Implements a message for a component
  # 
  # Arguments:
  #   component: typedesc, 
  #   message: static[string],
  #   weight: int = 0,
  #   function: proc(arg1: TArg1, ..)
  #
  # Usage:
  #   msg_impl(THealthComponent, "TakeDamage") do (damage: int):
  #     # `entity: PEntity` is injected in the params
  #     entity[THealthComponent].hp -= damage
  #     if entity[THealthComponent].hp < 0:
  #       entity.die
  #
  
  let 
    cs = callsite()
  if len(cs) > 5 or len(cs) < 4:
    quit "Malformed arguments for msg_impl()"
  
  let
    component = cs[1]
    msg = cs[2]
  var 
    func: PNimrodNode
    weight = 0
  
  ## hack: if you invoke do with no parameters just the stmt list is sent. 
  template getRealFunction(fromNode): expr =
    block:
      var result: PNimrodNode
      case fromNode.kind
      of nnkStmtList:
        result = newProc(procType = nnkDo, body = fromNode)
      of macro_dsl.procLikeNodes: 
        result = fromNode
      else:
        quit "Invalid parameter kind: $# \n $#" % [$fromNode.kind, lispRepr(fromNode)]
      result
  
  if len(cs) == 4:
    func = getRealFunction(cs[3])
  else:
    weight = cs[3].intval.int
    func = getRealFunction(cs[4])
  
  let msg_str = newStrLitNode($msg)
  
  ## needs to do
  # block:
  var result_body = newSeq[pnimrodnode](0)
  template addNODE(node): expr =  result_body.add(node)
  template addEXPR(msg): expr =  addNODE parseExpr(msg)
  
  #  let msg_id = MessageID(`msg as a string literal`)
  addNode newLetStmt(!!"msg_id", newCall("MessageID", msg_str.copyNimNode()))
  #  let comp = componentInfo(component)
  addNode newLetStmt(!!"comp", newCall("componentInfo", component.copy))
  
  template complainAboutOverriding(msgType): expr = parseExpr("""echo "Overriding the implementation of $1 message `$2` for ", comp.name""" %
    [msgType, $msg_str])
  
  var castexpr = newNimNode(nnkCast).add(!!"pointer")
  var this_lambda = newNimNode(nnkLambda)
  func.copyChildrenTo this_lambda
  this_lambda[3].insert 1, newNimNode(nnkIdentDefs).add(
    !!"entity", !!"PEntity", newEmptyNode())
  castexpr.add this_lambda
  
  let branch = newNimNode(nnkIfStmt)
  
  block:
    # if messageTypes[msg_id]: #multicast
    let thisBranch = newNimNode(nnkElifBranch)
    branch.add thisBranch
    thisBranch.add parseExpr("messageTypes[msg_id]")
    let thisBody = newStmtList()
    thisBranch.add thisBody
    
    #  if comp.multicast_messages.hasKey(msg_id):
    #   echo "Overriding implementation of ##msg## for ", comp.name
    #  comp.multicast_messages[msg_id] = cast[pointer](proc = ...)
    thisBody.add(
      newNimNode(nnkIfStmt).add(
        newNimNode(nnkElifBranch).add(
          parseExpr("comp.multicast_messages.hasKey(msg_id)"),
          complainAboutOverriding("multicast"))),
      newNimNode(nnkAsgn).add(
        parseExpr("comp.multicast_messages[msg_id]"), 
        castExpr))
    
  block:
    let lhs = parseExpr("comp.unicast_messages[msg_id]")
    # (weight: this_weight, func: cast[pointer](..))  ## (tuple constructor)
    let rhs = newNimNode(nnkPar).add(
      newNimNode(nnkExprColonExpr).add(
        !!"weight", newIntLitNode(weight)),
      newNimNode(nnkExprColonExpr).add(
        !!"func", castExpr)
    )
    let thisBranch = newNimNode(nnkElse)
    branch.add thisBranch
    thisBranch.add newStmtList(
      parseExpr("""if comp.unicast_messages.hasKey(msg_id):
        echo "Overriding implementation of unicast message $1 for ", comp.name """ %
        $msg_str),
      newNimNode(nnkAsgn).add(
        lhs, rhs))
    
  
  result_body.add(branch)
  result = newBlockStmt(label = nil, statements = result_body)
  
  when defined(Debug):  echo repr(result)
  
proc componentID(T: typedesc): int =
  var id {.global.} = nextComponentID()
  return id
proc componentID(s: string): int = 
  for c in allComponents:
    if c.name == s:
      return c.id
  raise newException(E_InvalidComponent, "Component has not been declared: $#" % s)

proc messageID(msg: expr[string]): int =
  var id {.global.} = nextMessageID()
  return id


macro unicast*(func): stmt =
  when false:
    echo "Unicast macro accepted parameter: "
    echo treerepr(func[6])
  var f = func[6]
  let messageName = $ f.name.basename
  if not f[3].hasArgumentNamed("entity"):
    f[3].insert(1, newNimNode(nnkIdentDefs).add(
      !!"entity", !!"PEntity", newEmptyNode()))
  
  var f_sig_pragma = f.pragma.copy
  f_sig_pragma.add_ident_if_absent "noConv"
  
  var f_signature = newNimNode(nnkProcTy).add(
    f.params.copy(),
    f_sig_pragma)
  
  var f_pointer = parse_expr("""entity.typeInfo.vtable[messageID("$#")]""" % messageName)
  
  var f_call_args = newSeq[PNimrodNode]()
  for i in 1 .. <len(f.params):
    f_call_args.add(!! $ f.params[i][0])
  
  var f_call = newCall(
    newNimNode(nnkCast).add(f_signature, f_pointer)
  ).add(f_call_args)
  
  f[6] = newStmtList( #    parseExpr("echo \"message ID is \", messageID(\""& messageName &"\")"),      parseExpr("""echo "vtable is $# len" % $len(entity.typeInfo.vtable)"""),
    newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
      parseExpr("not entity.typeInfo.vtable[messageID(\""& messageName &"\")].isNil"),
      if f.params[0].kind == nnkEmpty or f.params[0].kind == nnkIdent and $f.params[0] == "void": f_call 
      else: newNimNode(nnkReturnStmt).add(f_call)
    ) )
  )
  
  ##
  #f[6].insert(0, parseExpr("echo repr(entity)"))
  
  when defined(Debug):
    echo "Unicast macro result: "
    echo repr(f)
  return f

macro multicast*(func): stmt {.immediate.} =
  #assert callsite is a forward declaration
  func.expectKind nnkProcDef
  
  #check parameter for a combiner function used if the proc has a return type
  #do later
  
  var resultish = func.copy
  let msg_name = $ resultish.name.baseName
  
  if not resultish[3].hasArgumentNamed("entity"):
    resultish[3].insert 1, newNimNode(nnkIdentDefs).add(
      !!"entity", !!"PEntity", newNimNode(nnkEmpty))
  
  #do what {.unicast.} does with a different body (fooMulti())
  var result_body = newseq[PNimrodNode](0)
  
  #let runlist = e.typeInfo.multicast[messageID("foo")].addr
  result_body.add parseExpr(
    """let runList = entity.typeInfo.multicast[messageID("$1")].addr """ %
      msg_name)
  
  #if not(runList[].isNil:
  #  for msg in items(runList[]):
  #    cast[proc(..){.noconv.}](msg)(arg1, arg2)
  
  var f_sig_pragma = resultish.pragma.copy
  f_sig_pragma.add_ident_if_absent "noConv"
  
  let procTy = newNimNode(nnkProcTy).add(
    resultish.params.copy, f_sig_pragma)
  
  var call_args = newSeq[PNimrodNode](0)
  for i in 1 .. <len(resultish.params): call_args.add(resultish.params[i][0])
  
  let callExpr = newCall(newNimNode(nnkCast).add(procTy, !!"msg")).add(call_args)
  
  let forStmt = newNimNode(nnkForStmt).add(
    !!"msg", newCall("items", parseExpr("runList[]")), newStmtList(callExpr))
  
  result_body.add newNimNode(nnkIfStmt).add(
    newNimNode(nnkElifBranch).add(
      parseExpr("not(runList[].isNil)"),
      newStmtList(forStmt)))
  
  resultish.body = newStmtList(result_body)
  return newStmtList(
    parseExpr("""isMulticast("$1") = true""" % msg_name),
    resultish)

proc ensureLen* [T](some: var seq[T]; len: int) {.inline.} =
  if some.len < len: some.setLen len

proc requiresComponent*(T: typedesc; requiredComponents: varargs[int, `componentID`]) =
  let id = componentID(T)
  let comp = allComponents[id]
  comp.requiredComponents.add requiredComponents
  comp.requiredComponents = distnct(comp.requiredComponents)
  #sort x, cmp[int] #not working??
  sort comp.requiredComponents, proc(x, y: int): int = cmp(x, y)

proc defComponent* (T: typedesc;
    name: string = nil) =
  let id = ComponentID(T)
  allComponents.ensureLen id+1
  
  var thisComponent = allComponents[id]
  if not thisComponent.isNil:
    echo "Overriding component definition for ", thisComponent.name, " with ", name(T)
    quit 1

  var comp = PComponentInfo(
    id: id,
    size: sizeof(T),
    name: name(T),
    unicast_messages: initTable[int, TWeightedUnicastFunc](4),
    multicast_messages: initTable[int, pointer](4),
    requiredComponents: @[],
    conflictingComponents: @[]
  )
  allComponents[id] = comp

  if not name.isNil:
    comp.name = name


proc componentInfo*(T: typedesc): PComponentInfo =
  let id = componentID(T)
  return allComponents[id]


proc newTypeInfo* (components: seq[int]): PTypeInfo =
  result = alloc[TTypeInfo]()
  result.components = newSeq[PComponentInfo](components.len)
  result.offsets = newSeq[int](allcomponents.len)
  echo "typeinfo initialized for ", nummessages, " messages"
  
  newSeq result.vtable, numMessages+10
  newSeq result.multicast, numMessages+10
  var unicastWeights = newSeq[int](numMessages+10)
  
  var offs = 0
  for index, component_id in pairs(components):
    result.components[index] = allComponents[component_id]
    result.offsets[component_id] = offs
    inc offs, result.components[index].size
    for idx, msg in pairs(result.components[index].unicast_messages):
      if msg.weight > unicastWeights[idx] or result.vtable[idx].isNil:
        result.vtable[idx] = msg.func
        unicastWeights[idx] = msg.weight
    for idx, msg in pairs(result.components[index].multicast_messages):
      if result.multicast[idx].isNil:
        newSeq result.multicast[idx], 0
      result.multicast[idx].add msg
  
  result.instantiatedSize = offs


proc newEntityManager*: TEntityManager = 
  result.typeInfosTable = initTable[seq[int],PTypeInfo](512)

proc getTypeInfo* (manager: var TEntityManager; components: seq[int]): PTypeInfo =
  ## get the typeinfo record for a set of components
  result = manager.typeInfosTable[components]
  if result.isNil:
    #echo "Creating new typeinfo."
    result = newTypeInfo(components)
    manager.typeInfosTable[components] = result


proc instantiate (ty: PTypeInfo, entity: PEntity): PEntityData = cast[PEntityData](alloc0(ty.instantiatedSize))

proc newEntity*(manager: var TEntityManager; components: varargs[int, `componentID`]): TEntity =
  var components = @components
  components.sort cmp[int]
  result.typeInfo = manager.getTypeInfo(components)
  result.data = result.typeInfo.instantiate(result)
  # to optimize, could move this step to newTypeInfo() 
  for comp in result.typeInfo.components: 
    if comp.isNil or comp.initializer.isNil: continue
    comp.initializer(result)

proc hasComponent*(entity: PEntity; T: Typedesc): bool =
  let id = componentID(T)
  for c in entity.typeInfo.components:
    if c.id == id: return true
    if c.id > id: return false

proc get*(entity: PEntity; T: typedesc): var T =
  let offset = entity.typeInfo.offsets[componentID(T)]
  return cast[ptr T](entity.data[offset].addr)[]
proc `[]`*(entity: PEntity; T: typedesc): var T {.inline.} = get(entity, T)
proc `[]=`*(entity: PEntity; ty: typedesc; val: ty) {.inline.} = (entity[ty]) = val

when isMainModule:
  import math
  randomize()
  import fowltek/vector_math
  import fowltek/sdl2/engine
  import_all_sdl2_modules

  type ## Components
    TVector2f = TVector2[float]
    
    TPos = TVector2[float]
    TVel = object
      v: TVector2[float]
    THealth = object
      hp, max: int
    TBoundingBox = tuple[
      centerX,centerY: float,
      width,height: float]
    TSpriteInstance = object
      sprite: ptr TSprite
      rect: TRect 

    TSprite = object
      file: string
      tex: PTexture
      defaultRect: sdl2.TRect


  template ff(some: float, precision = 3): string = formatFloat(some, ffDecimal, precision)

  proc `$`*(some: TSpriteInstance): string = (
    if some.sprite.isNil: "nil"  else: some.sprite.file )
  
  proc `$`*(some: TVector2[float]): string = "($1,$2)".format(ff(some.x), ff(some.y))
  
  proc pos*[A: TNumber](x, y: A): TPos =
    result.x = x.float
    result.y = y.float
  
  defcomponent TPos, "Position"
  componentInfo(TPos).initializer = proc(entity: PEntity) =
    entity[TPos].x = random(640).float
    entity[TPos].y = random(480).float
  defComponent THealth, "Health"
  componentInfo(THealth).initializer = proc(entity: PEntity) =
    entity[THealth] = THealth(hp: 100, max: 100)
  
  defComponent TBoundingBox, "Bounding Box"
  defComponent TVel, "Velocity"
  defComponent TSpriteInstance, "Sprite"
  
  type
    TBounded = object
      rect: sdl2.TRect
      checkEnt: proc(entity: PEntity; bounds: var TBounded)
  
  defComponent TBounded
  #TBounded.requiresComponent TPos, TVel
  
  proc right*(some: ptr TRect): cint {.inline.} = some.x + some.w
  proc bottom*(some: ptr TRect): cint {.inline.} = some.y + some.h
  
  proc setToroidal(bounds: var TBounded) =
    bounds.checkEnt = proc(entity: PEntity; bounds: var TBounded) =
      #discard """
      let pos = entity[TPos].addr
      let bounds = bounds.rect.addr
      if pos.x.cint < bounds.x:
        pos.x = bounds.right.float
      elif pos.x.cint > bounds.right:
        pos.x = bounds.x.float
      if pos.y.cint < bounds.y:
        pos.y = bounds.bottom.float
      elif pos.y.cint > bounds.bottom:
        pos.y = bounds.y.float
      # """ 
  proc toroidalBounds(x, y, w, h: int): TBounded =
    result.rect = rect(x.cint, y.cint, w.cint, h.cint)
    result.setToroidal
 
  proc setBouncy(bounds: var TBounded) =
    bounds.checkEnt = proc(entity: PEntity; bounds: var TBounded) =
      let pos = entity[TPos].addr  
      let vel = entity[TVel].v.addr
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
  proc bouncyBounds(x, y, w, h: int): TBounded =
    result.rect = rect(x.cint, y.cint, w.cint, h.cint)
    result.setBouncy
       
 
  proc takeDamage* (amount: int) {.unicast.}
  
  proc debugStr* (collection: var seq[string]) {.multicast.}
  proc update*(dt: float){.multicast.}
  
  msg_impl(TVel, update) do(dt: float):
    entity[TPos] += entity[TVel].v
  
  msg_impl(TBounded, update) do (dt: float):
    entity[TBounded].checkEnt entity, entity[TBounded]
  
  
  template debugStrImpl(ty): stmt =
    msg_impl(ty, debugStr) do(result: var seq[string]):
      result.add "$#: $#".format(ComponentInfo(ty).name, entity[ty])
  debugStrImpl(THealth)
  debugStrImpl(TPos)
  debugStrImpl(TVel)
  debugStrImpl(TSpriteInstance)
  debugStrImpl(TBoundingBox)
  
  proc debugStr*(entity: PEntity): seq[string] {.inline.}=
    result = @[]
    entity.debugStr(result)
  
  var EM = newEntityManager()
  var entities = newSeq[TEntity](0)
  
  var reaper: tuple[souls: seq[int]]
  reaper.souls = @[]
  proc reap =
    if len(reaper.souls) > 0:
      reaper.souls.sort cmp[int]
      for i in countdown(<len(reaper.souls), 0):
        entities.del reaper.souls[i]
      reaper.souls.setLen 0
  
  proc die(entity: PEntity) =
    let e = entity.addr
    for i in 0 .. < entities.len:
      if e == entities[i].addr:
        reaper.souls.add i
        return
  
  msg_impl(THealth, takeDamage) do(amount: int) :
    entity[THealth].hp -= amount
    if entity[THealth].hp <= 0:
      entity.die()
  
  
  proc debugDraw(R: sdl2.PRenderer) {.multicast.}
  msg_impl(TPos, debugDraw) do(R: PRenderer) :
    #stringRGBA(R, entity[TPos].x.int16, entity[TPos].y.int16, $entity[TPos],
    #  255,0,0,255)
    let p = entity[TPos]
    let s = $p #entity.debugStr
    R.stringRGBA(p.x.int16, p.y.int16, s, 255,0,0,255)
  
  proc create_a_bunch_of_ents(num = 10) =
    ## component ids are 0 - 5
    var ids = newSeq[int](0)
    for n in 0 .. < num:
      for i in 0 .. random(4):
        ids.add random(5)
      entities.add(em.newEntity(distnct(ids)))
      ids.setLen 0
  
  discard """ 
  create_a_bunch_of_ents()
  
  # see what some of them have..
  for i in 0 .. <4:
    let id = random(<len(entities))
    echo "entity #",id, ": ", entities[id].debugStr.join(", ")
  """
  
  var engy = newSdlEngine()
  
  block:
    let winsize = vec2[int](engy.window.getSize.x, engy.window.getSize.y)
    componentInfo(TBounded).initializer = proc(entity: PEntity) = entity[TBounded] = ToroidalBounds(0, 0, winSize.x, winSize.y)
  
  
  type
    TBoundingCircle = object
      radius: float
  defComponent TBoundingCircle
  proc checkCollision*(entity2: PEntity): bool {.unicast.} 
  msg_impl(TBoundingCircle, checkCollision) do(entity2: PEntity) -> bool:
    return entity[TPos].distance(entity2[TPos]) < entity[TBoundingCircle].radius + entity2[TBoundingCircle].radius
  msg_impl(TBoundingCircle, debugDraw) do(R: PRenderer):
    let pos = entity[TPos].addr
    let radius = entity[TBoundingCircle].addr
    R.circleRGBA pos.x.int16, pos.y.int16, radius.radius.int16, 255,0,0,255
  
  proc handleCollision*(withEntity: PEntity) {.unicast.}
  msg_impl(THealth, handleCollision) do(withEntity: PEntity):
    entity.takeDamage 1
  
  ## https://github.com/Araq/Nimrod/issues/431
  echo "Number of unicast messages: ", numMessages, " should be 2"
  echo "Number of components: ", numComponents
  
  proc deg2rad* (some: int): float {.inline.} = some.float * pi / 180.0
  
  proc vectorForAngle(radians: float): TVector2f {.inline.} = (x: cos(radians), y: -sin(radians))
  
  proc randomize (some: var TVel, within: float) {.inline.} =
    let angle = random(360).deg2rad
    
    some.v.x = cos(angle) * within
    some.v.y = -sin(angle) * within
  
  proc mkAsteroid*(size = 8 .. 20) =
    entities.add(em.newEntity(TPos, TVel, THealth, TBounded, TBoundingCircle))
    template lastEnt : expr = entities[< entities.len]
    lastEnt[TVel].randomize 2.0
    lastEnt[TVel].v.x = 1.0
    lastEnt[TBoundingCircle].radius = random(size).float
    if random(10) == 0: lastEnt[TBounded].setBouncy
  
  for i in 0.. <30: mkAsteroid()
  
  template eachEntity(body: stmt): stmt {.immediate.} =
    for e_id in 0 .. <len(entities):
      template entity: expr = entities[e_id]
      body

  var running = true
  while running:
    if engy.pollHandle():
      case engy.evt.kind
      of QuitEvent:
        break
      else: nil
    
    let dtf = engy.frameDeltaFLT()
    eachEntity: 
      entity.update dtf
    # check collisions
    let h = < entities.len
    for e1 in 0 .. <h:
      let e1_d = entities[e1].addr
      for e2 in e1+1 .. h:
        if e2 > <entities.len: quit "Bad num $# max $#"% [$e2, $entities.len]
        if e1_d[].checkCollision(entities[e2]):
          e1_d[].handleCollision(entities[e2])
          entities[e2].handleCollision(e1_d[])
    
    reap()
    
    engy.setDrawColor 0,0,0,255
    engy.clear
    
    eachEntity:
      entity.debugDraw engy
    
    engy.present
    
  engy.destroy

