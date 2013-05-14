

when defined(Windows):
  const libName = "SDL2.dll"
elif defined(Linux):
  const LibName = "libSDL2.so"

include fowltek/sdl2/private/keycodes

const
  SDL_TEXTEDITINGEVENT_TEXT_SIZE* = 32
  SDL_TEXTINPUTEVENT_TEXT_SIZE* = 32
type
  TEvent* {.pure, final.} = object
    kind*: TEventType
    pad: array[0 .. <(56 - 4), byte]


  TWindowEventID* {.size: sizeof(byte).} = enum
    WindowEvent_None = 0, WindowEvent_Shown, WindowEvent_Hidden, WindowEvent_Exposed,
    WindowEvent_Moved, WindowEvent_Resized, WindowEvent_SizeChanged, WindowEvent_Minimized,
    WindowEvent_Maximized, WindowEvent_Restored, WindowEvent_Enter, WindowEvent_Leave,
    WindowEvent_FocusGained, WindowEvent_FocusLost, WindowEvent_Close
  
  TEventType* {.size: sizeof(cint).} = enum
    QuitEvent = 0x100, WindowEvent = 0x200, SysWMEvent,
    KeyDown = 0x300, KeyUp, TextEditing, TextInput,
    MouseMotion = 0x400, MouseButtonDown, MouseButtonUp, MouseWheel,
    InputMotion = 0x500, InputButtonDown, InputButtonUp, InputWheel, InputProximityIn, InputProximityOut,
    JoyAxisMotion=0x600, JoyBallMotion, JoyHatMotion, joyButtonDown, joyButtonUp, 
    fingerDown = 0x700, fingerUp, fingerMotion, touchButtonDown, touchButtonUp,
    dollarGesture = 0x800, DollarRecord, MultiGesture,
    clipboardUpdate = 0x900,
    dropFile = 0x1000,
    UserEvent = 0x8000, UserEvent1, UserEvent2, UserEvent3, UserEvent4, UserEvent5

  PWindowEvent* = ptr TWindowEvent 
  TWindowEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_WINDOWEVENT 
    timestamp*: Uint32
    windowID*: Uint32       #*< The associated window 
    event*: Uint8           #*< ::SDL_WindowEventID 
    padding1*: Uint8
    padding2*: Uint8
    padding3*: Uint8
    data1*: cint            #*< event dependent data 
    data2*: cint            #*< event dependent data 
  
  PKeyboardEvent* = ptr TKeyboardEvent
  TKeyboardEvent* {.pure, final.} = object 
    kind*: TEventType           #*< ::SDL_KEYDOWN or ::SDL_KEYUP 
    timestamp*: cint
    windowID*: cint       #*< The window with keyboard focus, if any 
    state*: Uint8           #*< ::SDL_PRESSED or ::SDL_RELEASED 
    repeat*: Uint8          #*< Non-zero if this is a key repeat 
    padding: array[0.. <2, byte]
    keysym*: TKeysym     #*< The key that was pressed or released 
  
  PTextEditingEvent* = ptr TTextEditingEvent 
  TTextEditingEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_TEXTEDITING 
    timestamp*: Uint32
    windowID*: Uint32       #*< The window with keyboard focus, if any 
    text*: array[0..SDL_TEXTEDITINGEVENT_TEXT_SIZE - 1, char] #*< The editing text 
    start*: cint            #*< The start cursor of selected editing text 
    length*: cint           #*< The length of selected editing text 
  
  PTextInputEvent* = ptr TTextInputEvent 
  TTextInputEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_TEXTINPUT 
    timestamp*: Uint32
    windowID*: Uint32       #*< The window with keyboard focus, if any 
    text*: array[0.. <SDL_TEXTINPUTEVENT_TEXT_SIZE, char] #*< The input text 
  
  PMouseMotionEvent* = ptr TMouseMotionEvent
  TMouseMotionEvent* {.pure, final.} = object 
    kind*: cint           #*< ::SDL_MOUSEMOTION 
    timestamp*: cint
    windowID*: cint       #*< The window with mouse focus, if any 
    state*: Uint8           #*< The current button state \
    padding*: array[0.. <3, byte]
    x*: cint                #*< X coordinate, relative to window 
    y*: cint                #*< Y coordinate, relative to window 
    xrel*: cint             #*< The relative motion in the X direction 
    yrel*: cint             #*< The relative motion in the Y direction 
  
  PMouseButtonEvent* = ptr TMouseButtonEvent 
  TMouseButtonEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_MOUSEBUTTONDOWN or ::SDL_MOUSEBUTTONUP 
    timestamp*: Uint32
    windowID*: Uint32       #*< The window with mouse focus, if any 
    button*: Uint8          #*< The mouse button index 
    state*: Uint8           #*< ::SDL_PRESSED or ::SDL_RELEASED 
    padding1*: Uint8
    padding2*: Uint8
    x*: cint                #*< X coordinate, relative to window 
    y*: cint                #*< Y coordinate, relative to window 
  
  PMouseWheelEvent* = ptr TMouseWheelEvent 
  TMouseWheelEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_MOUSEWHEEL 
    timestamp*: Uint32
    windowID*: Uint32       #*< The window with mouse focus, if any 
    x*: cint                #*< The amount scrolled horizontally 
    y*: cint                #*< The amount scrolled vertically 
  
  PJoyAxisEvent* = ptr TJoyAxisEvent
  TJoyAxisEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_JOYAXISMOTION 
    timestamp*: Uint32
    which*: Uint8           #*< The joystick device index 
    axis*: Uint8            #*< The joystick axis index 
    padding1*: Uint8
    padding2*: Uint8
    value*: cint            #*< The axis value (range: -32768 to 32767) 
  
  PJoyBallEvent* = ptr TJoyBallEvent
  TJoyBallEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_JOYBALLMOTION 
    timestamp*: Uint32
    which*: Uint8           #*< The joystick device index 
    ball*: Uint8            #*< The joystick trackball index 
    padding1*: Uint8
    padding2*: Uint8
    xrel*: cint             #*< The relative motion in the X direction 
    yrel*: cint             #*< The relative motion in the Y direction 
  
  PJoyHatEvent* = TJoyHatEvent 
  TJoyHatEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_JOYHATMOTION 
    timestamp*: Uint32
    which*: Uint8           #*< The joystick device index 
    hat*: Uint8             #*< The joystick hat index 
    value*: Uint8 #*< The hat position value. \
                  #                            \sa ::SDL_HAT_LEFTUP ::SDL_HAT_UP ::SDL_HAT_RIGHTUP
                  #                            \sa ::SDL_HAT_LEFT ::SDL_HAT_CENTERED ::SDL_HAT_RIGHT
                  #                            \sa ::SDL_HAT_LEFTDOWN ::SDL_HAT_DOWN ::SDL_HAT_RIGHTDOWN
                  #                            
                  #                            Note that zero means the POV is centered.
                  #                         
    padding1*: Uint8
  
  PJoyButtonEvent* = ptr TJoyButtonEvent 
  TJoyButtonEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_JOYBUTTONDOWN or ::SDL_JOYBUTTONUP 
    timestamp*: Uint32
    which*: Uint8           #*< The joystick device index 
    button*: Uint8          #*< The joystick button index 
    state*: Uint8           #*< ::SDL_PRESSED or ::SDL_RELEASED 
    padding1*: Uint8

  
  TTouchID* = int64
  TFingerID* = int64
  TGestureID* = int64

  PTouchFingerEvent* = ptr TTouchFingerEvent
  TTouchFingerEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_FINGERMOTION OR  SDL_FINGERDOWN OR SDL_FINGERUP
    timestamp*: Uint32
    windowID*: Uint32       #*< The window with mouse focus, if any 
    touchId*: TTouchID   #*< The touch device id 
    fingerId*: TFingerID
    state*: Uint8           #*< The current button state 
    padding1*: Uint8
    padding2*: Uint8
    padding3*: Uint8
    x*: Uint16
    y*: Uint16
    dx*: int16
    dy*: int16
    pressure*: Uint16

  PTouchButtonEvent* = ptr TTouchButtonEvent
  TTouchButtonEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_TOUCHBUTTONUP OR SDL_TOUCHBUTTONDOWN 
    timestamp*: Uint32
    windowID*: Uint32       #*< The window with mouse focus, if any 
    touchId*: TTouchID   #*< The touch device index 
    state*: Uint8           #*< The current button state 
    button*: Uint8          #*< The button changing state 
    padding1*: Uint8
    padding2*: Uint8

  PMultiGestureEvent* = ptr TMultiGestureEvent
  TMultiGestureEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_MULTIGESTURE 
    timestamp*: Uint32
    windowID*: Uint32       #*< The window with mouse focus, if any 
    touchId*: TTouchID   #*< The touch device index 
    dTheta*: cfloat
    dDist*: cfloat
    x*: cfloat              # currently 0...1. Change to screen coords? 
    y*: cfloat
    numFingers*: Uint16
    padding*: Uint16
    
  PDollarGestureEvent* = TDollarGestureEvent
  TDollarGestureEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_DOLLARGESTURE 
    timestamp*: Uint32
    windowID*: Uint32       #*< The window with mouse focus, if any 
    touchId*: TTouchID   #*< The touch device index 
    gestureId*: TGestureID
    numFingers*: Uint32
    error*: cfloat #
                   #    //TODO: Enable to give location?
                   #    float x;  //currently 0...1. Change to screen coords?
                   #    float y;  
                   #  
  PDropEvent* = ptr TDropEvent
  TDropEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_DROPFILE 
    timestamp*: Uint32
    file*: cstring          #*< The file name, which should be freed with SDL_free() 
  
  PQuitEvent* = ptr TQuitEvent
  TQuitEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_QUIT 
    timestamp*: Uint32

  PUserEvent* = TUserEvent
  TUserEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_USEREVENT through ::SDL_NUMEVENTS-1 
    timestamp*: Uint32
    windowID*: Uint32       #*< The associated window if any 
    code*: cint             #*< User defined event code 
    data1*: pointer         #*< User defined data pointer 
    data2*: pointer         #*< User defined data pointer 
  
  PSysWMmsg*  = ptr object{.pure, final.} 
  
  PSysWMEvent* = ptr TSysWMEvent
  TSysWMEvent* {.pure, final.} = object 
    kind*: Uint32           #*< ::SDL_SYSWMEVENT 
    timestamp*: Uint32
    msg*: PSysWMmsg  #*< driver dependent data, defined in SDL_syswm.h 
  
  TEventaction* {.size: sizeof(cint).} = enum 
    SDL_ADDEVENT, SDL_PEEKEVENT, SDL_GETEVENT
  TEventFilter* = proc (userdata: pointer; event: ptr TEvent): Bool32 {.cdecl.}
  

  SDL_Return* {.size: sizeof(cint).} = enum SdlError = -1, SdlSuccess = 0 ##\
    ## Return value for many SDL functions. Any function that returns like this \
    ## should also be discardable
  Bool8* {.size: sizeof(byte).} = enum False8 = 0, True8 = 1 ##\
    ## Bool8 used only where the type is an int8 that will be 0 or 1
  Bool32* {.size: sizeof(cint).} = enum False32 = 0, True32 = 1 ##\
    ## SDL_bool
  TKeyState* {.size: sizeof(byte).} = enum KeyPressed = 0, KeyReleased

  TKeySym* {.pure.} = object
    scancode*: cint ##TScancode
    sym*: cint ##TKeycode
    modstate*: int16
    unicode*: cint

  TPoint* = tuple[x, y: cint]
  TRect* = tuple[x, y: cint, w, h: cint]

  TDisplayMode* = object
    format*: cint
    w*, h*, refresh_rate*: cint
    driverData*: pointer
  

  PWindow* = ptr TWindow
  TWindow* {.pure.} = object

  PRenderer* = ptr TRenderer
  TRenderer* {.pure.} = object

  PTexture* = ptr TTexture
  TTexture* {.pure.} = object
  
  PGLContext* = pointer
  
  PCursor* = ptr object{.pure.}
  
  SDL_Version* = object
    major*, minor*, patch*: uint8
   
  PRendererInfo* = ptr TRendererInfo 
  TRendererInfo* {.pure, final.} = object 
    name*: cstring          #*< The name of the renderer 
    flags*: Uint32          #*< Supported ::SDL_RendererFlags 
    num_texture_formats*: Uint32 #*< The number of available texture formats 
    texture_formats*: array[0..16 - 1, Uint32] #*< The available texture formats 
    max_texture_width*: cint #*< The maximimum texture width 
    max_texture_height*: cint #*< The maximimum texture height 
  
  TTextureAccess* {.size: sizeof(cint).} = enum
    SDL_TEXTUREACCESS_STATIC, SDL_TEXTUREACCESS_STREAMING, SDL_TEXTUREACCESS_TARGET
  TTextureModulate*{.size:sizeof(cint).} = enum
    SDL_TEXTUREMODULATE_NONE, SDL_TEXTUREMODULATE_COLOR, SDL_TEXTUREMODULATE_ALPHA
  TRendererFlip* {.size: sizeof(cint).} = enum 
    SDL_FLIP_NONE = 0x00000000, #*< Do not flip 
    SDL_FLIP_HORIZONTAL = 0x00000001, #*< flip horizontally 
    SDL_FLIP_VERTICAL = 0x00000002 #*< flip vertically 
  
  TSysWMType* {.size: sizeof(cint).}=enum
    SysWM_Unknown, SysWM_Windows, SysWM_X11, SysWM_DirectFB,
    SysWM_Cocoa, SysWM_UIkit
  TWMinfo* = object
    version*: SDL_Version
    subsystem*: TSysWMType
    padding*: array[0.. <24, byte] ## if the low-level stuff is important to you check \
      ## SDL_syswm.h and cast padding to the right type

const ## WindowFlags
  SDL_WINDOW_FULLSCREEN* = 0x00000001     #    /**< fullscreen window */
  SDL_WINDOW_OPENGL*     = 0x00000002     #    /**< window usable with OpenGL context */
  SDL_WINDOW_SHOWN*      = 0x00000004     #    /**< window is visible */
  SDL_WINDOW_HIDDEN*     = 0x00000008     #    /**< window is not visible */
  SDL_WINDOW_BORDERLESS* = 0x00000010     #    /**< no window decoration */
  SDL_WINDOW_RESIZABLE*  = 0x00000020     #    /**< window can be resized */
  SDL_WINDOW_MINIMIZED*  = 0x00000040     #    /**< window is minimized */
  SDL_WINDOW_MAXIMIZED*  = 0x00000080     #    /**< window is maximized */
  SDL_WINDOW_INPUT_GRABBED* = 0x00000100  #    /**< window has grabbed input focus */
  SDL_WINDOW_INPUT_FOCUS* = 0x00000200    #    /**< window has input focus */
  SDL_WINDOW_MOUSE_FOCUS* = 0x00000400    #    /**< window has mouse focus */
  SDL_WINDOW_FOREIGN* = 0x00000800

converter toBool*(some: bool32): bool = bool(some)
converter toBool*(some: bool8): bool = bool(some)
converter toBool*(some: SDL_Return): bool = some == SdlSuccess


type 
  TColor* {.pure, final.} = tuple[
    r: Uint8,
    g: Uint8,
    b: Uint8,
    a: Uint8]

  TPalette* {.pure, final.} = object 
    ncolors*: cint
    colors*: ptr TColor
    version*: Uint32
    refcount*: cint

  TPixelFormat* {.pure, final.} = object 
    format*: Uint32
    palette*: ptr TPalette
    BitsPerPixel*: Uint8
    BytesPerPixel*: Uint8
    padding*: array[0..2 - 1, Uint8]
    Rmask*: Uint32
    Gmask*: Uint32
    Bmask*: Uint32
    Amask*: Uint32
    Rloss*: Uint8
    Gloss*: Uint8
    Bloss*: Uint8
    Aloss*: Uint8
    Rshift*: Uint8
    Gshift*: Uint8
    Bshift*: Uint8
    Ashift*: Uint8
    refcount*: cint
    next*: ptr TPixelFormat
  
  PBlitMap* = ptr object{.pure.} ##couldnt find SDL_BlitMap ?
  
  PSurface* = ptr TSurface
  TSurface* {.pure, final.} = object 
    flags*: cint          #*< Read-only 
    format*: ptr TPixelFormat #*< Read-only 
    w*: cint
    h*: cint                #*< Read-only 
    pitch*: cint            #*< Read-only 
    pixels*: pointer        #*< Read-write 
    userdata*: pointer      #*< Read-write  
    locked*: cint           #*< Read-only 
    lock_data*: pointer     #*< Read-only 
    clip_rect*: TRect    #*< Read-only 
    map*: PBlitMap   #*< Private 
    refcount*: cint         #*< Read-mostly 
  
  TBlendMode* {.size: sizeof(cint).} = enum
      BlendMode_None = 0x00000000, #*< No blending 
      BlendMode_Blend = 0x00000001, #*< dst = (src * A) + (dst * (1-A)) 
      BlendMode_Add  = 0x00000002, #*< dst = (src * A) + dst 
      BlendMode_Mod  = 0x00000004 #*< dst = src * dst 
  TBlitFunction* = proc(src: PSurface; srcrect: ptr TRect; dst: PSurface; 
    dstrect: ptr TRect): cint
    
  TTimerCallback* = proc (interval: Uint32; param: pointer): Uint32
  TTimerID* = cint

const ##RendererFlags
  Renderer_Software*: cint = 0x00000001
  Renderer_Accelerated*: cint = 0x00000002 
  Renderer_PresentVsync*: cint = 0x00000004 
  Renderer_TargetTexture*: cint = 0x00000008
  
const  ## These are the currently supported flags for the ::SDL_surface.
  SDL_SWSURFACE* = 0        #*< Just here for compatibility 
  SDL_PREALLOC* = 0x00000001 #*< Surface uses preallocated memory 
  SDL_RLEACCEL* = 0x00000002 #*< Surface is RLE encoded 
  SDL_DONTFREE* = 0x00000004 #*< Surface is referenced internally 

template SDL_MUSTLOCK*(some: PSurface): bool = (some.flags and SDL_RLEACCEL) != 0



const
  INIT_TIMER*       = 0x00000001
  INIT_AUDIO*       = 0x00000010
  INIT_VIDEO*       = 0x00000020
  INIT_JOYSTICK*    = 0x00000200
  INIT_HAPTIC*      = 0x00001000
  INIT_NOPARACHUTE* = 0x00100000      
  INIT_EVERYTHING*  = 0x0000FFFF

const SDL_WINDOWPOS_CENTERED_MASK* = 0x2FFF0000
template SDL_WINDOWPOS_CENTERED_DISPLAY*(X: cint): expr = (SDL_WINDOWPOS_CENTERED_MASK or X)
const SDL_WINDOWPOS_CENTERED* = SDL_WINDOWPOS_CENTERED_DISPLAY(0)
template SDL_WINDOWPOS_ISCENTERED*(X): expr = (((X) and 0xFFFF0000) == SDL_WINDOWPOS_CENTERED_MASK)


template EvConv(name, ptype: expr; valid: set[TEventType]): stmt {.immediate.}=
  proc `name`* (event: var TEvent): ptype =
    assert event.kind in valid
    result = cast[ptype](addr event)

EvConv(EvWindow, PWindowEvent, {WindowEvent})
EvConv(EvKeyboard, PKeyboardEvent, {KeyDown, KeyUP})
EvConv(EvTextEditing, PTextEditingEvent, {TextEditing})
EvConv(EvTextInput, PTextInputEvent, {TextInput})

EvConv(EvMouseMotion, PMouseMotionEvent, {MouseMotion})
EvConv(EvMouseButton, PMouseButtonEvent, {MouseButtonDown, MouseButtonUp})
EvConv(EvMouseWheel, PMouseWheelEvent, {MouseWheel})

EvConv(EvJoyAxis, PJoyAxisEvent, {JoyAxisMotion})
EvConv(EvJoyBall, PJoyBallEvent, {JoyBallMotion})
EvConv(EvJoyHat, PJoyHatEvent, {JoyHatMotion})
EvConv(EvJoyButton, PJoyButtonEvent, {JoyButtonDown, JoyButtonUp})

EvConv(EvTouchFinger, PTouchFingerEvent, {FingerMotion, FingerDown, FingerUp})
EvConv(EvTouchButton, PTouchButtonEvent, {TouchButtonUP, TouchButtonDown})
EvConv(EvMultiGesture, PMultiGestureEvent, {MultiGesture})
EvConv(EvDollarGesture, PDollarGestureEvent, {DollarGesture})

EvConv(EvDropFile, PDropEvent, {DropFile})
EvConv(EvQuit, PQuitEvent, {QuitEvent})

EvConv(EvUser, PUserEvent, {UserEvent, UserEvent1, UserEvent2, UserEvent3, UserEvent4, UserEvent5})
EvConv(EvSysWM, PSysWMEvent, {SysWMEvent})


const ## SDL_MessageBox flags. If supported will display warning icon, etc.
  SDL_MESSAGEBOX_ERROR* = 0x00000010 #*< error dialog 
  SDL_MESSAGEBOX_WARNING* = 0x00000020 #*< warning dialog 
  SDL_MESSAGEBOX_INFORMATION* = 0x00000040 #*< informational dialog 
  
  ## Flags for SDL_MessageBoxButtonData. 
  SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT* = 0x00000001 #*< Marks the default button when return is hit 
  SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT* = 0x00000002 #*< Marks the default button when escape is hit 

type
  TMessageBoxColor* {.pure, final.} = object 
    r*: Uint8
    g*: Uint8
    b*: Uint8

  TMessageBoxColorType* = enum 
    SDL_MESSAGEBOX_COLOR_BACKGROUND, SDL_MESSAGEBOX_COLOR_TEXT, 
    SDL_MESSAGEBOX_COLOR_BUTTON_BORDER, 
    SDL_MESSAGEBOX_COLOR_BUTTON_BACKGROUND, 
    SDL_MESSAGEBOX_COLOR_BUTTON_SELECTED, SDL_MESSAGEBOX_COLOR_MAX
  TMessageBoxColorScheme* {.pure, final.} = object 
    colors*: array[TMessageBoxColorType, TMessageBoxColor]


  TMessageBoxButtonData* {.pure, final.} = object 
    flags*: cint         #*< ::SDL_MessageBoxButtonFlags 
    buttonid*: cint         #*< User defined button id (value returned via SDL_MessageBox) 
    text*: cstring          #*< The UTF-8 button text 
  
  TMessageBoxData* {.pure, final.} = object 
    flags*: cint          #*< ::SDL_MessageBoxFlags 
    window*: PWindow #*< Parent window, can be NULL 
    title*, message*: cstring         #*< UTF-8 title and message text
    numbuttons*: cint
    buttons*: ptr TMessageBoxButtonData
    colorScheme*: ptr TMessageBoxColorScheme #*< ::SDL_MessageBoxColorScheme, can be NULL to use system settings 

  TRWops* {.pure, final.} = object 
    size*: proc (context: ptr TRWops): int64 
    seek*: proc (context: ptr TRWops; offset: int64; whence: cint): int64 
    read*: proc (context: ptr TRWops; destination: pointer; size, maxnum: csize): csize 
    write*: proc (context: ptr TRWops; source: pointer; size: csize; 
                  num: csize): csize 
    close*: proc (context: ptr TRWops): cint
    kind*: cint          
    mem*: TMem
  TMem*{.final.} = object 
    base*: ptr byte
    here*: ptr byte
    stop*: ptr byte

{.push callConv: cdecl, dynlib: LibName.}


proc SDL_Init*(flags: cint): SDL_Return {.importc: "SDL_Init".}
proc SDL_Quit*() {.importc: "SDL_Quit".}

proc GetPlatform*(): cstring {.importc: "SDL_GetPlatform".}

proc GetWMInfo*(window: PWindow; info: var TWMInfo): Bool32 {.
  importc: "SDL_GetWindowWMInfo".}

proc GetVersion*(ver: var SDL_Version) {.
  importc: "SDL_GetVersion".}
proc GetRevision*(): cstring {.importc: "SDL_GetRevision".}
proc GetRevisionNumber*(): cint {.importc: "SDL_GetRevisionNumber".}


proc GetNumRenderDrivers*(): cint {.importc: "SDL_GetNumRenderDrivers".}
proc GetRenderDriverInfo*(index: cint; info: var TRendererInfo): SDL_Return {.
  importc: "SDL_GetRenderDriverInfo".}
proc CreateWindowAndRenderer*(width, height: cint; window_flags: Uint32; 
  window: ptr PWindow; renderer: ptr PRenderer): SDL_Return {.
  importc: "SDL_CreateWindowAndRenderer".}

proc CreateRenderer*(window: PWindow; index: cint; flags: cint): PRenderer {.
  importc: "SDL_CreateRenderer".}
proc CreateSoftwareRenderer*(surface: PSurface): PRenderer {.
  importc: "SDL_CreateSoftwareRenderer".}
proc GetRenderer*(window: PWindow): PRenderer {.importc: "SDL_GetRenderer".}
proc GetRendererInfo*(renderer: PRenderer; info: PRendererInfo): cint {.
  importc: "SDL_GetRendererInfo".}

proc CreateTexture*(renderer: PRenderer; format: Uint32; 
  access, w, h: cint): PTexture {.importc: "SDL_CreateTexture".}

proc CreateTextureFromSurface*(renderer: PRenderer; surface: PSurface): PTexture {.
  importc: "SDL_CreateTextureFromSurface".}

proc QueryTexture*(texture: PTexture; format: ptr Uint32; 
  access, w, h: ptr cint): SDL_Return {.importc: "SDL_QueryTexture".}

proc SetTextureColorMod*(texture: PTexture; r, g, b: Uint8): SDL_Return {.
  importc: "SDL_SetTextureColorMod".}

proc GetTextureColorMod*(texture: PTexture; r, g, b: var Uint8): SDL_Return {.
  importc: "SDL_GetTextureColorMod".}

proc SetTextureAlphaMod*(texture: PTexture; alpha: Uint8): SDL_Return {.
  importc: "SDL_GetTextureAlphaMod", discardable.}

proc GetTextureAlphaMod*(texture: PTexture; alpha: var Uint8): SDL_Return {.
  importc: "SDL_GetTextureAlphaMod", discardable.}
  
proc SetTextureBlendMode*(texture: PTexture; blendMode: TBlendMode): SDL_Return {.
  importc: "SDL_SetTextureBlendMode", discardable.}
  
proc GetTextureBlendMode*(texture: PTexture; 
  blendMode: var TBlendMode): SDL_Return {.importc: "SDL_GetTextureBlendMode", discardable.}

proc UpdateTexture*(texture: PTexture; rect: ptr TRect; pixels: pointer; 
  pitch: cint): SDL_Return {.importc: "SDL_UpdateTexture", discardable.}

proc LockTexture*(texture: PTexture; rect: ptr TRect; pixels: ptr pointer; 
  pitch: ptr cint): SDL_Return {.importc: "SDL_LockTexture", discardable.}

proc UnlockTexture*(texture: PTexture) {.importc: "SDL_UnlockTexture".}

proc RenderTargetSupported*(renderer: PRenderer): Bool32 {.
  importc: "SDL_RenderTargetSupported".}

proc SetRenderTarget*(renderer: PRenderer; texture: PTexture): SDL_Return {.
  importc: "SDL_SetRenderTarget".}
#*
# 
proc GetRenderTarget*(renderer: PRenderer): PTexture {.
  importc: "SDL_GetRenderTarget".}
proc RenderSetLogicalSize*(renderer: PRenderer; w, h: cint): cint {.importc: "SDL_RenderSetLogicalSize".}

proc RenderGetLogicalSize*(renderer: PRenderer; w, h: var cint) {.
  importc: "SDL_RenderGetLogicalSize".}
#*
#   \brief Set the drawing area for rendering on the current target.
# 
#   \param rect The rectangle representing the drawing area, or NULL to set the viewport to the entire target.
# 
#   The x,y of the viewport rect represents the origin for rendering.
# 
#   \note When the window is resized, the current viewport is automatically
#         centered within the new window size.
# 
#   \sa SDL_RenderGetViewport()
#   \sa SDL_RenderSetLogicalSize()
# 
proc SetViewport*(renderer: PRenderer; rect: ptr TRect): SDL_Return {.
  importc: "SDL_RenderSetViewport", discardable.}
proc GetViewport*(renderer: PRenderer; rect: var TRect) {.
  importc: "SDL_RenderGetViewport".}

proc SetScale*(renderer: PRenderer; scaleX, scaleY: cfloat): SDL_Return {.
  importc: "SDL_RenderSetScale", discardable.}
proc GetScale*(renderer: PRenderer; scaleX, scaleY: var cfloat) {.
  importc: "SDL_RenderGetScale".}

proc SetDrawColor*(renderer: PRenderer; r, g, b: uint8, a = 255'u8): SDL_Return {.
  importc: "SDL_SetRenderDrawColor", discardable.}
proc GetDrawColor*(renderer: PRenderer; r, g, b, a: var uint8): SDL_Return {.
  importc: "SDL_GetRenderDrawColor", discardable.}

proc SetDrawBlendMode*(renderer: PRenderer; blendMode: TBlendMode): SDL_Return {.
  importc: "SDL_SetRenderDrawBlendMode", discardable.}

proc GetDrawBlendMode*(renderer: PRenderer; 
  blendMode: var TBlendMode): SDL_Return {.
  importc: "SDL_GetRenderDrawBlendMode", discardable.}

proc DrawPoint*(renderer: PRenderer; x, y: cint): SDL_Return {.
  importc: "SDL_RenderDrawPoint", discardable.}
#*
proc DrawPoints*(renderer: PRenderer; points: ptr TPoint; 
  count: cint): SDL_Return {.importc: "SDL_RenderDrawPoints", discardable.}

proc DrawLine*(renderer: PRenderer; 
  x1, y1, x2, y2: cint): SDL_Return {.
  importc: "SDL_RenderDrawLine", discardable.}
#*
proc DrawLines*(renderer: PRenderer; points: ptr TPoint; 
  count: cint): SDL_Return {.importc: "SDL_RenderDrawLines", discardable.}

proc DrawRect*(renderer: PRenderer; rect: var TRect): SDL_Return{.
  importc: "SDL_RenderDrawRect", discardable.}

proc DrawRects*(renderer: PRenderer; rects: ptr TRect; 
  count: cint): SDL_Return {.importc: "SDL_RenderDrawRects".}
proc FillRect*(renderer: PRenderer; rect: var TRect): SDL_Return {.
  importc: "SDL_RenderFillRect", discardable.}
proc FillRect*(renderer: PRenderer; rect: ptr TRect = nil): SDL_Return {.
  importc: "SDL_RenderFillRect", discardable.}
#*
proc FillRects*(renderer: PRenderer; rects: ptr TRect; 
  count: cint): SDL_Return {.importc: "SDL_RenderFillRects", discardable.}

proc Copy*(renderer: PRenderer; texture: PTexture; 
                     srcrect, dstrect: ptr TRect): SDL_Return {.
  importc: "SDL_RenderCopy", discardable.}

proc CopyEx*(renderer: PRenderer; texture: PTexture; 
                       srcrect, dstrect: var TRect; 
                       angle: cdouble; center: ptr TPoint; 
                       flip: TRendererFlip = SDL_FLIP_NONE): SDL_Return {.
                       importc: "SDL_RenderCopyEx", discardable.}


proc Clear*(renderer: PRenderer): cint {.
  importc: "SDL_RenderClear", discardable.}

proc ReadPixels*(renderer: PRenderer; rect: var TRect; format: cint; 
  pixels: pointer; pitch: cint): cint {.importc: "SDL_RenderReadPixels".}
proc Present*(renderer: PRenderer) {.importc: "SDL_RenderPresent".}

proc destroy*(texture: PTexture) {.importc: "SDL_DestroyTexture".}
proc destroy*(renderer: PRenderer) {.importc: "SDL_DestroyRenderer".}


proc bindTexture*(texture: PTexture; texw, texh: var cfloat): cint {.
  importc: "SDL_GL_BindTexture".}
proc unbindTexture*(texture: PTexture) {.importc: "SDL_GL_UnbindTexture".}

proc CreateRGBSurface*(flags: cint; width, height, depth: cint; 
  Rmask, Gmask, BMask, Amask: cint): PSurface {.importc: "SDL_CreateRGBSurface".}
proc CreateRGBSurfaceFrom*(pixels: pointer; width, height, depth, pitch: cint;
  Rmask, Gmask, Bmask, Amask: cint): PSurface {.
  importc: "SDL_CreateRGBSurfaceFrom".}

proc destroy*(surface: PSurface) {.importc: "SDL_FreeSurface".}

proc SetSurfacePalette*(surface: PSurface; palette: ptr TPalette): cint {.
  importc:"SDL_SetSurfacePalette".}
#*
#   \brief Sets up a surface for directly accessing the pixels.
#   
#   Between calls to SDL_LockSurface() / SDL_UnlockSurface(), you can write
#   to and read from \c surface->pixels, using the pixel format stored in 
#   \c surface->format.  Once you are done accessing the surface, you should 
#   use SDL_UnlockSurface() to release it.
#   
#   Not all surfaces require locking.  If SDL_MUSTLOCK(surface) evaluates
#   to 0, then you can read and write to the surface at any time, and the
#   pixel format of the surface will not change.
#   
#   No operating system or library calls should be made between lock/unlock
#   pairs, as critical system locks may be held during this time.
#   
#   SDL_LockSurface() returns 0, or -1 if the surface couldn't be locked.
#   
#   \sa SDL_UnlockSurface()
# 
proc LockSurface*(surface: PSurface): cint {.importc: "SDL_LockSurface".}
#* \sa SDL_LockSurface() 
proc UnlockSurface*(surface: PSurface) {.importc: "SDL_UnlockSurface".}
#*
#   Load a surface from a seekable SDL data stream (memory or file).
#   
#   If \c freesrc is non-zero, the stream will be closed after being read.
#   
#   The new surface should be freed with SDL_FreeSurface().
#   
#   \return the new surface, or NULL if there was an error.
# 
proc LoadBMP_RW*(src: ptr TRWops; freesrc: cint): PSurface {.
  importc: "SDL_LoadBMP_RW".}



proc RWFromFile*(file: cstring; mode: cstring): ptr TRWops {.importc: "SDL_RWFromFile".}
proc RWFromFP*(fp: TFILE; autoclose: Bool32): ptr TRWops {.importc: "SDL_RWFromFP".}
proc RWFromMem*(mem: pointer; size: cint): ptr TRWops {.importc: "SDL_RWFromMem".}
proc RWFromConstMem*(mem: pointer; size: cint): ptr TRWops {.importc: "SDL_RWFromConstMem".}

#*
#   Load a surface from a file.
#   
#   Convenience macro.
# 
#*
proc SaveBMP_RW*(surface: PSurface; dst: ptr TRWops; 
                     freedst: cint): SDL_Return {.importc: "SDL_SaveBMP_RW".}

proc SetSurfaceRLE*(surface: PSurface; flag: cint): cint {.
  importc:"SDL_SetSurfaceRLE".}
proc SetColorKey*(surface: PSurface; flag: cint; key: Uint32): cint {.
  importc: "SDL_SetColorKey".}

proc GetColorKey*(surface: PSurface; key: var Uint32): cint {.
  importc: "SDL_GetColorKey".}
proc SetSurfaceColorMod*(surface: PSurface; r, g, b: Uint8): cint {.
  importc: "SDL_SetSurfaceColorMod".}

proc GetSurfaceColorMod*(surface: PSurface; r, g, b: var Uint8): cint {.
  importc: "SDL_GetSurfaceColorMod".}

proc SetSurfaceAlphaMod*(surface: PSurface; alpha: Uint8): cint {.
  importc: "SDL_SetSurfaceAlphaMod".}
proc GetSurfaceAlphaMod*(surface: PSurface; alpha: var Uint8): cint {.
  importc: "SDL_GetSurfaceAlphaMod".}

proc SetSurfaceBlendMode*(surface: PSurface; blendMode: TBlendMode): cint {.
  importc: "SDL_SetSurfaceBlendMode".}
proc GetSurfaceBlendMode*(surface: PSurface; blendMode: ptr TBlendMode): cint {.
  importc: "SDL_GetSurfaceBlendMode".}

proc SetClipRect*(surface: PSurface; rect: ptr TRect): bool32 {.
  importc: "SDL_SetClipRect".}
proc GetClipRect*(surface: PSurface; rect: ptr TRect) {.
  importc: "SDL_GetClipRect".}

proc ConvertSurface*(src: PSurface; fmt: ptr TPixelFormat; 
  flags: cint): PSurface {.importc: "SDL_ConvertSurface".}
proc ConvertSurfaceFormat*(src: PSurface; pixel_format, 
  flags: Uint32): PSurface {.importc: "SDL_ConvertSurfaceFormat".}

proc ConvertPixels*(width, height: cint; src_format: Uint32; src: pointer; 
  src_pitch: cint; dst_format: Uint32; dst: pointer; dst_pitch: cint): cint {.
  importc: "SDL_ConvertPixels".}
#*
#   Performs a fast fill of the given rectangle with \c color.
#   
#   If \c rect is NULL, the whole surface will be filled with \c color.
#   
#   The color should be a pixel of the format used by the surface, and 
#   can be generated by the SDL_MapRGB() function.
#   
#   \return 0 on success, or -1 on error.
# 
proc FillRect*(dst: PSurface; rect: ptr TRect; color: Uint32): SDL_Return {.
  importc: "SDL_FillRect", discardable.}
proc FillRects*(dst: PSurface; rects: ptr TRect; count: cint; 
                    color: Uint32): cint {.importc: "SDL_FillRects".}

proc UpperBlit*(src: PSurface; srcrect: ptr TRect; dst: PSurface; 
  dstrect: ptr TRect): SDL_Return {.importc: "SDL_UpperBlit".}

proc LowerBlit*(src: PSurface; srcrect: ptr TRect; dst: PSurface; 
  dstrect: ptr TRect): SDL_Return {.importc: "SDL_LowerBlit".}

proc SoftStretch*(src: PSurface; srcrect: ptr TRect; dst: PSurface; 
  dstrect: ptr TRect): SDL_Return {.importc: "SDL_SoftStretch".}


proc UpperBlitScaled*(src: PSurface; srcrect: ptr TRect; dst: PSurface; 
  dstrect: ptr TRect): SDL_Return {.importc: "SDL_UpperBlitScaled".}
proc LowerBlitScaled*(src: PSurface; srcrect: ptr TRect; dst: PSurface; 
  dstrect: ptr TRect): SDL_Return {.importc: "SDL_LowerBlitScaled".} 



proc ReadU8*(src: ptr TRWops): Uint8 {.importc: "SDL_ReadU8".}
proc ReadLE16*(src: ptr TRWops): Uint16 {.importc: "SDL_ReadLE16".}
proc ReadBE16*(src: ptr TRWops): Uint16 {.importc: "SDL_ReadBE16".}
proc ReadLE32*(src: ptr TRWops): Uint32 {.importc: "SDL_ReadLE32".}
proc ReadBE32*(src: ptr TRWops): Uint32 {.importc: "SDL_ReadBE32".}
proc ReadLE64*(src: ptr TRWops): Uint64 {.importc: "SDL_ReadLE64".}
proc ReadBE64*(src: ptr TRWops): Uint64 {.importc: "SDL_ReadBE64".}
proc WriteU8*(dst: ptr TRWops; value: Uint8): csize {.importc: "SDL_WriteU8".}
proc WriteLE16*(dst: ptr TRWops; value: Uint16): csize {.importc: "SDL_WriteLE16".}
proc WriteBE16*(dst: ptr TRWops; value: Uint16): csize {.importc: "SDL_WriteBE16".}
proc WriteLE32*(dst: ptr TRWops; value: Uint32): csize {.importc: "SDL_WriteLE32".}
proc WriteBE32*(dst: ptr TRWops; value: Uint32): csize {.importc: "SDL_WriteBE32".}
proc WriteLE64*(dst: ptr TRWops; value: Uint64): csize {.importc: "SDL_WriteLE64".}
proc WriteBE64*(dst: ptr TRWops; value: Uint64): csize {.importc: "SDL_WriteBE64".}

proc ShowMessageBox*(messageboxdata: ptr TMessageBoxData; 
  buttonid: var cint): cint {.importc: "SDL_ShowMessageBox".}

proc ShowSimpleMessageBox*(flags: Uint32; title, message: cstring; 
  window: PWindow): cint {.importc: "SDL_ShowSimpleMessageBox".}
  #   \return 0 on success, -1 on error





proc GetNumVideoDrivers*(): cint {.importc: "SDL_GetNumVideoDrivers".}
proc GetVideoDriver*(index: cint): cstring {.importc: "SDL_GetVideoDriver".}
proc VideoInit*(driver_name: cstring): SDL_Return {.importc: "SDL_VideoInit".}
proc VideoQuit*() {.importc: "SDL_VideoQuit".}
proc GetCurrentVideoDriver*(): cstring {.importc: "SDL_GetCurrentVideoDriver".}
proc GetNumVideoDisplays*(): cint {.importc: "SDL_GetNumVideoDisplays".}

proc GetDisplayBounds*(displayIndex: cint; rect: var TRect): SDL_Return {.
  importc: "SDL_GetDisplayBounds".}
proc GetNumDisplayModes*(displayIndex: cint): cint {.importc: "SDL_GetNumDisplayModes".}
#*
proc GetDisplayMode*(displayIndex: cint; modeIndex: cint; 
  mode: var TDisplayMode): SDL_Return {.importc: "SDL_GetDisplayMode".}
                         
proc GetDesktopDisplayMode*(displayIndex: cint; 
  mode: var TDisplayMode): SDL_Return {.importc: "SDL_GetDesktopDisplayMode".}
proc GetCurrentDisplayMode*(displayIndex: cint; 
  mode: var TDisplayMode): SDL_Return {.importc: "SDL_GetCurrentDisplayMode".}

proc GetClosestDisplayMode*(displayIndex: cint; mode: ptr TDisplayMode; 
                                closest: ptr TDisplayMode): ptr TDisplayMode {.importc: "SDL_GetClosestDisplayMode".}
#*
proc GetDisplayIndex*(window: PWindow): cint {.importc: "SDL_GetWindowDisplayIndex".}
#*
proc SetDisplayMode*(window: PWindow; 
  mode: ptr TDisplayMode): SDL_Return {.importc: "SDL_SetWindowDisplayMode".}
#*
proc GetDisplayMode*(window: PWindow; mode: var TDisplayMode): cint  {.
  importc: "SDL_GetWindowDisplayMode".}
#*
proc GetPixelFormat*(window: PWindow): Uint32 {.importc: "SDL_GetWindowPixelFormat".}
#*
proc CreateWindow*(title: cstring; x, y, w, h: cint; 
                       flags: Uint32): PWindow  {.importc: "SDL_CreateWindow".}
#*
proc CreateWindowFrom*(data: pointer): PWindow {.importc: "SDL_CreateWindowFrom".}
#*
#   \brief Get the numeric ID of a window, for logging purposes.
# 
proc GetID*(window: PWindow): Uint32 {.importc: "SDL_GetWindowID".}
#*
#   \brief Get a window from a stored ID, or NULL if it doesn't exist.
# 
proc GetWindowFromID*(id: Uint32): PWindow {.importc: "SDL_GetWindowFromID".}
#*
#   \brief Get the window flags.
# 
proc GetFlags*(window: PWindow): Uint32 {.importc: "SDL_GetWindowFlags".}
#*
#   \brief Set the title of a window, in UTF-8 format.
#   
#   \sa SDL_GetWindowTitle()
# 
proc SetTitle*(window: PWindow; title: cstring) {.importc: "SDL_SetWindowTitle".}
#*
#   \brief Get the title of a window, in UTF-8 format.
#   
#   \sa SDL_SetWindowTitle()
# 
proc GetTitle*(window: PWindow): cstring {.importc: "SDL_GetWindowTitle".}
#*
#   \brief Set the icon for a window.
#   
#   \param icon The icon for the window.
# 
proc SetIcon*(window: PWindow; icon: PSurface) {.importc: "SDL_SetWindowIcon".}
#*
proc SetData*(window: PWindow; name: cstring; 
  userdata: pointer): pointer {.importc: "SDL_SetWindowData".}
#*
proc GetData*(window: PWindow; name: cstring): pointer {.importc: "SDL_GetWindowData".}
#*
proc SetPosition*(window: PWindow; x, y: cint) {.importc: "SDL_SetWindowPosition".}
proc GetPosition*(window: PWindow; x, y: var cint)  {.importc: "SDL_GetWindowPosition".}
#*
proc SetSize*(window: PWindow; w, h: cint)  {.importc: "SDL_SetWindowSize".}
proc GetSize*(window: PWindow; w, h: var cint) {.importc: "SDL_GetWindowSize".}

proc SetBordered*(window: PWindow; bordered: bool32) {.importc: "SDL_SetWindowBordered".}
#
proc ShowWindow*(window: PWindow) {.importc: "SDL_ShowWindow".}
proc HideWindow*(window: PWindow) {.importc: "SDL_HideWindow".}
#*
proc RaiseWindow*(window: PWindow) {.importc: "SDL_RaiseWindow".}
proc MaximizeWindow*(window: PWindow) {.importc: "SDL_MaximizeWindow".}
proc MinimizeWindow*(window: PWindow) {.importc: "SDL_MinimizeWindow".}
#*
# 
proc RestoreWindow*(window: PWindow) {.importc: "SDL_RestoreWindow".}

proc SetFullscreen*(window: PWindow; fullscreen: bool32): SDL_Return {.importc: "SDL_SetWindowFullscreen".}
proc GetSurface*(window: PWindow): PSurface {.importc: "SDL_GetWindowSurface".}

proc UpdateSurface*(window: PWindow): SDL_Return  {.importc: "SDL_UpdateWindowSurface".}
proc UpdateSurfaceRects*(window: PWindow; rects: ptr TRect; 
  numrects: cint): SDL_Return  {.importc: "SDL_UpdateWindowSurfaceRects".}
#*
proc SetGrab*(window: PWindow; grabbed: bool32) {.importc: "SDL_SetWindowGrab".}
proc GetGrab*(window: PWindow): bool32 {.importc: "SDL_GetWindowGrab".}
proc SetBrightness*(window: PWindow; brightness: cfloat): SDL_Return {.importc: "SDL_SetWindowBrightness".}

proc GetBrightness*(window: PWindow): cfloat {.importc: "SDL_GetWindowBrightness".}

proc SetGammaRamp*(window: PWindow; 
  red, green, blue: ptr Uint16): SDL_Return {.importc: "SDL_SetWindowGammaRamp".}
#*
#   \brief Get the gamma ramp for a window.
#   
#   \param red   A pointer to a 256 element array of 16-bit quantities to hold 
#                the translation table for the red channel, or NULL.
#   \param green A pointer to a 256 element array of 16-bit quantities to hold 
#                the translation table for the green channel, or NULL.
#   \param blue  A pointer to a 256 element array of 16-bit quantities to hold 
#                the translation table for the blue channel, or NULL.
#    
#   \return 0 on success, or -1 if gamma ramps are unsupported.
#   
#   \sa SDL_SetWindowGammaRamp()
# 
proc GetGammaRamp*(window: PWindow; red: ptr Uint16; 
                               green: ptr Uint16; blue: ptr Uint16): cint {.importc: "SDL_GetWindowGammaRamp".}
                               
proc Destroy*(window: PWindow) {.importc: "SDL_DestroyWindow".}
proc IsScreenSaverEnabled*(): Bool32 {.importc: "SDL_IsScreenSaverEnabled".}
proc EnableScreenSaver*() {.importc: "SDL_EnableScreenSaver".}
proc DisableScreenSaver*() {.importc: "SDL_DisableScreenSaver".}


proc GetTicks*(): Uint32 {.importc: "SDL_GetTicks".}
proc GetPerformanceCounter*(): Uint64 {.importc: "SDL_GetPerformanceCounter".}
proc GetPerformanceFrequency*(): Uint64 {.importc: "SDL_GetPerformanceFrequency".}
proc Delay*(ms: Uint32) {.importc: "SDL_Delay".}
#*
#  \brief Add a new timer to the pool of timers already running.
# 
#  \return A timer ID, or NULL when an error occurs.
# 
proc AddTimer*(interval: Uint32; callback: TTimerCallback; 
      param: pointer): TTimerID {.importc: "SDL_AddTimer".}
#*
#  \brief Remove a timer knowing its ID.
# 
#  \return A boolean value indicating success or failure.
# 
#  \warning It is not safe to remove a timer multiple times.
# 
proc RemoveTimer*(id: TTimerID): bool32 {.importc: "SDL_RemoveTimer".}


#*
#   \name OpenGL support functions
# 
#@{
#*
#   \brief Dynamically load an OpenGL library.
#   
#   \param path The platform dependent OpenGL library name, or NULL to open the 
#               default OpenGL library.
#   
#   \return 0 on success, or -1 if the library couldn't be loaded.
#   
#   This should be done after initializing the video driver, but before
#   creating any OpenGL windows.  If no OpenGL library is loaded, the default
#   library will be loaded upon creation of the first OpenGL window.
#   
#   \note If you do this, you need to retrieve all of the GL functions used in
#         your program from the dynamic library using SDL_GL_GetProcAddress().
#   
#   \sa SDL_GL_GetProcAddress()
#   \sa SDL_GL_UnloadLibrary()
# 


##SDL_keyboard.h:
proc GetKeyboardFocus*: PWindow {.importc: "SDL_GetKeyboardFocus".}
  #Get the window which currently has keyboard focus.
proc GetKeyboardState*(numkeys: ptr int = nil): ptr array[0 .. SDL_NUM_SCANCODES.int, uint8] {.importc: "SDL_GetKeyboardState".}
  #Get the snapshot of the current state of the keyboard
proc GetModState*: TKeymod {.importc: "SDL_GetModState".}
  #Get the current key modifier state for the keyboard
proc SetModState*(state: TKeymod) {.importc: "SDL_SetModState".}
  #Set the current key modifier state for the keyboard
proc GetKeyFromScancode*(scancode: TScanCode): cint {.importc: "SDL_GetKeyFromScancode".}
  #Get the key code corresponding to the given scancode according to the current keyboard layout
proc GetScancodeFromKey*(key: cint): TScanCode {.importc: "SDL_GetScancodeFromKey".}
  #Get the scancode corresponding to the given key code according to the current keyboard layout
proc GetScancodeName*(scancode: TScanCode): cstring {.importc: "SDL_GetScancodeName".}
  #Get a human-readable name for a scancode
proc GetScancodeFromName*(name: cstring): TScanCode {.importc: "SDL_GetScancodeFromName".}
  #Get a scancode from a human-readable name
proc GetKeyname*(key: cint): cstring {.importc: "SDL_GetKeyName".}
  #Get a human-readable name for a key
proc GetKeyFromName*(name: cstring): cint {.importc: "SDL_GetKeyFromName".}
  #Get a key code from a human-readable name
proc StartTextInput* {.importc: "SDL_StartTextInput".}
  #Start accepting Unicode text input events
proc IsTextInputActive*: bool {.importc: "SDL_IsTextInputActive".}
proc StopTextInput* {.importc: "SDL_StopTextInput".}
proc SetTextInputRect*(rect: ptr TRect) {.importc: "SDL_SetTextInputRect".}
proc HasScreenKeyboardSupport*: bool {.importc: "SDL_HasScreenKeyboardSupport".}
proc IsScreenKeyboardShown*(window: PWindow): bool {.importc: "SDL_IsScreenKeyboardShown".}



proc GetMouseFocus*(): PWindow {.importc: "SDL_GetMouseFocus".}
#*
#   \brief Retrieve the current state of the mouse.
#   
#   The current button state is returned as a button bitmask, which can
#   be tested using the SDL_BUTTON(X) macros, and x and y are set to the
#   mouse cursor position relative to the focus window for the currently
#   selected mouse.  You can pass NULL for either x or y.
# 
proc GetMouseState*(x, y: var cint): Uint8 {.importc: "SDL_GetMouseState", discardable.}
proc GetMouseState*(x, y: ptr cint): Uint8 {.importc: "SDL_GetMouseState", discardable.}
#*
proc GetRelativeMouseState*(x, y: var cint): Uint8 {.
  importc: "SDL_GetRelativeMouseState".}
#*
proc WarpMouseInWindow*(window: PWindow; x, y: cint)  {.
  importc: "SDL_WarpMouseInWindow".}
#*
proc SetRelativeMouseMode*(enabled: bool32): SDL_Return  {.
  importc: "SDL_SetRelativeMouseMode".}
#*
proc GetRelativeMouseMode*(): bool32 {.importc: "SDL_GetRelativeMouseMode".}
#*
proc CreateCursor*(data, mask: ptr Uint8; 
  w, h, hot_x, hot_y: cint): PCursor {.importc: "SDL_CreateCursor".}
#*
proc CreateColorCursor*(surface: PSurface; hot_x, hot_y: cint): PCursor {.
  importc: "SDL_CreateColorCursor".}
proc SetCursor*(cursor: PCursor) {.importc: "SDL_SetCursor".}
proc GetCursor*(): PCursor {.importc: "SDL_GetCursor".}
proc destroy*(cursor: PCursor) {.importc: "SDL_FreeCursor".}
proc ShowCursor*(toggle: bool): Bool32 {.importc: "SDL_ShowCursor", discardable.}


# Function prototypes 
#*
#   Pumps the event loop, gathering events from the input devices.
#   
#   This function updates the event queue and internal input device state.
#   
#   This should only be run in the thread that sets the video mode.
# 
proc PumpEvents*() {.importc: "SDL_PumpEvents".}

#*
#   Checks the event queue for messages and optionally returns them.
#   
#   If \c action is ::SDL_ADDEVENT, up to \c numevents events will be added to
#   the back of the event queue.
#   
#   If \c action is ::SDL_PEEKEVENT, up to \c numevents events at the front
#   of the event queue, within the specified minimum and maximum type,
#   will be returned and will not be removed from the queue.
#   
#   If \c action is ::SDL_GETEVENT, up to \c numevents events at the front 
#   of the event queue, within the specified minimum and maximum type,
#   will be returned and will be removed from the queue.
#   
#   \return The number of events actually stored, or -1 if there was an error.
#   
#   This function is thread-safe.
# 
proc PeepEvents*(events: ptr TEvent; numevents: cint; action: TEventaction; 
  minType: Uint32; maxType: Uint32): cint {.importc: "SDL_PeepEvents".}
#@}
#*
#   Checks to see if certain event types are in the event queue.
# 
proc HasEvent*(kind: Uint32): bool32 {.importc: "SDL_HasEvent".}
proc HasEvents*(minType: Uint32; maxType: Uint32): bool32 {.importc: "SDL_HasEvents".}
proc FlushEvent*(kind: Uint32) {.importc: "SDL_FlushEvent".}
proc FlushEvents*(minType: Uint32; maxType: Uint32) {.importc: "SDL_FlushEvents".}

proc PollEvent*(event: var TEvent): Bool32 {.importc: "SDL_PollEvent".}
proc WaitEvent*(event: var TEvent): Bool32 {.importc: "SDL_WaitEvent".}
proc WaitEventTimeout*(event: var TEvent; timeout: cint): Bool32 {.importc: "SDL_WaitEventTimeout".}
#*
#   \brief Add an event to the event queue.
#   
#   \return 1 on success, 0 if the event was filtered, or -1 if the event queue 
#           was full or there was some other error.
# 
proc PushEvent*(event: ptr TEvent): cint {.importc: "SDL_PushEvent".}

#*
proc SetEventFilter*(filter: TEventFilter; userdata: pointer) {.importc: "SDL_SetEventFilter".}
#*
#   Return the current event filter - can be used to "chain" filters.
#   If there is no event filter set, this function returns SDL_FALSE.
# 
proc GetEventFilter*(filter: var TEventFilter; userdata: var pointer): bool32 {.importc: "SDL_GetEventFilter".}
#*
#   Add a function which is called when an event is added to the queue.
# 
proc AddEventWatch*(filter: TEventFilter; userdata: pointer) {.importc: "SDL_AddEventWatch".}
#*
#   Remove an event watch function added with SDL_AddEventWatch()
# 
proc DelEventWatch*(filter: TEventFilter; userdata: pointer) {.importc: "SDL_DelEventWatch".}
#*
#   Run the filter function on the current event queue, removing any
#   events for which the filter returns 0.
# 
proc FilterEvents*(filter: TEventFilter; userdata: pointer) {.importc: "SDL_FilterEvents".}
#@{
#
#/**
#   This function allows you to set the state of processing certain events.
#    - If \c state is set to ::SDL_IGNORE, that event will be automatically 
#      dropped from the event queue and will not event be filtered.
#    - If \c state is set to ::SDL_ENABLE, that event will be processed 
#      normally.
#    - If \c state is set to ::SDL_QUERY, SDL_EventState() will return the 
#      current processing state of the specified event.
# 
proc EventState*(kind: TEventType; state: cint): Uint8 {.importc: "SDL_EventState".}
#@}
#
#/**
#   This function allocates a set of user-defined events, and returns
#   the beginning event number for that set of events.
# 
#   If there aren't enough user-defined events left, this function
#   returns (Uint32)-1
# 
proc RegisterEvents*(numevents: cint): Uint32 {.importc: "SDL_RegisterEvents".}


proc SetError*(fmt: cstring) {.varargs, importc: "SDL_SetError".}
proc GetError*(): cstring {.importc: "SDL_GetError".}
proc ClearError*() {.importc: "SDL_ClearError".}



proc GL_CreateContext*(window: PWindow): PGLContext {.importc: "SDL_GL_CreateContext".}
  ## Create an OpenGL context for use with an OpenGL window, and make it current.
proc GL_SwapWindow*(window: PWindow) {.importc: "SDL_GL_SwapWindow".}
  ## Swap the OpenGL buffers for a window, if double-buffering is supported.


{.pop.}

const
  SDL_QUERY* = -1
  SDL_IGNORE* = 0
  SDL_DISABLE* = 0
  SDL_ENABLE* = 1

##define SDL_GetEventState(type) SDL_EventState(type, SDL_QUERY)
proc GetEventState*(kind: TEventType): uint8 {.inline.} = EventState(kind, SDL_QUERY)

import unsigned
##define SDL_BUTTON(X)		(1 << ((X)-1))
template SDL_BUTTON*(x: uint8): uint8 = (1'u8 shl (x - 1'u8))
const 
  BUTTON_LEFT* = 1'u8
  BUTTON_MIDDLE* = 2'u8
  BUTTON_RIGHT* = 3'u8
  BUTTON_X1* = 4'u8
  BUTTON_X2* = 5'u8
  BUTTON_LMASK* = SDL_BUTTON(BUTTON_LEFT)
  BUTTON_MMASK* = SDL_BUTTON(BUTTON_MIDDLE)
  BUTTON_RMASK* = SDL_BUTTON(BUTTON_RIGHT)
  BUTTON_X1MASK* = SDL_BUTTON(BUTTON_X1)
  BUTTON_X2MASK* = SDL_BUTTON(BUTTON_X2)


               
## compatibility functions

proc DestroyTexture*(texture: PTexture) {.inline.} = destroy(texture)
proc DestroyRenderer*(renderer: PRenderer) {.inline.} = destroy(renderer)
proc FreeCursor*(cursor: PCursor) {.inline.} = destroy(cursor)
proc FreeSurface*(surface: PSurface) {.inline.} = destroy(surface)

proc BlitSurface*(src: PSurface; srcrect: ptr TRect; dst: PSurface; 
  dstrect: ptr TRect): SDL_Return {.inline, discardable.} = UpperBlit(src, srcrect, dst, dstrect)
proc BlitScaled*(src: PSurface; srcrect: ptr TRect; dst: PSurface; 
  dstrect: ptr TRect): SDL_Return {.inline, discardable.} = UpperBlitScaled(src, srcrect, dst, dstrect) 

#/#define SDL_LoadBMP(file)	SDL_LoadBMP_RW(SDL_RWFromFile(file, "rb"), 1)
proc LoadBMP*(file: string): PSurface {.inline.} = LoadBMP_RW(RWFromFile(cstring(file), "rb"), 1)
##define SDL_SaveBMP(surface, file) \
#  SDL_SaveBMP_RW(surface, SDL_RWFromFile(file, "wb"), 1)
proc SaveBMP*(surface: PSurface; file: string): SDL_Return {.
  inline, discardable.} = SaveBMP_RW(surface, RWFromFile(file, "wb"), 1)

proc Color*(r, g, b, a: range[0..255]): TColor = (r.uint8, g.uint8, b.uint8, a.uint8)

proc Rect*(x, y: cint; w = cint(0), h = cint(0)): TRect =
  result.x = x
  result.y = y
  result.w = w
  result.h = h

proc Point*[T: TNumber](x, y: T): TPoint = (x.cint, y.cint)

proc Contains*(some: TRect; point: TPoint): bool = 
  return point.x >= some.x and point.x <= (some.x + some.w) and
    point.y >= some.y and point.y <= (some.y + some.h)