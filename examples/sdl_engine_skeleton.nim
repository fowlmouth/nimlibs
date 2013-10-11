import fowltek/sdl2/engine
import_all_sdl2_things

var 
  ng = newSdlEngine()
  running = true

ng.addHandler do(E: PSdlEngine) -> bool:
  result = (E.evt.kind == QuitEvent) or 
    (E.evt.kind == KeyDown and E.evt.EvKeyboard.keysym.sym == K_ESCAPE)
  running = not result

while running:
  ng.handleEvents
  
  ng.setDrawColor 0,0,0,255
  ng.clear
  
  ng.present
