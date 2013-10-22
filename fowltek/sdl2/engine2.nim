import fowltek/sdl2, fowltek/sdl2/spriteCache

template import_all_sdl2_modules*: stmt =
  import fowltek/sdl2, fowltek/sdl2/image, fowltek/sdl2/gfx, fowltek/sdl2/ttf
template import_all_sdl2_helpers*: stmt =
  when not defined(toSDLcolor): 
    import fowltek/sdl2/color
  when not defined(spriteCache):
    import fowltek/sdl2/spritecache
template import_all_sdl2_things*: stmt =
  import_all_sdl2_modules
  import_all_sdl2_helpers

type
  PGameEngine* = var TGameEngine
  TGameEngine* = object ##fuck it, this is actually "game engine", rename it later
    gameStates: seq[PGameState]
    lastTick: uint32
    window*: PWindow
    render*: PRenderer
    running: bool
    sprites*: TSpriteCache
  
  PGameState* = ref object of TObject
    update*: TGameStateUpdateCB
    draw* :  TGameStateDrawCB
    events* : seq[TGameStateEventCB]
  
  TGameStateUpdateCB* = proc(E: PGameEngine; dt: float)
  TGameStateDrawCB* =  proc (E: PGameEngine)
  TGameStateEventCB* = proc (E: PGameEngine; evt: var sdl2.TEvent): bool

converter toRenderer* (some: PGameEngine): sdl2.PRenderer = some.render

proc topState* (M: PGameEngine): PGameState {.inline.} =
  M.gameStates[M.gameStates.high]


proc frameDeltaMS*(some: PGameEngine): int32 {.
  inline.} = 
  ## Calculate the delta MS from the last frame.
  ## This is no use unless you call it once a frame.
  let cur = sdl2.getTicks()
  result = int32(cur - some.lastTick)
  some.lastTick = cur
  
proc frameDeltaFlt(some: PGameEngine): float {.
  inline.} = some.frameDeltaMS / 1000

proc handleEvents* (M: PGameEngine) {.inline.} =
  var evt: sdl2.TEvent
  while evt.pollEvent:
    block tryToHandleIt:
      for handler in M.topState.events:
        if handler(M, evt): break tryToHandleIt

proc draw* (M: PGameEngine) {.inline.} =
  M.topState.draw M
proc update* (M: PGameEngine) {.inline.} =
  M.topState.update M, M.frameDeltaFLT()

proc pushState* (M: PGameEngine; S: PGameState) =
  M.gameStates.add S
proc popState* (M: PGameEngine) =
  discard M.gameStates.pop

proc close* (M: PGameEngine) {.inline.} = 
  M.running = false
proc stop*  (M: PGameEngine) {.inline.} = 
  M.close

proc run * (M: PGameEngine) {.inline.} =
  while M.running:
    M.handleEvents
    M.update 
    
    M.setDrawColor 0,0,0,255
    M.clear
    
    M.draw 
    
    M.present

proc newGameEngine* (
    gs: PGameState;
    caption = "SDL Game", 
    startX, startY = 100, 
    sizeX = 640, sizeY = 480,
    renderFlags = Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture,
    imageRoot = "assets"
  ) : TGameEngine =
  
  discard sdl2.Init (INIT_EVERYTHING)
  
  result = TGameEngine(
    gameStates: @[gs], 
    running: true,
    sprites: newSpriteCache(root = imageRoot))
  
  result.window = CreateWindow(caption, startX.cint, startY.cint, 
    sizeX.cint, sizeY.cint, SDL_WINDOW_SHOWN)
  result.render = result.window.createRenderer(-1, 
    Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)
  
  result.lastTick = sdl2.getTicks()
  

proc defaultDraw (M: PGameEngine) {.procvar.} = nil
proc defaultUpdate (M: PGameEngine; dt: float) {.procvar.} = nil

proc init* (gs: PGameState)  =
  gs.draw   = defaultDraw
  gs.update = defaultUpdate
  gs.events = @[]
proc newGameState* (
    update = defaultUpdate; 
    draw = defaultDraw;
    events: seq[TGameStateEventCB] = @[]
  ): PGameState =
  PGameState(update: update, draw: draw, events: events)

proc addHandler* (gs: PGameState; cb: TGameStateEventCB) {.inline.} =
  gs.events.add cb



proc closeOnQuitEvent* (M: PGameEngine; evt: var sdl2.TEvent): bool {.procvar.}=
  result = evt.kind == QuitEvent
  if result: M.close

proc closeOnQuitEventOrKey* (key: cint): TGameStateEventCB =
  return proc(M: PGameEngine; evt: var sdl2.TEvent): bool =
    result = (evt.kind == QuitEvent) or 
      (evt.kind == KeyDown and evt.EvKeyboard.keysym.sym == key)
    if result: M.close

proc keyEvent* (
    key: cint; 
    evtKind: TEventType; 
    action: proc(M: PGameEngine)): TGameStateEventCB =
  assert evtKind in {KeyDown, KeyUP}
  return proc(M: PGameEngine; evt: var sdl2.TEvent): bool =
    result = evt.kind == evtKind and 
      evt.EvKeyboard.keysym.sym == key
    if result: action(M)
