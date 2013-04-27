
import tables, macros, strutils
import fowltek/tmaybe, fowltek/macro_dsl


type
  CBase* = object of TObject ## Base component type
  TEntity* = object of TObject ## Base entity type

type
  ComponentImpl = ref object
    name: string
    field: TMaybe[string]
    parent: TMaybe[string]
    children: seq[string]
    
    requirements: TMaybe[seq[string]]
    data: TMaybe[PNimrodNode]
    methods: TTable[string, PNimrodNode]
    needsRef, inheritable: bool 
  EntityRecord = ref object
    name: string
    fields: TTable[string, ComponentImpl]
var 
  entities{.compileTime.} =initOrderedTable[string, EntityRecord](64)
  components{.compiletime.} = initOrderedTable[string, ComponentImpl](64)


proc getField (some: ComponentImpl): string {.compiletime.}=
  #there has to be a field set somewhere in a components inheritance
  if some.field: return some.field.val
  
  var c = some
  while not(c.field):
    if not(c.parent):
      echo "Ran out of parents to search for a field name for component ", some.name
      quit 1
    c = components[c.parent.val]
  some.field = c.field
  return c.field.val

macro defComponent*(comp_name): stmt {.immediate.}=
  ## Define a component. Usage: defComponent(COMPONENT_NAME, Arg1 = X, Arg2 = Y, ..)
  ## Arguments:
  ##   field = foo  # Denotes how the component is stored in an entity, must therefore be unique.
  ##                  No checks are made for this currently
  ##   parent = SomeComponent # A component must have a parent or a field set
  ##   
  ##   data = ..  # What data is stored in the component, can be a tuple that is transformed to an 
  ##                object type or it can be some other type, if it is some other type
  ##                the component is not inheritable. If this type _is_ inherited, it 
  ##                will be used as a ref type to utilize Nimrod's MULTIPLE DISPATCH 
  ##   requires = field   OR
  ##   requires = [field1, field2]  # states that an entity using this component must atleast 
  ##                have these fields available
  
  let cs = callsite()
  let name = $comp_name
  var cmp = ComponentImpl(name: name, methods: initTable[string, PNimrodNode](8))
  echo "new component ", name
  
  template compError(msg) =
    echo "Problem with component `",name,"`: ", msg
  
  for i in 2 .. <len(cs):
    let this = cs[i]
    this.expectKind nnkExprEqExpr
    let 
      name = $this[0]
      v = this[1]
    case name.toLower
    of "field":
      cmp.field = Just($v)
    of "data":
      cmp.data = Just(v)
    of "parent":
      let parent =  $v
      if not components[parent].inheritable:
        echo "Component `$#` trying to inherit from final component `$#`!"
      else:
        cmp.parent = Just(parent)
        #components[parent].needsRef = true
        components.mget(parent).needsRef = true
        if components.mget(parent).children.isNil:
          components.mget(parent).children = @[cmp.name]
        else:
          components.mget(parent).children.add cmp.name
    of "requires":
      if v.kind == nnkIdent:
        cmp.requirements = Just(@[ $v ])
      elif v.kind == nnkBracket:
        cmp.requirements = Just(newSeq[string](len(v)))
        for i in 0 .. <len(v):
          cmp.requirements.val[i] = $v[i]
      else:
        echo "Unexpected parameter for component requirements: ", repr(v)
    else:
      compError "Unrecognized argument: "&name
  
  if cmp.parent and not(cmp.field):
    echo "Setting component field to parent field."
    cmp.field = components[cmp.parent.val].field
  
  if cmp.parent:
    cmp.needsRef = true 
  
  if not(cmp.field) and cmp.data:
    comperror "Data associated with no field to store it in!"
  else:
    cmp.inheritable = true
  
  if not(cmp.parent) and cmp.data and cmp.data.val.kind != nnkTupleTy:
    ## this component is a wrapper for another type, and not inheritable
    cmp.inheritable = false
  
  ## CONCERN: previously this was right after the var cmp = .. line, 
  ## retrieving it was bringing a componentImpl with only the string set
  echo "components.len: ", components.len()
  echo name
  components[name] = cmp

macro defEntity*(ent_name): stmt {.immediate.} =
  let cs = callsite()
  let naaame = $ent_name
  var ent = EntityRecord(name: naaame, fields: initTable[string, ComponentImpl](8)) 
  
  echo "new entity ", naaame
  var cmps = newSeq[ComponentImpl](0)
  var cmpFields = newSeq[string](0)
  
  for i in 2 .. <len(cs):
    let arg = cs[i]
    if arg.kind != nnkIdent:
      echo "Invalid argument: `", repr(arg), "`"
      continue
    
    let component = components[$arg]
    if not(component.isNil):
      cmps.add component
      if component.field:
        cmpFields.add component.field.val
      
    else:
      echo "No such component registered: ", $arg
  
  
  for component in cmps:
    ## check requirements
    if component.requirements:
      for required_field in component.requirements.val:
        if required_field notin cmpFields:
          echo "Component ", component.name, " missing required field ", required_field
          quit 1
    
    
    let field = component.field
    if not field: 
      echo "Component has no field, skipped: ", component.name
      continue 
    
    if not ent.fields.hasKey(field.val):
      ent.fields[field.val] = component
    else:
      echo "Two components struggle for the same field, `", #<-try 
        ent.fields[field.val].name, "` and `", component.name,
        "` both want `", field.val, "`."
  
  entities[ent.name] = ent
  result = nil

macro componentInterface*: stmt {.immediate.}=
  #echo(treerepr(callsite()))
  let cs = callsite()
  assert cs.len == 4
  let thisComponent = $cs[1]
  #var component = components[thisComponent]
  let thisMethodName = $ cs[2]
  echo "new interface ", thisMethodName, " for ", thisComponent
  components.mget(thisComponent).methods[thisMethodName] = cs[3]
  #echo(repr(component.methods[thisMethodName]))

macro dumpcomponents*: stmt =
  echo "COMPONENTS: ", len(components)
  for k, v in pairs(components):
    echo "key: ", k
    echo "val: ", repr(v)
  
  echo "ENTITIES: ", len(entities)
  for k, v in pairs(entities):
    echo "key: ", k
    echo "val: ", repr(v)

macro buildTypes*: stmt =
  var res = newNimNode(nnkTypeSection)
  
  for name, cmp in pairs(components):
    echo "building ", name
    
    var ty: PNimrodNode
    if cmp.inheritable:
      var recList: PNimrodNode
      if cmp.data:
        recList = newNimNode(nnkRecList)
        for i in 0 .. <len(cmp.data.val):
          recList.add cmp.data.val[i].copyNimTree
        
      else:
        recList = newEmptyNode()
      
      var parent = if not cmp.parent:
        !!"CBase" else: !!components[cmp.parent.val].name
      var otype = newNimNode(nnkObjectTy).add(
        newEmptyNode(), newNimNode(nnkOfInherit).und(parent), recList)
      
      ty = if cmp.needsRef:  newNimNode(nnkRefTy).add(otype)
        else: otype
      
    else:
      ty = cmp.data.val
      
    res.add newNimNode(nnkTypeDef).add(
      !!name, newEmptyNode(), ty)
  
  for name, ent in pairs(entities):
    var recList = newNimNode(nnkRecList)
    for field, comp in pairs(ent.fields):
      recList.add newNimNode(nnkIdentDefs).add(
        !!field, !!comp.name, newEmptyNode())
    if recList.len == 0: recList = newEmptyNode()
    
    res.add newNimNode(nnkTypeDef).und(
      !!name,
      newEmptyNode(),
      newNimNode(nnkObjectTy).und(
        newEmptyNode(),
        newNImNode(nnkOfInherit).und(!!"TEntity"),
        recList
    ) )
  
  result = newStmtList(res)
  when defined(Debug):
    echo repr(result)


proc instanceMethod(ent: EntityRecord; comp: ComponentImpl; 
      meth_name: string, meth: PNimrodNode): PNimrodNode {.compileTime.} =
  result = newNimNode(nnkMethodDef)
  meth.copyChildrenTo result
  result.name = !!meth_name
  
  var p = result.params
  p.insert(newNimNode(nnkIdentDefs).add(
    !!"entity", newNimNode(nnkVarTy).add(!!ent.name), newEmptyNode()),
    1
  )
  p.insert(newNimNode(nnkIdentDefs).add(
    !!comp.field.val, !!comp.name, newEmptyNode()),
    2
  )
  result.params = p

proc instantiateSubcomponents(ent: EntityRecord, comp: ComponentImpl,
    interfaceCache: var TOrderedTable[string, tuple[args: PNimrodNode, fields: seq[string]]] 
    ): PNimrodNode {.compileTime.}=
  result = newStmtList()
  for name, meth in pairs(comp.methods):
    result.add instanceMethod(ent, comp, name, meth)
    if not interfaceCache.hasKey(name):
      var p = meth.params.copyNimTree
      p.insert(
        newNimNode(nnkIdentDefs).add(
          !!"entity",
          newNimNode(nnkVarTy).add(!!ent.name),
          newEmptyNode()
        ), 1
      )
        
      interfaceCache[name] = (args: p, fields: @[comp.field.val])
    else:
      if comp.field.val notin interfaceCache.mget(Name).fields:
        interfaceCache.mget(name).fields.add comp.field.val
  
  if not comp.children.isNil:
    for c in comp.children:
      #result.add instantiateSubcomponents(ent, components.mget(c), interfaceCache)
      # V this is done instead to keep the resulting stmt list flattened
      instantiateSubcomponents(ent, components.mget(c), interfaceCache).copyChildrenTo(result)


macro generateMethods*: stmt =
  result = newStmtList()
  for name, ent in pairs(entities):
    template insertEntityParam(toNode) =
      insert(
        toNode, 
        newNimNode(nnkIdentDefs).add(
          !!"entity", newNimNode(nnkVarTy).add(!!name), newEmptyNode()),
        1)
    
    
    var entityImpls = initOrderedTable[string, tuple[args: PNimrodNode; fields: seq[string]]](32)
    ## { method_name : ( method_prototype, component_fields ) }
    
    for f, comp in pairs(ent.fields):
      ## instance methods for each component
      
      # each component needs to be checked for children having methods that need
      # to be instantiated
      #var r = instantiateSubcomponents(ent, comp, entityImpls)
      #result.add r
      instantiateSubcomponents(ent, comp, entityImpls).copyChildrenTo(result)
      
      when false:
        ## done in instantiateSubcomponents()
        for m, meth in pairs(comp.methods):
          #echo name,':',f,':',m
          
          
          var thisM = instanceMethod(comp, ent, m, meth)
          result.add thisM
          
          
          if not entityImpls.hasKey(m):
            ## add the prototype to the list whatfor the next step of generationing
            var params = newNimNode(nnkFormalParams)
            params.add thisM.params[0]
            params.add thisM.params[1]
            ## skip the component argument 
            for i in 3.. <len(thisM.params):
              params.add thisM.params[i]
            
            entityImpls[m] = (args: params, fields: newSeq[string](0))
          
          entityImpls.mget(m).fields.add f
    
    ## turn that into 
    ## entity.method(entity.field, arg1, arg2, ..)
    for m, args_fields in pairs(entityImpls):
      var newParams = args_fields.args.copyNimTree()
      var argNames: seq[string] = @[]
      for i in 2 .. <len(newParams):
        argNames.add($newParams[i][0]) # <- identdefs
      
      var body = newStmtList()
      for field in args_fields.fields:
        ## entity.method(entity.field, arg1, arg2, ..)
        var c = newCall((!!"entity").dot(!!m))
        c.add((!!"entity").dot(!!field))
        for arg in argNames:
          c.add(!!arg)
        body.add c
      
      
      var meth = newProc(
        name = !!m,
        procType = nnkMethodDef,
        body = body)
      meth.params = newParams
      
      result.add meth
  
  when defined(Debug):
    echo repr(result)
    


when isMainModule:

  import fowltek/vector_math, os, math

  type TVector2f = TVector2[float]
  proc round* (some: TVector2f): TVector2[int] = (some.x.round.int, some.y.round.int)
  


  defComponent(CPos, field = pos, data = TVector2f) 

  defComponent(CVelocity, field = vel, data = TVector2f, requires = pos)
  
  #componentInterface(CVelocity, update) do (dt: float): 
  componentInterface(CVelocity, update, proc(dt: float) =
    ## CVelocity is passed as `vel` or you could get it from entity.vel
    entity.pos += vel * dt)

  defComponent(CGravity, field = grav, data = TVector2f, requires = pos)
  componentInterface(CGravity, update, proc(dt: float) =
    entity.vel -= grav * dt)

  defComponent(CRenderable, field = rendr, requires = pos)
  defComponent(CCircular, parent = CRenderable, data = tuple[radius: float])

  componentInterface(CRenderable, draw, proc() =
    echo "drawing at ", entity.pos.x.int, 'x', entity.pos.y.int )
  componentInterface(CCircular, draw, proc() =
    echo "drawing circle radius ", rendr.radius, " at ", entity.pos.round)

  defEntity(ECharles, CPos, CVelocity, CGravity)

  defEntity(EBill, CPos, CRenderable, CGravity, CVelocity)
  
  
  buildTypes()
  generateMethods()

  var bill = EBill(rendr: CCircular(radius: 3.0), pos: (x: 10.0, y: 20.0),
    grav: (0.0, 1.0), vel: (1.0, 0.0))
  bill.draw
  
  when false:
    var c1 = ECharles(grav: (0.0, 1.0), pos: (100.0, 100.0))
    let framerate = 1.0
    for i in 0 .. <10:
      echo "pos: ", round(c1.pos)
      c1.update framerate
      sleep 1

