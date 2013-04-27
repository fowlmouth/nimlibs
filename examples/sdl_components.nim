import fowltek/sdl2, fowltek/sdl2/gfx, fowltek/components
import fowltek/vector_math

type TVector2f = TVector2[float]

defComponent(CPos, field = pos, data = TVector2f)
defComponent(CVelocity, field = vel, requires = pos, data = TVector2f)
componentInterface(CVelocity, update, proc(dt: float) = 
  entity.pos += vel * dt)

defComponent(CRenderable, field = rendr, requires = pos)
componentInterface(CRenderable, draw, proc(R: sdl2.PRenderer) = nil)
defComponent(CCircular, parent = CRenderable, data = tuple[radius: float])
componentInterface(CCircular, draw, proc(R: sdl2.PRenderer) = 
  R.circleRGBA entity.pos.x.int16, entity.pos.y.int16, rendr.radius.int16, 
    255, 0, 0, 255
)

defEntity(ECircy, CPos, CVelocity, CRenderable)

buildTypes()
generateMethods()
 


discard SDL_Init(INIT_EVERYTHING)

var 
  window: PWindow
  render: PRenderer

window = CreateWindow("SDL Skeleton", 100, 100, 640,480, SDL_WINDOW_SHOWN)
render = CreateRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)

var c1 = ECircy(pos: (100.0, 100.0), rendr: CCircular(radius: 3.4), vel: (1.0, 0.0))

var
  evt: TEvent
  runGame = true
  fpsman: TFPSmanager
fpsman.init

while runGame:
  while pollEvent(evt):
    if evt.kind == QuitEvent:
      runGame = false
      break
  
  let dt = fpsman.getFramerate() / 1000
  c1.update dt
  
  render.setDrawColor 0,0,0,255
  render.clear
  
  c1.draw render
  
  render.present

destroy render
destroy window

