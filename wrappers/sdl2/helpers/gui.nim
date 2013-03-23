## This is a whack GUI based on SDL2_GFX 
## May change in the future to use SDL2_TTF more
## 
import sdl2, sdl2_gfx, color, vector_math
import strutils, unsigned


type

  TDirection* = enum North, East, South, West

  PWidget* = ref TWidget
  TWidget* = object{.inheritable.}
    col: sdl2.TColor
    bounds*: TRect     
    vt: TWidgetVTable
  
  TWidgetVTable = tuple[
    draw: drawProc, event: eventHandler, 
    pos: posSetter, update, destroy: updateFunc]
  
  TVector2i* = TVector2[int32]

  
  drawProc = proc(some: PWidget; R: PRenderer)
  eventHandler = proc(some: PWidget; evt: var sdl2.TEvent): bool
  posSetter = proc(some: PWidget; x, y: int16)
  updateFunc = proc(some:PWidget)

const
  GuiUpdateDelay = 1000


proc free*(some: PWidget) =
  some.vt.destroy(some)

proc handleEvent*(some: PWidget; evt: var sdl2.TEvent): bool{.
  inline,discardable.}=some.vt.event(some, evt)

proc draw*(some: PWidget; R: PRenderer){.inline.} =
  some.vt.draw(some, R)
  when defined(Debug):
    R.setDrawColor Red
    R.drawRect some.bounds

proc setPos*[A: TNumber](b: PWidget; x, y: A){.inline.}=
  b.vt.pos(b, x.int16, y.int16)

proc update*(some: PWidget) {.inline.} = some.vt.update(some)

proc setColor*(b: PWidget; col: sdl2.TColor) =
  b.col = col


proc contains*(a: TRect; b: TVector2[cint]): bool =
  if a.x <= b.x and (a.x + a.w) >= b.x and
     a.y <= b.y and (a.y + a.h) >= b.y: 
    result = true


{.pragma: id, immediate, dirty.}

template free_fwd* (ty): expr = (proc(some: ty) = some.vt.destroy(some))

template upd_impl(name: expr; typ: expr; body: stmt): stmt {.id.} =
  proc `upd name`*(W: PWidget) =
    var W{.inject.} = typ(W)
    body

template draw_impl(name, typ: expr; body: stmt): stmt {.id.}=
  proc `draw name`*(W: PWidget; R: PRenderer) =
    let W{.inject.} = typ(W)
    body

template pos_impl(name, typ: expr; body: stmt): stmt {.id.} =
  proc `pos name`*(W: PWidget; X,Y: int16) =
    var W{.inject.} = typ(W)
    body

template evt_impl(name, typ: expr;body: stmt): stmt {.id.} =
  proc `evt name`*(W: PWidget; evt: var sdl2.Tevent): bool =
    var W{.inject.} = typ(W)
    body
template mouse_click(btn: uint8; bounds: var TRect; body: stmt): stmt {.id.}=
  if evt.kind == MouseButtonDown:
    let m{.inject.} = EvMouseBUtton(evt)
    if m.button == btn and vec2(m.x, m.y) in bounds:
      body

proc `evt nop`*(W: PWidget; evt: var sdl2.Tevent): bool = false

template pos_impl_default: stmt {.immediate.}=
  W.bounds.x = x
  W.bounds.y = y
  W.update()

proc `pos default`*(W: PWidget; X,Y: int16) =
  pos_impl_default()

proc `draw nop`*(W: PWidget; R: PRenderer) = nil

proc `upd default`*(W: PWidget) = nil


proc init*(
        some: PWidget, 
        draw: drawProc = draw_nop; 
        event: eventHandler = evt_nop;
        pos: posSetter = pos_default;
        update: updateFunc = upd_default;
        destroy: updateFunc = upd_default ) =
  some.vt.draw = draw
  some.vt.event= event
  some.vt.pos = pos
  some.vt.update = update
  some.vt.destroy = destroy
  some.col = White   




iterator reverseExcept[A] (some: var seq[A]; n: int = 0): var A = 
  for i in countDown(some.high - n, 0):
    yield some[i]

template pushViewport*(R: PRenderer; V: ptr TRect; body: stmt): stmt =
  var current_viewport: TRect
  R.getViewport current_viewport
  R.setViewport(V)
  body
  R.setViewport(addr current_viewport)


type
  PGui* = ref TGui
  TGui* = object of TWidget
    widgets: seq[PWidget]
    focusedWidget: PWidget
    focusMode*: TFocusMode
    autoFocusNewWindows*, drawFocused*: bool
    tabIndex: int
    nextUpdate: uint32
  TFocusMode* = enum
    FocusFollowsMouse, ClickToFocus
  

evt_impl gui, PGui:
  if evt.kind == KeyDown and EvKeyboard(evt).keysym.sym == K_TAB and
      W.focusedWidget.isNil:
    W.tabIndex = (W.tabIndex+1) mod W.widgets.len
    W.focusedWidget = W.widgets[W.tabIndex]
  
  if W.focusMode == FocusFollowsMouse and evt.kind == MouseMotion:
    let m = EvMouseMOtion(evt)
    
    let pos = vec2(m.x, m.y)
    for wid in reverseExcept(W.widgets):
      if pos in wid.bounds: 
        W.focusedWidget = wid
        break
  
  if not W.focusedWidget.isNil:
    return W.focusedWidget.handleEvent(evt)

draw_impl gui, PGui:
  pushViewport R, W.bounds.addr:
    for wgt in W.widgets:
      wgt.draw(R)
    if W.drawFocused:
      if not W.focusedWidget.isNil:
        R.setDrawColor W.focusedWidget.col
        R.drawRect W.focusedWidget.bounds

upd_impl gui, PGui:
  if sdl2.getTicks() > W.nextUpdate:
    inc W.nextUpdate, GuiUpdateDelay
    for c in W.widgets.items: c.update()

proc newGui*(bounds: TRect): PGui =
  new result, free_fwd(PGui)
  
  init(result, draw_gui, evt_gui, update=upd_gui)
  
  result.widgets = @[]
  result.bounds = bounds
  result.autoFocusNewWIndows = true
  result.nextUpdate = sdl2.getTicks()+GuiUpdateDelay
  
proc newGui*(G: PGui): PGui = 
  result = newGui(G.bounds)
  
  result.autoFocusNewWIndows = G.AutoFocusNewWindows

proc newGui*(W: PWindow): PGui = 
  var bounds: TRect
  W.getSize bounds.w, bounds.h
  result = newGui(bounds)

proc add*(G: PGui; W: PWidget): PWidget {.discardable.}=
  for Wdg in G.Widgets:
    if Wdg == W: 
      result = W
      break
  if result.isNil:
    G.widgets.add W
    result = W
  if G.autoFocusNewWIndows: G.focusedWidget = result

proc delete*(G: PGui; W: PWidget) =
  for i in 0 .. high(G.widgets):
    if W == G.widgets[i]:
      G.widgets.delete i
      break
      


type
  PTextArea* = ref TTextArea
  TTextArea* = object of TWidget
    lines: seq[string]
    cursor: TVector2[int]
    line_no: int ## # of line nos shown (2 for "10",etc)
    show_cursor: bool



template thisLine(some: PTextArea): var string = some.lines[some.cursor.y]

proc move_cursor(P: PTextArea; d: TDirection, by = 1)=
  case d
  of West, East: 
    inc P.cursor.x, by * (if d == West: -1 else: 1)
    if P.cursor.x < 0:  P.cursor.x = 0
  of North, South:
    inc P.cursor.y, by * (if d == North: -1 else: 1)
    if P.cursor.y < 0: P.cursor.y = 0
    elif P.cursor.y > P.lines.high:
      let new_lines = P.cursor.y - P.lines.high
      for i in 1 .. new_lines: P.lines.add ""
      P.cursor.x = 0
  else:nil
  if P.cursor.x > P.thisLine.len:
    P.cursor.x = P.thisLine.len

proc backspace(T: PTextArea) =
  if T.Cursor.X == 0 and T.Cursor.Y > 0:
    let ln = T.thisLine
    T.lines.delete T.cursor.Y
    dec T.Cursor.Y
    T.Cursor.X = T.ThisLine.len
    T.ThisLine.add ln
  else:
    let rest = T.thisLine.substr(T.cursor.x)
    T.thisLine.setLen T.cursor.x-1
    T.thisLine.add rest
    T.move_cursor West

upd_impl textarea, PTextArea:
  W.bounds.w = min(W.lines.map(proc(x: string): int = x.len).max, 80).int32 * 8'i32
  W.bounds.h = min(W.lines.len, 40).int32 * 10'i32
  if W.line_no > 0: 
    inc W.bounds.w, W.line_no * 8

proc joinText*(some: PTextArea): string {.inline.} = some.lines.join("\L")
proc clearText*(some: PTextArea){.inline.} = 
  some.lines = @[""]
  some.cursor.x = 0
  some.cursor.y = 0

{.warning[SmallLshouldNotBeUsed]: off.}
proc addLine*(some: PTextArea; lines: varargs[string]) =
  for l in lines: some.lines.add l
  some.update()

proc setText*(some: PTextArea; text:string) {.inline.} =
  some.clearText()
  some.addline text.split('\L')

draw_impl textarea, PTextArea:
  let margin = (W.line_no * 8 + W.bounds.x).int16
  for i in 0 .. W.lines.high:
    let y = (W.bounds.y + i * 10).int16
    if W.line_no > 0:
      R.stringRGBA W.bounds.x.int16, y, $i,  W.Col
    R.stringRGBA margin, y, W.lines[i], W.Col
  
  if W.show_cursor:
    let cursor_x = int16(margin + W.cursor.x * 8)
    let cursor_y = int16(W.bounds.y + W.cursor.y * 10)
    R.lineRGBA cursor_x, cursor_y, cursor_x, cursor_y + 10,  W.Col.R, W.Col.G, W.Col.B, W.Col.A
  
evt_impl textarea, PTextArea:
  
  template RT : stmt = return true
  
  case evt.kind
  of TextInput:
    var inp = EvTextInput(evt)
    let s = $cast[cstring](addr inp.text[0])
    W.thisLine.insert(s, W.cursor.x)
    W.cursor.x.inc s.len
    result = true
  of KeyDown:
    let k = EvKeyboard(evt)
    
    case k.keysym.sym
    of K_LEFT:
      W.move_cursor West
      RT
    of K_RIGHT:
      W.move_cursor East
      RT
    of K_UP:
      W.move_cursor North
      result = true
    of K_DOWN:
      W.move_cursor South
      result = true
    of K_BACKSPACE:
      W.backspace()
      result = true
    of K_HOME:
      W.move_cursor West, 999
    of K_END:
      W.move_cursor East, 999
    
    of K_RETURN:
      if W.thisLine.len > W.cursor.x:
        let rest = W.thisLine.substr(W.cursor.x)
        W.thisLine.setLen W.cursor.x
        
        inc W.cursor.y, 1
        W.cursor.x = 0
        W.lines.insert rest,W.cursor.Y
    else: nil
  else: nil
  
  if result:
    update(W)


proc newTextArea*(line_no = 3; show_cursor = true; text = ""): PTextArea =
  new result,free_fwd(PTextArea)
  init( result, draw_textarea, evt_textarea, update=upd_textarea)
  result.setText text
  result.line_no = line_no
  result.show_cursor = show_cursor
proc newTextArea_noInput*(line_no = 0; show_cursor = false; text = ""): PTextArea =
  ## a specialized text area that doesnt respond to events (input)
  result = newTextArea(line_no, show_cursor, text)
  result.vt.event = evt_nop
  

type
  PButton* = ref TButton
  TButton* = object of TWidget
    text: string
    onclick*: proc(){.closure.}

draw_impl button, PButton:
  R.stringColor W.bounds.x.int16, W.bounds.y.int16, W.text, W.col

evt_impl button, PButton:
  mouseClick BUTTON_LEFT, W.bounds:
      W.onClick()
      return true
      
proc setText*(b:PButton; s:string) =
  b.text = s
  b.bounds.w = (b.text.len * 8).cint
  b.bounds.h = 10
proc getText*(b:PButton):string = b.text

proc newButton*(t: string; f: proc{.closure.}): PButton =
  new result,free_fwd(PButton)
  init result, draw_button, evt_button
  result.setText t
  result.onclick = f

proc newTextEntry*(t: string): PButton =
  ##this should be a button thats clickable but editable like the text area
  new result,free_fwd(PButton)
  init result, draw_button, evt_button
  ##need a specialized evt_button to figure out where to put the caret
  ##specialized draw_button to draw the text clamped to some width(optionally)
  result.setText t
  result.onClick = proc = nil




type
  PSubWindow* = ref TSubWindow
  TSubWIndow* = object of TWidget
    title: string
    shaded: bool
    widget: PWidget
    shade_button: PButton
    titleBar: TRect
    isDragging: bool

proc x2(some: TRect): cint = some.x + some.w
proc y2(some: TRect): cint = some.y + some.h

upd_impl subw, PSubWindow:
  W.bounds.w = cint(W.title.len * 8)
  W.bounds.h = 10
  W.titleBar = W.bounds
  inc W.titleBar.w, 2 * 8
  
  if not(W.shaded) and not(W.widget.isNil):
    W.widget.update()
    let diff = W.titleBar.x2 - W.bounds.x2
    if diff > 0:
      inc W.bounds.w, diff
    inc W.bounds.h, W.widget.bounds.h
  
  W.shade_button.setPos(W.titleBar.x2 - 8, W.TitleBar.y)
  discard """ let diff = W.titleBar.x + W.titleBar.w - w.bounds.x + w.bounds.x
  if diff > 0: inc W.bounds.w, diff """

draw_impl subw, PSubWindow:
  R.stringRGBA W.bounds.x.int16, W.bounds.y.int16, W.title, W.col
  #R.stringRGBA((W.bounds.x+W.bounds.w-8).int16, W.bounds.y.int16, "x", Red)
  R.setDrawColor Yellow
  R.drawRect W.titleBar
  W.shadeButton.draw(R)
  if not W.shaded:
    W.widget.draw(R)

pos_impl subw, PSubWindow:
  pos_impl_default()
  W.widget.setPos W.bounds.x.int16, (W.bounds.y + 10).int16
  W.update()

evt_impl subw, PSubWindow: 
  result = W.shadeButton.handleEvent(evt)
  if not result:
    mouseClick BUTTON_LEFT, W.titleBar:
      if not W.isDragging:
        W.isDragging = true
        result = true
    if evt.kind == MouseButtonUp and EvMouseButton(evt).button == BUTTON_LEFT:
      W.isDragging = false
      result = true
    elif evt.kind == MouseMotion and W.isDragging:
      let m = evMouseMOtion(evt)
      W.setPos m.xrel + W.bounds.x, m.yrel + W.bounds.y      
      return true
  if not result:  result = W.widget.handleEvent(evt)
  
  W.update()

proc toggleShade*(some: PSubWindow) =
  some.shaded = not some.shaded
  some.shadeButton.setText(if some.shaded: "+" else: "-")
  some.update

proc setTitle*(W: PSubWindow; title: string) =
  W.title = title
proc newSubWindow*(Title: string; Widget: PWidget; shaded = false): PSubWindow =
  new result,free_fwd(PSubWindow)
  result.init(draw=draw_subw, event=evt_subw, pos=pos_subw, update=upd_subw) 
  result.setTitle title
  result.widget = widget
  result.shaded = shaded
  let res = result
  result.shadeButton = newButton("-", proc =
    res.toggleShade())
  GC_unref result


type
  PAlignment* = ref TAlignment
  TAlignment* = object of TWidget
    pack_dir: TDirection
    children: seq[PWidget]
    spacing: int


proc incorporate(A: var TRect; B: TRect) =
  if B.x2 > A.x2:
    inc A.w, B.x2 - A.x2
  if B.x < A.x:
    dec A.x, A.x - B.x
  if B.y2 > A.y2:
    inc A.h, B.y2 - A.y2
  if B.y  < A.y:
    dec A.y, A.y - B.y

upd_impl align, PAlignment:
  var pos = vec2(W.bounds.x, W.bounds.y)
  for i in 0 .. high(W.children):
    W.children[i].setPos(pos.x, pos.y)
    case W.pack_dir
    of South:
      inc pos.y, (W.children[i].bounds.h + W.spacing)
    of North:
      dec pos.y, W.children[i].bounds.h + W.spacing
    of East:
      inc pos.x, W.children[i].bounds.w + W.spacing
    of West:
      dec pos.x, W.children[i].bounds.w + W.spacing
    W.bounds.incorporate W.children[i].bounds

pos_impl align, PAlignment:
  pos_impl_default()
  update(W)

draw_impl align, PAlignment:
  for c in W.children.items: c.draw(R)

evt_impl align, PAlignment:
  for c in W.children.items:
    if c.handleEvent(evt): return true

proc newAlignment*(dir: TDirection, spacing = 0): PAlignment =
  new result,free_fwd(PAlignment)
  init(result, pos = pos_align, draw = draw_align,
    event = evt_align, update=upd_align) 
  result.pack_dir = dir
  result.children = @[]
  result.spacing = spacing


proc add*(a: PAlignment; b: PWidget): PWidget{.discardable.}=
  a.children.add b
  result = b

proc newMenuList*(): PAlignment = newAlignment(South, 2)

proc `[]`*(a: PAlignment; index: int): PWidget = a.children[index]

