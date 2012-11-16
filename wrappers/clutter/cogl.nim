
const LibName = "libcogl.so"

type 
  PCobject* = ptr TCobject  ##
  TCobject* {.pure, final.} = object

  CoglUserDataKey* {.pure, final.} = object 
    unused: cint

  CoglDebugObjectForeachTypeCallback* = proc (info: ptr CoglDebugObjectTypeInfo; 
      user_data: pointer)
  CoglUserDataDestroyCallback* = proc (user_data: pointer)

  CoglDebugObjectTypeInfo* {.pure, final.} = object 
    name*: cstring
    instance_count*: culong
#*
#  CoglUserDataDestroyCallback:
#  @user_data: The data whos association with a #CoglObject has been
#              destoyed.
# 
#  When associating private data with a #CoglObject a callback can be
#  given which will be called either if the object is destroyed or if
#  cogl_object_set_user_data() is called with NULL user_data for the
#  same key.
# 
#  Since: 1.4
# 

#define COGL_OBJECT(X)          ((CoglObject *)X)
template COGL_OBJECT*(x): expr = cast[PCobject](x)



importcizzle "cogl_object_":
  proc set_user_data*(obj: PCObject; key: ptr CoglUserDataKey; 
    user_data: pointer; destroy: CoglUserDataDestroyCallback)
    #  Associates some private @user_data with a given #CoglObject. To
    #  later remove the association call cogl_object_set_user_data() with
    #  the same @key but NULL for the @user_data.
  proc get_user_data*(obj: PCObject; key: ptr CoglUserDataKey): pointer
    #  Finds the user data previously associated with @object using
    #  the given @key. If no user data has been associated with @object
    #  for the given @key this function returns NULL.

when defined(COGL_ENABLE_EXPERIMENTAL_API): 
  proc debug_object_foreach_type*(func: CoglDebugObjectForeachTypeCallback; 
    user_data: pointer) {.importc: "cogl_debug_object_foreach_type_EXP".}
    #  Invokes @func once for each type of object that Cogl uses and
    #  passes a count of the number of objects for that type. This is
    #  intended to be used solely for debugging purposes to track down
    #  issues with objects leaking.
 
  proc debug_object_print_instances*() {.
    importc: "debug_object_print_instances_EXP".}
    #  Prints a list of all the object types that Cogl uses along with the
    #  number of objects of that type that are currently in use. This is
    #  intended to be used solely for debugging purposes to track down
    #  issues with objects leaking.


importcizzle "cogl_":
  proc rectangle*(x1, y1, x2, y2: cfloat)
  proc rectangle_with_texture_coords*(x1, y1, x2, y2: cfloat; tx1, ty1, tx2, ty2: cfloat)
  proc rectangle_with_multitexture_coords*(x1, y1, x2, y2: cfloat; tex_coords: ptr cfloat; tex_coords_len: cint)
  proc rectangles_with_texture_coords*(verts: ptr cfloat; n_rects: cuint)
  proc rectangles*(verts: ptr cfloat; n_rects: cuint)
  proc polygon*(vertices: ptr CoglTextureVertex; n_vertices: cuint; 
                     use_color: gboolean)





