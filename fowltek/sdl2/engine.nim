## This is a minimal engine for rapid prototyping
## functionality included:
## * assisted window and renderer creation
## * easy to use event handling system
import fowltek/sdl2, fowltek/sdl2/gfx
import fowltek/tmaybe, unsigned


discard SDL_Init(INIT_EVERYTHING)

type 
  TSdlEventHandler* = proc(engine: var TSdlEngine): bool
  TSdlEventHandlerSeq* = seq[TSdlEventHandler]
  TSDLEngine* = object
    window*: PWindow
    render*: PRenderer
    evt*: TEvent
    eventHandlers*: TMaybe[TSDLEventHandlerSeq]
    fpsMan*: TFpsManager
    lastTick*: uint32

proc destroy* (some: var TSdlEngine) {.inline.} =
  destroy some.render
  destroy some.window

proc newSDLEngine*(
    caption = "SDL Game", 
    startX, startY = 100, 
    sizeX = 640, sizeY = 480,
    renderFlags = Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture): TSdlEngine =
  
  discard SDL_Init (INIT_EVERYTHING)
  result.window = CreateWindow(caption, startX.cint, startY.cint, 
    sizeX.cint, sizeY.cint, SDL_WINDOW_SHOWN)
  result.render = result.window.createRenderer(-1, 
    Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)
  
  result.fpsMan.init
  result.lastTick = sdl2.getTicks()

proc addHandler*(some: var TSdlEngine; handler: TSdlEventHandler) =
  if not some.eventHandlers:
    some.eventHandlers = Just(@[ handler ])
  else:
    some.eventHandlers.val.add handler

proc pollHandle*(some: var TSdlEngine): bool {.inline.} =
  result = some.evt.pollEvent
  if result and some.eventHandlers:
    for eh in some.eventHandlers.val:
      if eh(some): break

proc handleEvents*(some: var TSdlEngine) {.inline.} =
  while some.pollHandle:
    nil

proc frameDeltaMS*(some: var TSdlEngine): int32 {.
  inline.} = 
  let cur = sdl2.getTicks()
  result = int32(cur - some.lastTick)
  some.lastTick = cur
  
proc frameDeltaFlt*(some: var TSdlEngine): float {.
  inline.} = some.frameDeltaMS / 1000

proc delay*(some: var TSdlEngine) {.inline.} =
  ## wait for fpsMan (use this or Renderer_PresentVSync to limit the framerate)
  some.fpsMan.delay
proc delay*(some: var TSdlEngine; ms: uint32) {.inline.} =
  ## wait for `ms` milliseconds
  sdl2.delay ms


when isMainModule:
  var e = newSDLengine(sizeX = 640, sizeY = 480)
  var running = true
  e.addHandler proc(E: var TSdlEngine): bool =
    result = e.evt.kind == QuitEvent
    if result:
      running = false
  
  import strutils
  
  while running:
    e.handleEvents
    ## if you dont want to use the event handlers ->
    ## if e.pollHandle: 
    ##   # do stuff with e.evt
    let dt = e.frameDeltaFlt
    
    e.render.setDrawColor 0,0,0,255
    e.render.clear
    
    e.render.present

  destroy e
