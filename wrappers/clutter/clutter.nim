
template clutterImports*(): stmt {.immediate.} =
  import glib2

const LibName = "libclutter-1.0.so.0"

clutterImports()

type
  PActor* = ptr TActor
  TActor* {.pure.} = object of TGObject
  
  PStage* = ptr TStage
  TStage*{.pure.} = object of TActor
  
  PText* = ptr TText
  TText* {.pure.} = object of TActor
  
  
  PActorMeta* = ptr TActorMeta
  TActorMeta* {.pure.} = object of TGObject
  
  TAction* {.pure.} = object of TActorMeta
  PAction* = ptr TAction
  
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


proc text_get_type*(): GType {.importc: "clutter_text_get_type".}
template CLUTTER_TEXT*(some: PActor): PText = cast[PText](
  G_TYPE_CHECK_INSTANCE_CAST(some, text_get_type()))      ##cast[PText](some)


proc newText_priv(font_name: cstring; text: cstring): PActor {.
  importc: "clutter_text_new_with_text".}

proc setColor*(stage: PStage; col: ptr TColor) {.
  importc: "clutter_stage_set_color".}

proc setColor*(text: PText; col: ptr TColor) {.importc: "clutter_text_set_color".}
proc getColor*(text: PText; col: ptr TColor) {.importc: "clutter_text_get_color".}

proc addChild*(actor, child: PActor) {.importc: "clutter_actor_add_child".}
proc show*(actor: PActor) {.importc: "clutter_actor_show".}

proc newColor*(r, g, b, a: uint8): ptr TColor {.importc: "clutter_color_new".}



# #define CLUTTER_TYPE_ACTION             (clutter_action_get_type ())
# #define CLUTTER_ACTION(obj)             (G_TYPE_CHECK_INSTANCE_CAST ((obj), CLUTTER_TYPE_ACTION, ClutterAction))
# #define CLUTTER_IS_ACTION(obj)          (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CLUTTER_TYPE_ACTION))
# #define CLUTTER_ACTION_CLASS(klass)     (G_TYPE_CHECK_CLASS_CAST ((klass), CLUTTER_TYPE_ACTION, ClutterActionClass))
# #define CLUTTER_IS_ACTION_CLASS(klass)  (G_TYPE_CHECK_CLASS_TYPE ((klass), CLUTTER_TYPE_ACTION))
# #define CLUTTER_ACTION_GET_CLASS(obj)   (G_TYPE_INSTANCE_GET_CLASS ((obj), CLUTTER_TYPE_ACTION, ClutterActionClass))





proc action_get_type*(): GType {.importc: "clutter_action_get_type".}
# ClutterActor API 


proc add_action*(self: PActor; action: PAction) {.
  importc: "clutter_actor_add_action".}
proc add_action*(self: PActor; name: cstring; action: PAction) {.
  importc: "clutter_actor_add_action_with_name".}
proc remove_action*(self: PActor; action: PAction) {.importc: "clutter_actor_remove_action".}
proc remove_action*(self: PActor; name: cstring) {.importc: "clutter_actor_remove_action_by_name".}

proc get_action*(self: PActor; name: cstring): PAction {.
  importc: "clutter_actor_get_action".}
proc get_actions*(self: PActor): PGList {.importc: "clutter_actor_get_actions".}
proc clear_actions*(self: PActor) {.importc: "clutter_actor_clear_actions".}
proc hasActions*(self: PActor): gboolean {.importc: "clutter_actor_has_actions".}




# #define CLUTTER_TYPE_ACTOR_META                 (clutter_actor_meta_get_type ())
# #define CLUTTER_ACTOR_META(obj)                 (G_TYPE_CHECK_INSTANCE_CAST ((obj), CLUTTER_TYPE_ACTOR_META, ClutterActorMeta))
# #define CLUTTER_IS_ACTOR_META(obj)              (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CLUTTER_TYPE_ACTOR_META))
# #define CLUTTER_ACTOR_META_CLASS(klass)         (G_TYPE_CHECK_CLASS_CAST ((klass), CLUTTER_TYPE_ACTOR_META, ClutterActorMetaClass))
# #define CLUTTER_IS_ACTOR_META_CLASS(klass)      (G_TYPE_CHECK_CLASS_TYPE ((klass), CLUTTER_TYPE_ACTOR_META))
# #define CLUTTER_ACTOR_META_GET_CLASS(obj)       (G_TYPE_INSTANCE_GET_CLASS ((obj), CLUTTER_TYPE_ACTOR_META, ClutterActorMetaClass))

proc actor_meta_get_type*(): GType {.
  importc: "clutter_actor_meta_get_type".}
proc set_name*(meta: PActorMeta; name: cstring) {.
  importc: "clutter_actor_meta_set_name".}
proc get_name*(meta: PActorMeta): cstring {.
  importc: "clutter_actor_meta_get_name".}
proc set_enabled*(meta: PActorMeta; is_enabled: gboolean) {.
  importc: "clutter_actor_meta_set_enabled".}
proc get_enabled*(meta: PActorMeta): gboolean {.
  importc: "clutter_actor_meta_get_enabled".}
proc get_actor*(meta: PActorMeta): PActor {.
  importc: "clutter_actor_meta_get_actor".}




{.pop.}

proc newText*(font_name: cstring; text: cstring): PText = 
  result = CLUTTER_TEXT(newText_priv(font_name, text))
