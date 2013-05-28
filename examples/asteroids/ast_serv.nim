import fowltek/entitty, fowltek/idgen, enet,
  fowltek/tmaybe, fowltek/bbtree, ast_comps,
  math, tables, fowltek/boundingbox

type
  TServerMode* = enum
    SClient, SHost
  
  PCServ* = var TCServ
  TCServ* = object
    entities*: seq[TEntity]
    activeEntities*: seq[int]
    domain*: TDomain
    bbtree*: TBBTree[int]
    eserv: TMaybe[enet.PHost]
    case serverMode: TServerMode
    of SHost:
      idg: TIDgen[int]
    else:nil

proc newServ* : TCServ =
  result.entities = @[]
  result.activeEntities = @[]
  result.serverMode = SHost
  result.idg = newIDGen[int]()
  result.bbtree = newBBtree[int]()
  
  result.domain = newDomain()

proc connect* (address: string; port: int): TMaybe[TCServ] =
  nil

import algorithm
proc poll* (S: PCServ) = 
  if S.eserv:
    nil
  if random(10) == 0:
    S.activeEntities.sort cmp[int]

proc get_ent* (S: PCServ; id: int): PEntity{.inline.} = S.entities[id]

proc add_ent* (S: PCServ; ent: TEntity): int =
  result = S.idg.get
  S.entities.ensureLen result+1
  S.entities[result] = ent
  S.get_ent(result).id = result
  S.activeEntities.add result
  S.bbtree.insert result, S.get_ent(result).getBoundingBox

proc add_ents* (S: PCserv; num: int, components: varargs[int, `componentID`]): seq[int] =
  var ty = S.domain.getTypeinfo(components)

  newSeq result, 0
  for i in 1 .. num:
    let id = S.add_ent(ty.newEntity)
    result.add id

proc each_ent_cb* (ids: seq[int]; S: PCServ; cb: proc(X: PEntity)) =
  for id in ids:
    cb S.get_ent(id)

template eachEntity* (serv; body: stmt): stmt {.immediate,dirty.}=
  #for idx in 0 .. high(serv.entities):
  for id in serv.activeEntities:  
    template entity: expr  = serv.entities[id]
    #if entity.id > -1:
    body

proc update* (S: PCServ; dt: float) {.inline.}=
  eachEntity(S): 
    entity.update dt
    S.bbtree.update entity.id, entity.getBoundingBox

