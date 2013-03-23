import sdl2, sdl2_gfx
import gui
import math
randomize()

discard SDL_Init(INIT_EVERYTHING)

var 
  window: PWindow
  render: PRenderer
  g: PGui

window = CreateWindow("SDL Skeleton", 100, 100, 640,480, SDL_WINDOW_SHOWN)
render = CreateRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)
g = newGui(window)

proc showMessage (s: string) =
  var w: PSubWindow
  var algn = newAlignment(South, 2)
  algn.add newTextArea_noInput(text = s)
  algn.add newButton("Okay", proc(s:PButton) = g.delete(w))
  w = newSubWindow("oh my god this is important", algn)
  w.setPos random(640 - 100) + 100, random(480 - 80)+80
  g.add w
  

block:
  var inputArea = newTextArea()
  var btn1 = newButton("Herp", proc(s:PButton) = showMessage("HERP"))
  var btn2 = newButton("Derp", proc(s:PButton) = nil)
  var algn = newAlignment(East, 4)
  algn.add btn1
  algn.add btn2
  var algn2 = newAlignment(South, 4)
  algn2.add inputArea
  algn2.add algn
  var w = newSubWindow("Input", algn2)
  w.setPos 100, 100
  g.add w

var
  evt: TEvent
  runGame = true

while runGame:
  while pollEvent(evt):
    if evt.kind == QuitEvent:
      runGame = false
      break
    g.handleEvent evt
  
  g.update()
  render.setDrawColor 0,0,0,255
  render.clear
  
  g.draw render
  render.present

destroy render
destroy window

