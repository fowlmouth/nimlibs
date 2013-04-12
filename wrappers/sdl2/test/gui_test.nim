import sdl2, sdl2_gfx
import gui , color
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
  algn.add newButton("Okay", proc = g.delete(w))
  w = newSubWindow("omg", algn)
  w.setPos random(640 - 100) + 100, random(480 - 80)+80
  g.add w
  
  w.vt.destroy = proc(W:PWidget) =
    let W = PSubWindow(W)
    echo "WINDOW FREE'D: ", W.getTitle()
  

block:
  var inputArea = newTextArea()
  var btn1 = newButton("Herp", proc = showMessage("HERP"))
  btn1.setColor Blue
  var btn2 = newButton("GC Fullcollect", proc = GC_FullCollect())
  btn2.setColor Red
  var algn = newAlignment(East, 8)
  algn.add btn1
  algn.add btn2
  var algn2 = newAlignment(South, 4)
  algn2.add inputArea
  algn2.add algn
  var w = newSubWindow("Input", algn2)
  w.setPos 100, 100
  g.add w
  
  var tileWindows = newButton("Tile Windows", proc =
    var pos = (0, 0)
    for widget in g.children:
      widget.setPos pos[0], pos[1]
      inc pos[1], widget.bounds.h)
  tileWindows.setPos 0, 480-10
  tileWindows.vt.pos = proc(W:PWidget; X,Y:int16) = nil
  g.add tileWindows

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

