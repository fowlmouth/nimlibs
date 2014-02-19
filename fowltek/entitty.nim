import algorithm, sequtils
import hashes, tables, typetraits, strutils, macros
from fowltek/pointer_arithm import alloc

when NimrodVersion < "0.9.3":
  {.error: "Entitty is written with features that require bleeding-edge Nimrod.".}
  # "Entitty is written with features that require at least Nimrod 0.9.2. Gonna need you to go ahead and upgrade, thanks.".}

# Defines available
#   PDomainIsReference - makes PDomain a ref type
#   EntittyAutoAddRequiredComponents - 

{.deadCodeElim: on.}

template Issue431(x): expr = (x + 30)
  # offset added to numbers affected by nimrod issue 431 (temp, unscaling hack)

#export typetraits.name
export typetraits, tables, strutils

type
  PComponentInfo* = ref object{.inheritable.}
    id*: int
    name*: string
    size*: int
    unicast_messages*: TTable[int, TWeightedUnicastFunc] ## unicast messages implemented by this component, with their weight
    multicast_messages*: TTable[int, pointer] 
    initializer*,destructor*: proc(E: PEntity)
    requiredComponents, conflictingComponents: seq[int]
    
  TWeightedUnicastFunc* = tuple[weight: int, func: pointer]
  
  PTypeInfo* = ptr TTypeInfo
  TTypeInfo* = object
    allComponents*: seq[PComponentInfo] # replacement for .components, unavailable components here are NIL
    offsets*: seq[int]
    instantiatedSize: int

    vtable*: seq[pointer]
    multicast*: seq[seq[pointer]] ## [msg_id][functions] 
    initializers*: seq[proc(entity: PEntity)] 
    destructors: seq[proc(entity: PEntity)]
    
    validType: bool
    whatsTheProblem: string

  PEntity* = var TEntity
  TEntity* = object
    typeInfo*: ptr TTypeInfo
    data*: PEntityData
    userdata*: pointer
    ID* : int
  PEntityData = ptr array[1024, byte]

  ## TODO rename to something fun like World or Place, Happenin_Spot, etc 
  TDomain* = object
    typeInfosTable: TTable[seq[int], PTypeInfo]

when defined(PDomainIsReference):
  type PDomain* = ref TDomain
else:
  type PDomain* = var TDomain

type
  E_InvalidComponent* = object of E_Base
  E_BadEntity* = object of E_Base
var
  allComponents* {.global.}: seq[PComponentInfo] = @[]
  messageTypes*: array[512, bool] ## true if the message is multicast
template isMulticastMsg*(id: expr[string]): bool = (bind messageTypes)[messageID(id)]

var numMessages* = 0
proc nextMessageID: int = 
  result = numMessages
  inc numMessages

var 
  messageIDs {.global.} = initTable[string, int](512)
proc getMessageID*(msg: string): int =
  let normalized = msg.normalize
  if messageIDs.hasKey(normalized):
    return messageIDs[normalized]
  result = nextMessageID()
  messageIDs[normalized] = result

proc messageID*(msg: expr[string]): int =
  var id {.global.} = getMessageID(msg)# nextMessageID()
  return id
  

var numComponents* = 0

template addUnicastMsg* (T: typedesc; M: expr[string]; weight: int, func: proc): stmt =
  let id = componentID(T)
  let msg_id = messageID(M)
  allComponents[id].unicastMessages[msg_id] = (weight, cast[pointer](func))
template addMulticastMsg* (T: Typedesc; M: expr[string]; func: proc): stmt =
  let comp = componentInfo(T)
  let msg_id = messageID(M)
  if comp.multicast_messages.hasKey(msg_id): 
    echo "wahh wahh you're overriding the definition of message ", M, " for ", comp.name
  comp.multicast_messages[msg_id] = cast[pointer](func)

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
      of routineNodes: 
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
  addNode newLetStmt(ident"msg_id", newCall("MessageID", msg_str.copyNimNode()))
  #  let comp = componentInfo(component)
  addNode newLetStmt(ident"comp", newCall("componentInfo", component.copy))
  
  template complainAboutOverriding(msgType): expr = parseExpr("""echo "Overriding the implementation of $1 message `$2` for ", comp.name""" %
    [msgType, $msg_str])
  
  var castexpr = newNimNode(nnkCast).add(ident"pointer")
  var this_lambda = newNimNode(nnkLambda)
  func.copyChildrenTo this_lambda
  this_lambda[3].insert 1, newNimNode(nnkIdentDefs).add(
    ident"entity", ident"PEntity", newEmptyNode())
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
        ident"weight", newIntLitNode(weight)),
      newNimNode(nnkExprColonExpr).add(
        ident"func", castExpr)
    )
    let thisBranch = newNimNode(nnkElse)
    branch.add thisBranch
    thisBranch.add newStmtList(
      parseExpr("""if comp.unicast_messages.hasKey(msg_id):
        echo "Overriding implementation of unicast message $1 for ", comp.name """ %
        $msg_str),
      newNimNode(nnkAsgn).add(
        lhs, rhs
    ) )


  result_body.add(branch)
  result = newBlockStmt(result_body.newStmtList)

  when defined(Debug):  echo repr(result)

proc nextComponentID*(T: typedesc): int = 
  result = numComponents
  inc numComponents
  allComponents.ensureLen(result+1)

  var comp = PComponentInfo(
    id: result,
    size: sizeof(T),
    name: name(T),
    unicast_messages: initTable[int, TWeightedUnicastFunc](4),
    multicast_messages: initTable[int, pointer](4),
    requiredComponents: @[],
    conflictingComponents: @[]
  )
  allComponents[result] = comp

  when defined(DEBUG):
    echo "Component #$# declared `$#`".format(comp.id, comp.name)


proc componentID*(T: typedesc): int =
  var id {.global.} = nextComponentID(T)
  return id
proc findComponent*(s: string): int = 
  for c in allComponents:
    if c.name == s:
      return c.id
  raise newException(E_InvalidComponent, "Component has not been declared: $#" % s)
proc componentID*(s: expr[string]): int =
  var id{.global.} = findComponent(s)
  return id

macro unicast*(func): stmt =
  when false:
    echo "Unicast macro accepted parameter: "
    echo treerepr(func[6])
  
  var f = func[6]
  
  let messageName = $ f.name.basename
  let isVoid = f.params[0].kind == nnkEmpty or (f.params[0].kind == nnkIdent and ($f.params[0]).toLower == "void")
  
  if not f[3].hasArgOfName("entity"):
    f[3].insert(1, newNimNode(nnkIdentDefs).add(
      ident"entity", ident"PEntity", newEmptyNode()))
  
  var f_sig_pragma = f.pragma.copyNimTree
  var f_new_pragma = f.pragma.copyNimTree
  f_sig_pragma.add_ident_if_absent "noConv"
  #f_sig_pragma.add_ident_if_absent "procvar"
  f_new_pragma.add_ident_if_absent "procvar"
  f.pragma = f_new_pragma
  
  var f_signature = newNimNode(nnkProcTy).add(
    f.params.copy,
    f_sig_pragma)
  
  var f_pointer = parse_expr("""entity.typeInfo.vtable[messageID("$#")]""" % messageName)
  
  var f_call_args = newSeq[PNimrodNode]()
  for i in 1 .. <len(f.params):
    #when defined(Debug): echo "f.params[$1] => $2".format(i, lispRepr(f.params[i]))
    #f_call_args.add(!! $ f.params[i][0])
    ## example here: 
    ## IdentDefs(Ident(!"entity"), Ident(!"PEntity"), Empty())  ## this one gets inserted
    ## IdentDefs(Ident(!"x"), Ident(!"y"), Ident(!"float"), Empty())  ## example of (x,y: float)
    for index in 0 .. f.params[i].len - 3:
      f_call_args.add(ident($ f.params[i][index]))
  
  var f_call = newCall(
    newNimNode(nnkCast).add(f_signature, f_pointer)
  ).add(f_call_args)
  
  f[6] = newStmtList( #    parseExpr("echo \"message ID is \", messageID(\""& messageName &"\")"),      parseExpr("""echo "vtable is $# len" % $len(entity.typeInfo.vtable)"""),
    newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
      parseExpr("not entity.typeInfo.vtable[messageID(\""& messageName &"\")].isNil"),
      if isVoid: f_call 
      else: newNimNode(nnkReturnStmt).add(f_call)
  ) ) )
  
  #f[6].insert(0, parseExpr("echo repr(entity)"))
  result = f#newStmtList(parseExpr("entitty_imports"), f)
  
  when defined(Debug):
    echo "Unicast macro result: "
    echo repr(result)

macro multicast*(func): stmt =
  #assert callsite is a forward declaration
  func.expectKind nnkDo
  func.body.expectKind nnkProcDef
  
  #check parameter for a combiner function used if the proc has a return type
  #do later
  
  var resultish = func.body.copy
  let msg_name = $ resultish.name.baseName
  
  if not resultish[3].hasArgOfName("entity"):
    resultish[3].insert 1, newNimNode(nnkIdentDefs).add(
      ident"entity", ident"PEntity", newNimNode(nnkEmpty))
  
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
  
  let callExpr = newCall(newNimNode(nnkCast).add(procTy, ident"msg")).add(call_args)
  
  let forStmt = newNimNode(nnkForStmt).add(
    ident"msg", newCall("items", parseExpr("runList[]")), newStmtList(callExpr))
  
  result_body.add newStmtList(forStmt)
  discard """ result_body.add newNimNode(nnkIfStmt).add(
    newNimNode(nnkElifBranch).add(
      parseExpr("not(runList[].isNil)"),
      newStmtList(forStmt))) """
  
  resultish.body = newStmtList(result_body)
  result = newStmtList(
    parseExpr("""isMulticastMsg("$1") = true""" % msg_name),
    resultish)
  
  when defined(Debug):
    echo "multicast result: ", treerepr(result)

proc ensureLen* [T](some: var seq[T]; len: int) {.inline.} =
  if some.len < len: some.setLen len

proc requiresComponent*(T: typedesc; requiredComponents: varargs[int, `componentID`]) =
  let id = componentID(T)
  let comp = allComponents[id]
  comp.requiredComponents.add requiredComponents
  comp.requiredComponents = distnct(comp.requiredComponents)
  #sort comp.requiredComponents, cmp[int] #not working??
  sort comp.requiredComponents, proc(x, y: int): int = cmp(x, y)

macro component*: stmt =
  ## type Foo {.component.} = object ...
  ## (when nimrod supports it)
  let cs = callsite()
  echo treerepr(cs)
  quit "component() macro is not implemented yet"

proc componentInfo*(T: typedesc): PComponentInfo =
  let id = componentID(T)
  return allComponents[id]

template unless*(cond; body: stmt): stmt =
  if not(cond): body

proc newTypeInfo* (components: seq[int]): PTypeInfo =
  let numThisComponents = components.len
  var errors: seq[string] = @[]
  if numThisComponents == 0: errors.add "Typeinfo created with no components!"
  
  result = alloc[TTypeInfo]()
  #newSeq result.components, numThisComponents
  newSeq result.allComponents, Issue431(numComponents)
  newSeq result.offsets, Issue431(numComponents)
  
  when defined(Debug):
    echo "typeinfo initialized for ", nummessages, " messages "#, repr(components)
  newSeq result.vtable, Issue431(numMessages)
  newSeq result.multicast, Issue431(numMessages)
  for i in 0 .. <Issue431(numMessages):
    newSeq result.multicast[i], 0
  newSeq result.initializers, 0
  newSeq result.destructors, 0
  
  var unicastWeights = newSeq[int](Issue431(numMessages))
  var requiredComponents = newSeq[int](0)
  
  var offs = 0
  #for index, component_id in pairs(components):
  for component_id in components:
    #result.components[index] = allComponents[component_id]
    result.allComponents[component_id] = allComponents[component_id]
    template thisComponent: expr =
      #when false: result.allComponents[component_id]
      #else: 
      #result.components[index]
      result.allComponents[component_id]
    
    result.offsets[component_id] = offs
    inc offs, thisComponent.size
    
    for message_id, msg in pairs(thisComponent.unicast_messages):
      template thisMessage: expr = result.vtable[message_id]
      
      if thisMessage.isNil or msg.weight > unicastWeights[message_id]:
        thisMessage = msg.func
        unicastWeights[message_id] = msg.weight
      
    for message_id, msg in pairs(thisComponent.multicast_messages):
      template thisMessageSeq: expr = result.multicast[message_id]
      #if thisMessageSeq.isNIL: thisMessageSeq.newSeq 0
      thisMessageSeq.add msg

    requiredComponents.add thisComponent.requiredComponents
    unless thisComponent.initializer.isNil:
      result.initializers.add thisComponent.initializer
    unless thisComponent.destructor.isNil:
      result.destructors.add thisComponent.destructor

  result.instantiatedSize = offs

  # collect required components
  for required_comp in distnct(requiredComponents):
    if result.allComponents[required_comp].isNIL:
      errors.add "requires component $#" % allComponents[required_comp].name

  result.validType = true
  if errors.len > 0:
    result.validType = false
    result.whatsTheProblem = errors.join(", ")

proc isValid* (ty: PTypeInfo): bool {.inline.} = ty.validType
proc getError* (ty:PTypeInfo):string{.inline.} = ty.whatsTheProblem

when defined(PDomainIsReference):
  proc newDomain*: PDomain = 
    result = PDomain(
      typeInfosTable: initTable[seq[int], PTypeinfo](512)
    )
else:
  proc newDomain*: TDomain = 
    result.typeInfosTable = initTable[seq[int],PTypeInfo](512)
  proc newEntityManager*: TDomain {.deprecated.} = newDomain()

proc getTypeInfo* (dom: PDomain; components: varargs[int, `componentID`]): PTypeInfo =
  var components = @components
  components.sort cmp[int]
  result = dom.typeInfosTable[components]
  if result.isNil:
    result = newTypeInfo(components)
    dom.typeInfosTable[components] = result

proc collectRequiredComponentIDs (ty: PTypeInfo): seq[int] =
  newSeq result, 0
  for c in ty.allComponents:
    if not c.isNil:  result.add c.requiredComponents
  result = result.distnct()

proc summary* (ty: PTypeInfo): string =
  let requiredComponents = ty.collectRequiredComponentIDs()
  
  #return "$1 components: $2 \L$3 required components: $4".format(
  #  ty.components.len, ty.components.map(proc(x: PComponentInfo): string = x.name).join(", "),
  #  requiredComponents.len, requiredComponents.map(proc(id: int): string = allComponents[id].name).join(", "))

proc instantiate (ty: PTypeInfo): PEntityData = 
  if not ty.validType:
    raise newException(E_BadEntity, "Cannot instantiate bad entity!\LReason: $#" %
      ty.whatsTheProblem)
  return cast[PEntityData](alloc0(ty.instantiatedSize))

proc newEntity*(typeinfo: PTypeInfo; initialize = true): TEntity =
  result = TEntity(typeInfo: typeInfo, data: typeInfo.instantiate)
  
  if initialize:
    # to optimize, could move this step to newTypeInfo() 
    for initializer in result.typeInfo.initializers:
      initializer result

proc newEntity*(manager: PDomain; components: varargs[int, `componentID`]): TEntity = 
  return manager.getTypeInfo(components).newEntity

proc destroy* (some: PEntity) {.inline.} =
  for f in some.typeinfo.destructors:
    f(some)
  dealloc some.data
  reset some

proc setInitializer*(component: typedesc, func: proc(x: PEntity)) =
  componentInfo(component).initializer = func
  when defined(Debug): 
    echo "set initializer for ", componentInfo(component).name  
proc setDestructor*(component: typedesc; func: proc(x: PEntity)) =
  componentInfo(component).destructor = func
  when defined(Debug):
    echo "set destructor for ", componentInfo(component).name

proc hasComponent*(entity: PEntity; T: Typedesc): bool {.
  inline.} = not entity.typeInfo.allComponents[componentID(T)].isNil

proc get*(entity: PEntity; T: typedesc): var T =
  let offset = entity.typeInfo.offsets[componentID(T)]
  return cast[ptr T](entity.data[offset].addr)[]
proc `[]`*(entity: PEntity; T: typedesc): var T {.inline.} = get(entity, T)
proc `[]=`*(entity: PEntity; ty: typedesc; val: ty) {.inline.} = (entity[ty]) = val



proc changeComponents* (dom: PDomain; ty: PTypeinfo; add, remove: varargs[int, `componentID`]): PTypeInfo =
  var comps: seq[int] = @[]
  
  for id, c in ty.allComponents:
    if not c.isNil:
      if id notin remove:
        # keep it
        comps.add id
    else:
      # does not have
      if id in add:
        comps.add id
  
  return dom.getTypeinfo(comps)


proc components* (types: varargs[int,`componentID`]): seq[int] =
  @types

proc changeComponents* (
    dom: PDomain; entity: PEntity; 
    add, remove: seq[int])=
  let ty = dom.changeComponents(entity.typeInfo, add=add, remove=remove) 
  var newEnt = ty.newEntity(false)
  
  for idx, c1 in entity.typeinfo.allComponents:
    let c2 = newEnt.typeInfo.allComponents[idx]
    # run destructor for types in c1 but not in c2
    # run initializer for new types (c2 and not c1)
    # copy data for existing types 
    if not(c1.isNil) and not(c2.isNil):
      copyMem(
        newEnt.data[ty.offsets[c1.id]].addr,
        entity.data[entity.typeinfo.offsets[c1.id]].addr,
        c1.size
      )
    elif c1.isNIl and not(c2.isNil):
      if not c2.initializer.isNil:
        c2.initializer(newEnt)
    elif not(c1.isNil) and c2.isNil:
      if not c1.destructor.isNil:
        c1.destructor(entity)

  swap newEnt.typeinfo, entity.typeInfo
  swap newEnt.data, entity.data
  dealloc newEnt.data
  
proc removeComponents* (dom: PDomain; entity: PEntity; remove: varargs[int, `componentID`]) =
  changeComponents(dom, entity, add= @[], remove= @remove)
proc addComponents* (dom: PDomain; entity: PEntity; add: varargs[int, `componentID`]) =
  changeComponents(dom, entity, add= @add, remove= @[])


