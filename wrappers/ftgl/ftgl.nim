
when defined(Linux):
  const LibName = "libftgl.so.2.1.3"

type
  TRenderMode* = enum
    RenderFront = 0x0001, RenderBack = 0x0002, 
    RenderSide =  0x0004, RenderAll =  0xffff
  
  TTextAlignment* = enum
    AlignLeft, AlignCenter, AlignRight, AlignJustify
  
  PFont* = ptr TFont
  TFont* {.pure.}= object
  
  PLayout* = ptr TLayout
  TLayout* {.pure.} = object

{.push: cdecl.}
proc destroy*(font: PFont) {.
  importc: "ftglDestroyFont", dynlib: LibName.}

proc createPixmapFont*(filename: cstring): PFont {.
  importc: "ftglCreatePixmapFont", dynlib: LibName.}
proc createBitmapFont*(filename: cstring): PFont {.
  importc: "ftglCreateBitmapFont", dynlib: LibName.}
proc createPolygonFont*(filename: cstring): PFont {.
  importc: "ftglCreatePolygonFont", dynlib: LibName.}
proc createExtrudeFont*(filename: cstring): PFont {.
  importc: "ftglCreateExtrudeFont", dynlib: LibName.}
proc createOutlineFont*(filename: cstring): PFont {.
  importc: "ftglCreateOutlineFont", dynlib: LibName.}
proc createTextureFont*(filename: cstring): PFont {.
  importc: "ftglCreateTextureFont", dynlib: LibName.}

proc setFaceSize*(font: PFont; size, res: cuint): cint {.
  importc: "ftglSetFontFaceSize", dynlib: LibName.}

proc getFaceSize*(font: PFont): cuint {.
  importc: "ftglGetFontFaceSize", dynlib: LibName.}


proc render*(font: PFont; text: cstring; mode: cint) {.
  importc: "ftglRenderFont", dynlib: LibName.}
proc render*(font: PFont; text: cstring; mode: TRenderMode) {.
  importc: "ftglRenderFont", dynlib: LibName.}

proc destroy*(layout: PLayout) {.importc: "ftglDestroyLayout", dynlib: LibName.}
proc getBBox*(layout: PLayout; text: cstring; bounds: var array[0..5, cfloat]) {.
  importc: "ftglGetLayoutBBox", dynlib: LibName.}

proc render*(layout: PLayout; text: cstring; mode: cint) {.
  importc: "ftglRenderLayout", dynlib: LibName.}
proc render*(layout: PLayout; text: cstring; mode: TRenderMode) {.
  importc: "ftglRenderLayout", dynlib: LibName.}

proc createSimpleLayout*(): PLayout {.
  importc: "ftglCreateSimpleLayout", dynlib: LibName.}

proc setFont*(layout: PLayout; font: PFont) {.
  importc: "ftglSetLayoutFont", dynlib: LibName.}
proc getFont(layout: PLayout): PFont {.
  importc: "ftglGetLayoutFont", dynlib: LibName.}

proc setLineLength*(layout: PLayout; len: cfloat) {.
  importc: "ftglSetLayoutLineLength", dynlib: LibName.}
proc getLineLength*(layout: PLayout): cfloat {.
  importc: "ftglGetLayoutLineLength", dynlib: LibName.}

proc setAlignment*(layout: PLayout; alignment: cint) {.
  importc: "ftglSetLayoutAlignment", dynlib: LibName.}
proc getAlignment*(layout: PLayout): cint {.
  importc: "ftglGetLayoutAlignement", dynlib: LibName.}

proc setLineSpacing*(layout: PLayout; spacing: cfloat) {.
  importc: "ftglSetLayoutLineSpacing", dynlib: LibName.}
when false:
  ## this is in the header but not exported..
  proc getLineSpacing*(layout: PLayout): cfloat {.
    importc: "ftglGetLayoutLineSpacing", dynlib: LibName.}

{.pop.}

## See these newlines and
## look towards the future!





