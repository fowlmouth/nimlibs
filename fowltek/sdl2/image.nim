import fowltek/sdl2

when defined(Linux):
  const LibName = "libSDL2_image.so"
else:
  {.fatal: "Please fill out the library name for your platform at the top of fowltek/sdl2/image.nim".}



const 
  IMG_INIT_JPG* = 0x00000001
  IMG_INIT_PNG* = 0x00000002 
  IMG_INIT_TIF* = 0x00000004 
  IMG_INIT_WEBP* = 0x00000008


{.push callconv:cdecl, dynlib: libName.}

#import fowltek/importc_block
#importcizzle "IMG_":
proc IMG_Linked_Version*(): ptr SDL_version {.importc: "IMG_Linked_Version".}


proc IMG_Init*(flags: cint = IMG_INIT_JPG or IMG_INIT_PNG): cint {.
  importc: "IMG_Init".}
  ## It returns the flags successfully initialized, or 0 on failure.
  ## This is completely different than SDL_Init() -_-

proc IMG_Quit*() {.importc: "IMG_Quit".}
# Load an image from an SDL data source.
#   The 'type' may be one of: "BMP", "GIF", "PNG", etc.
#
#   If the image format supports a transparent pixel, SDL will set the
#   colorkey for the surface.  You can enable RLE acceleration on the
#   surface afterwards by calling:
# SDL_SetColorKey(image, SDL_RLEACCEL, image->format->colorkey);
# 
#proc IMG_LoadTyped_RW*(src: ptr SDL_RWops; freesrc: cint; type: cstring): ptr SDL_Surface
# Convenience functions 
proc IMG_Load*(file: cstring): PSurface {.importc: "IMG_Load".}
#proc IMG_Load_RW*(src: ptr SDL_RWops; freesrc: cint): ptr SDL_Surface
# Load an image directly into a render texture.
# 
proc IMG_LoadTexture*(renderer: PRenderer; file: cstring): PTexture {.
  importc: "IMG_LoadTexture".}
#proc IMG_LoadTexture_RW*(renderer: ptr SDL_Renderer; src: ptr SDL_RWops; 
#                         freesrc: cint): ptr SDL_Texture
#proc IMG_LoadTextureTyped_RW*(renderer: ptr SDL_Renderer; src: ptr SDL_RWops; 
#                              freesrc: cint; type: cstring): ptr SDL_Texture
# Invert the alpha of a surface for use with OpenGL
#   This function is now a no-op, and only provided for backwards compatibility.
#
proc IMG_InvertAlpha*(on: cint): cint {.importc: "IMG_InvertAlpha".}

discard """
# Functions to detect a file type, given a seekable source 
proc IMG_isICO*(src: ptr SDL_RWops): cint
proc IMG_isCUR*(src: ptr SDL_RWops): cint
proc IMG_isBMP*(src: ptr SDL_RWops): cint
proc IMG_isGIF*(src: ptr SDL_RWops): cint
proc IMG_isJPG*(src: ptr SDL_RWops): cint
proc IMG_isLBM*(src: ptr SDL_RWops): cint
proc IMG_isPCX*(src: ptr SDL_RWops): cint
proc IMG_isPNG*(src: ptr SDL_RWops): cint
proc IMG_isPNM*(src: ptr SDL_RWops): cint
proc IMG_isTIF*(src: ptr SDL_RWops): cint
proc IMG_isXCF*(src: ptr SDL_RWops): cint
proc IMG_isXPM*(src: ptr SDL_RWops): cint
proc IMG_isXV*(src: ptr SDL_RWops): cint
proc IMG_isWEBP*(src: ptr SDL_RWops): cint 
# Individual loading functions 
proc IMG_LoadICO_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadCUR_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadBMP_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadGIF_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadJPG_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadLBM_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadPCX_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadPNG_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadPNM_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadTGA_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadTIF_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadXCF_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadXPM_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadXV_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_LoadWEBP_RW*(src: ptr SDL_RWops): ptr SDL_Surface
proc IMG_ReadXPMFromArray*(xpm: cstringArray): ptr SDL_Surface
"""



{.pop.}













