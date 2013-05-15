import fowltek/pointer_arithm, algorithm, sequtils
import hashes, tables, typetraits, strutils
import macros, fowltek/macro_dsl

when NimrodVersion != "0.9.1":
  {.error "Please to use the Live Nimrod off the Git Head. A thank you <3".}

const
  Issue431_Offset = 30 # offset added to numbers affected by nimrod issue 431 (temp, unscaling hack)  

template Entitty_Imports* : stmt {.dirty.} =
  ## Import entitty's required libraries, call this before you declare your components.
  when not(defined(tables)): import tables
  when not(defined(typetraits)): import typetraits

type
  PComponentInfo* = ref object{.inheritable.}
    id*: int
    name*: string
    size*: int
    unicast_messages*: TTable[int, TWeightedUnicastFunc] ## unicast messages implemented by this component, with their weight
    multicast_messages*: TTable[int, pointer] 
    initializer: proc(E: PEntity)
    requiredComponents, conflictingComponents: seq[int]
    
  TWeightedUnicastFunc* = tuple[weight: int, func: pointer]
  
  PTypeInfo* = ptr TTypeInfo
  TTypeInfo* = object
    components: seq[PComponentInfo]
    offsets: seq[int]
    instantiatedSize: int

    vtable*: seq[pointer]
    multicast*: seq[seq[pointer]] ## [msg_id][functions] 
    
    validType: bool
    whatsTheProblem: string

  PEntity* = var TEntity
  TEntity* = object
    typeInfo*: ptr TTypeInfo
    data: PEntityData
  PEntityData = ptr array[0.. <1024, byte]

  ## TODO rename to something fun like World or Place, Happenin_Spot, etc 
  TEntityManager = object
    typeInfosTable: TTable[seq[int], PTypeInfo]


  E_InvalidComponent* = object of E_Base
  E_BadEntity* = object of E_Base
var
  allComponents*: seq[PComponentInfo] = @[]
  messageTypes*: array[0.. <512, bool] ## true if the message is multicast
template isMulticastMsg*(id: expr[string]): bool = (bind messageTypes)[messageID(id)]

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
    thisBranch.add parseExpr("entitty.messageTypes[msg_id]")
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
  
proc componentID*(T: typedesc): int =
  var id {.global.} = nextComponentID()
  return id
proc findComponent(s: string): int = 
  for c in allComponents:
    if c.name == s:
      return c.id
  raise newException(E_InvalidComponent, "Component has not been declared: $#" % s)
proc componentID*(s: expr[string]): int =
  var id{.global.} = findComponent(s)
  return id

proc messageID*(msg: expr[string]): int =
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
    parseExpr("""isMulticastMsg("$1") = true""" % msg_name),
    resultish)

proc ensureLen* [T](some: var seq[T]; len: int) {.inline.} =
  if some.len < len: some.setLen len

proc requiresComponent*(T: typedesc; requiredComponents: varargs[int, `componentID`]) =
  let id = componentID(T)
  let comp = allComponents[id]
  comp.requiredComponents.add requiredComponents
  comp.requiredComponents = distnct(comp.requiredComponents)
  #sort comp.requiredComponents, cmp[int] #not working??
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
  
  when defined(DEBUG):
    echo "Component #$# declared `$#`".format(comp.id, comp.name)


proc componentInfo*(T: typedesc): PComponentInfo =
  let id = componentID(T)
  return allComponents[id]


proc newTypeInfo* (components: seq[int]): PTypeInfo =
  let numThisComponents = components.len
  assert numThisComponents > 0, "Typeinfo created with no components!"
  
  result = alloc[TTypeInfo]()
  result.components = newSeq[PComponentInfo](numThisComponents)
  result.offsets = newSeq[int](numComponents+Issue431_Offset)
  
  echo "typeinfo initialized for ", nummessages, " messages ", repr(components)
  newSeq result.vtable, numMessages+Issue431_Offset
  newSeq result.multicast, numMessages+Issue431_Offset
  var unicastWeights = newSeq[int](numMessages+Issue431_Offset)
  var requiredComponents = newSeq[int](0)
  
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

    requiredComponents.add result.components[index].requiredComponents

  result.instantiatedSize = offs

  result.validType = true

  # collect required components
  var errors = newSeq[string](0)
  for required_comp in distnct(requiredComponents):
  
    block componentCheck:
     
      for my_comp in result.components:
        if my_comp.id == required_comp:
          break componentCheck
        elif my_comp.id > required_comp:
          break
      errors.add "requires component $#" % allComponents[required_comp].name


  if errors.len > 0:
    result.validType = false
    result.whatsTheProblem = errors.join(", ")



proc newEntityManager*: TEntityManager = 
  result.typeInfosTable = initTable[seq[int],PTypeInfo](512)

proc getTypeInfo* (manager: var TEntityManager; components: seq[int]): PTypeInfo =
  ## get the typeinfo record for a set of components
  result = manager.typeInfosTable[components]
  if result.isNil:
    #echo "Creating new typeinfo."
    result = newTypeInfo(components)
    manager.typeInfosTable[components] = result


proc summary* (ty: PTypeInfo): string = 
  var requiredComponents = newseq[int](0)
  for c in ty.components: requiredComponents.add(c.requiredComponents)
  requiredComponents = requiredComponents.distnct
  
  return "$1 components: $2 \L$3 required components: $4".format(
    ty.components.len, ty.components.map(proc(x: PComponentInfo): string = x.name).join(", "),
    requiredComponents.len, requiredComponents.map(proc(id: int): string = allComponents[id].name).join(", "))

proc instantiate (ty: PTypeInfo): PEntityData = 
  if not ty.validType:
    raise newException(E_BadEntity, "Cannot instantiate bad entity!\LReason: $#\LTypeinfo: $#".format(
      ty.whatsTheProblem, ty.summary)) 
  return cast[PEntityData](alloc0(ty.instantiatedSize))

proc newEntity*(typeinfo: PTypeInfo): TEntity =
  result.typeInfo = typeInfo
  result.data = typeInfo.instantiate
  # to optimize, could move this step to newTypeInfo() 
  for comp in result.typeInfo.components: 
    if comp.isNil or comp.initializer.isNil: continue
    comp.initializer(result)

proc newEntity*(manager: var TEntityManager; components: varargs[int, `componentID`]): TEntity =
  var components = @components
  components.sort cmp[int]
  return manager.getTypeInfo(components).newEntity

proc destroy* (some: PEntity) {.inline.} =
  dealloc some.data
  reset some.data

proc setInitializer*(component: typedesc, func: proc(x: PEntity)) =
  componentInfo(component).initializer = func  

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
