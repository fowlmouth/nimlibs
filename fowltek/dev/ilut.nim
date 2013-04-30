import fowltek/dev/il, opengl, fowltek/importc_block
when defined(Linux):
  const LibName = "libILUT.so"

const
  ILUT_OPENGL*: ILenum     = 0
  ILUT_ALLEGRO*: ILenum    = 1
  ILUT_WIN32*: ILenum      = 2
  ILUT_DIRECT3D8*: ILenum  = 3
  ILUT_DIRECT3D9*: ILenum  = 4
  ILUT_X11*: ILenum        = 5
  ILUT_DIRECT3D10*: ILenum = 6

{.push  cdecl, dynlib: LibName.}

importcizzle "ilut":
  proc Init*() 
  proc Renderer*(renderer: ILenum): ILboolean 

  proc GLBindTexImage*(): GLuint 





{.pop.}
