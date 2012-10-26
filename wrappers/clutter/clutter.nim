import glib2

const LibName = "libclutter-1.0.so.0"

type
  PActor* = ptr TActor
  TActor* {.pure.} = object of TGObject
  
  PStage* = ptr TStage
  TStage*{.pure.} = object of TActor
  
  PText* = ptr TText
  TText* {.pure.} = object of TActor
  
  TColor* = tuple[r, g, b, a: uint8]
  
  TClutterInitError* {.size: sizeof(cint).}=enum
    ErrorInternal = -3, ErrorBackend = -2, ErrorThreads = -1,
    ErrorUnknown = 0, ErrorNone = 1
converter toBool*(some: TClutterInitError): bool = some == ErrorNone

discard """template CLUTTER_STAGE*(some: PActor): PStage = cast[PStage](some)
"""

#G_TYPE_CHECK_INSTANCE_CAST(
{.push: cdecl, dynlib: LibName.}

proc initClutter*(argc: ptr cint; argv: ptr cstringarray): TClutterInitError {.
  importc: "clutter_init".}

proc main*() {.importc: "clutter_main".}

proc newStage*(): PActor {.importc: "clutter_stage_new".}

proc stage_get_type*(): GType {.importc: "clutter_stage_get_type".}
template CLUTTER_STAGE*(some: PActor): PStage = cast[PStage](
  G_TYPE_CHECK_INSTANCE_CAST(some, stage_get_type()))


proc newText*(font_name: cstring; text: cstring): PActor {.
  importc: "clutter_text_new_with_text".}

proc text_get_type*(): GType {.importc: "clutter_text_get_type".}
template CLUTTER_TEXT*(some: PActor): PText = cast[PText](
  G_TYPE_CHECK_INSTANCE_CAST(some, text_get_type()))      ##cast[PText](some)

proc setColor*(stage: PStage; col: ptr TColor) {.
  importc: "clutter_stage_set_color".}

proc setColor*(text: PText; col: ptr TColor) {.importc: "clutter_text_set_color".}
proc getColor*(text: PText; col: ptr TColor) {.importc: "clutter_text_get_color".}

proc addChild*(actor, child: PActor) {.importc: "clutter_actor_add_child".}
proc show*(actor: PActor) {.importc: "clutter_actor_show".}

proc newColor*(r, g, b, a: uint8): ptr TColor {.importc: "clutter_color_new".}

{.pop.}


when isMainModule:
  if not initClutter(nil, nil):
    quit "Failed to initialize clutter!"

  var stage = newStage()

  var label = newText("Sans 32px", "Sup yo")
  stage.addChild label
  
  var col = newColor(0, 0, 0, 255)
  CLUTTER_STAGE(stage).setColor(col)
  col.r = 255
  CLUTTER_TEXT(label).setColor(col)
  
  stage.show()

  clutter.main()
