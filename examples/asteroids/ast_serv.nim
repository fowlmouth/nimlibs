import fowltek/entitty, fowltek/idgen, enet

type
  PCServ* = var TCServ
  TCServ* = object
    entities*: seq[TEntity]
    domain*: TDomain
    idg: TIDgen[int]
      #eserv: TMaybe[enet.pclient]

proc newServ* : TCServ =
  result.entities = @[]
  result.idg = newIDGen[int]()
  result.domain = newDomain()

proc get_ent* (S: PCServ; id: int): PEntity{.inline.} = S.entities[id]

proc add_ent* (S: PCServ; ent: TEntity): int =
  result = S.idg.get
  S.entities.ensureLen result+1
  S.entities[result] = ent
  S.get_ent(result).id = result

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
  for idx in 0 .. high(serv.entities):  
    template entity: expr  = serv.entities[idx]
    if entity.id > -1:
      body
