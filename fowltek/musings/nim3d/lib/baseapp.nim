import glfw, gl_helpers, opengl,
  strutils, camera, nodes
when defined(UseDevil):
  import devil, ilut
type
  PApp* = ref TApp
  TApp* = object
    w, h: int32
    activeInput: PInputClient
    cam: PCamera
    scene: PScene
    renderProc: TRenderCallback
    updateProc: TUpdateCallback
  
  PInputClient* = ref TInputClient
  TInputClient* = object
    keyHandlers: array[TKeyAction, array[0..GLFW_KEY_LAST, TKeyHandler]]
  
  TKeyHandler* = proc() {.closure.}
  TRenderCallback* = proc(){.closure.}
  TUpdateCallback* = proc(dt:float){.closure.}
var
  keyState*: array[0..GLFW_KEY_LAST, bool] 
  instance: PApp

proc newInputClient*(): PInputClient
proc handleWindowSize(w, h: cint){.stdcall.}
proc handleKey(key: cint, status: TKeyAction){.stdcall.}
proc setCamera*(a: PApp; cam: PCamera) {.inline.}
proc setScene*(a: PApp; scn: PScene) {.inline.}

template KEY*(c: char): cint = cint(c)

proc newApp*(w, h: int32; antiAlias = 4'i32): PApp =
  if not instance.isNil:
    quit "App already instanced"
  
  if not glfw.Init().bool:
    quit "Could not initialize GLFW!"
  
  new result
  instance = result
  result.w = w
  result.h = h
  result.activeInput = newInputClient()
  result.setCamera newCamera()
  result.setScene newScene()
  
  when defined(UseDevil):
    IL_init()
    ILUT_init()
    if not ILUT_renderer(ILUT_OPENGL):
      quit "Failed to initialize Devil!"
  
  OpenWindowHint(GLFW_FSAA_SAMPLES, antiAlias)
  
  if not OpenWindow(w, h, 8, 8, 8, 8, 0, 0, GLFW_WINDOW).bool:
    Terminate()
    quit "Failed to open window"
  
  opengl.loadExtensions()
  gl_helpers.init()
  
  glEnable GL_LIGHTING
  glEnable GL_LIGHT0
  
  glEnable GL_DEPTH_TEST
  
  glLightModeli GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE
  glEnable GL_NORMALIZE

  SwapInterval(1)
  
  setWindowSizeCallback handleWindowSize
  setKeyCallback handleKey

proc setRender*(a: PApp; render: TRenderCallback) =
  a.renderProc = render
proc setUpdate*(a: PApp; update: TUpdateCallback) =
  a.updateProc = update

proc getCamera*(a: PApp): PCamera {.inline.} = a.cam
proc setCamera*(a: PApp; cam: PCamera) =
  a.cam = cam
proc getScene*(a: PApp): PScene {.inline.} = a.scene
proc setScene*(a: PApp; scn: PScene) = a.scene = scn

proc newInputClient*(): PInputClient =
  new result

proc windowOpen*(): bool {.inline.} = GetWindowParam(GLFW_OPENED) == GL_TRUE

method update*(app: PApp; dt: float) = 
  if not(app.updateProc.isNil): app.updateProc(dt)
method render*(app: PApp) = 
  glClear GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT
  app.cam.apply()
  if not(app.renderProc.isNil): app.renderProc()
  SwapBuffers()

method renderScene*(app: PApp) = app.scene.render()

method run*(app: PApp) =
  var currentTime, lastTime = glfw.getTime()
  lastTime -= (16 / 1000)  ##fix so that ode doesnt derp
  when defined(ShowFPS):
    var FPStime = currentTime + 1.0
  while windowOpen():
    currentTime = glfw.getTime()
    when defined(ShowFPS):
      if currentTime > FPStime:
        setWindowTitle "FPS: "&formatFloat(1.0/(currentTime - lastTime), ffDecimal, 2)
        FPStime = currentTime + 1.0
    app.update(currentTime - lastTime)
    app.render()
    lastTime = currentTime

proc register*(client: PInputClient; key: cint; 
                kind: TKeyAction; p: TKeyHandler) =
  client.keyHandlers[kind][key] = p

proc register*(app: PApp; key: cint; 
                kind: TKeyAction; p: TKeyHandler) {.inline.} =
  app.activeInput.register(key, kind, p)

proc setInputClient*(app: PApp; client: PInputClient){.inline.}=
  app.activeInput = client

proc handleKey(key: cint, status: TKeyAction) =
  keyState[key] = status.bool
  let p = instance.activeInput.keyHandlers[status][key]
  if not p.isNil: p()

proc handleWindowSize(w, h: cint) =
  instance.w = w
  instance.h = h
  
  glViewport 0, 0, w, h
  glMatrixMode GL_PROJECTION
  glLoadIdentity()
  
  gluPerspective 80.0, w / h, 0.1, 1000.0
  
  
