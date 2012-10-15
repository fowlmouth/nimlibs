
when defined(Linux):
  const LibName = "libIL.so"
type
  ILuint* = uint32
  ILenum* = cuint
  ILboolean* = bool
  ILbitfield* = cuint
  ILbyte* = cchar
  ILshort* = cshort
  ILint* = int32
  ILsizei* = int32
  ILubyte* = cuchar
  ILushort* = cushort
  ILfloat* = cfloat
  ILclampf* = cfloat
  ILdouble* = cdouble
  ILclampd* = cdouble
  ILint64* = int64
  ILuint64* = uint64
const
  IL_VERSION_NUM*: ILenum = 0x00000DE2
  IL_IMAGE_WIDTH*: ILenum = 0x00000DE4
  IL_IMAGE_HEIGHT*: ILenum = 0x00000DE5
  IL_IMAGE_DEPTH*: ILenum = 0x00000DE6
  IL_IMAGE_SIZE_OF_DATA*: ILenum = 0x00000DE7
  IL_IMAGE_BPP*: ILenum = 0x00000DE8
  IL_IMAGE_BYTES_PER_PIXEL*: ILenum = 0x00000DE8
  IL_IMAGE_BITS_PER_PIXEL*: ILenum = 0x00000DE9
  IL_IMAGE_FORMAT*: ILenum = 0x00000DEA
  IL_IMAGE_TYPE*: ILenum = 0x00000DEB
  IL_PALETTE_TYPE*: ILenum = 0x00000DEC
  IL_PALETTE_SIZE*: ILenum = 0x00000DED
  IL_PALETTE_BPP*: ILenum = 0x00000DEE
  IL_PALETTE_NUM_COLS*: ILenum = 0x00000DEF
  IL_PALETTE_BASE_TYPE*: ILenum = 0x00000DF0
  IL_NUM_FACES*: ILenum = 0x00000DE1
  IL_NUM_IMAGES*: ILenum = 0x00000DF1
  IL_NUM_MIPMAPS*: ILenum = 0x00000DF2
  IL_NUM_LAYERS*: ILenum = 0x00000DF3
  IL_ACTIVE_IMAGE*: ILenum = 0x00000DF4
  IL_ACTIVE_MIPMAP*: ILenum = 0x00000DF5
  IL_ACTIVE_LAYER*: ILenum = 0x00000DF6
  IL_ACTIVE_FACE*: ILenum = 0x00000E00
  IL_CUR_IMAGE*: ILenum = 0x00000DF7
  IL_IMAGE_DURATION*: ILenum = 0x00000DF8
  IL_IMAGE_PLANESIZE*: ILenum = 0x00000DF9
  IL_IMAGE_BPC*: ILenum = 0x00000DFA
  IL_IMAGE_OFFX*: ILenum = 0x00000DFB
  IL_IMAGE_OFFY*: ILenum = 0x00000DFC
  IL_IMAGE_CUBEFLAGS*: ILenum = 0x00000DFD
  IL_IMAGE_ORIGIN*: ILenum = 0x00000DFE
  IL_IMAGE_CHANNELS*: ILenum = 0x00000DFF

{.push: cdecl, dynlib: LibName.}
proc IL_init*() {.importc: "ilInit".} 

proc loadImage*(filename: cstring): bool {.
  importc: "ilLoadImage".}

proc GenImages*(num: csize; images: ptr ILuint) {.
  importc: "ilGenImages".}
proc GenImages*(num: csize; images: var ILuint) {.
  importc: "ilGenImages".}
proc GenSingleImage*(): ILuint =
  genImages(1, result)

proc bindImage*(image: ILuint) {.importc: "ilBindImage".}

proc deleteImage*(Num: ILuint){.
  importc: "ilDeleteImage".}
proc deleteImages*(Num: ILsizei; Images: ptr ILuint){.
  importc: "ilDeleteImages".}
proc deleteImages*(Num: ILsizei; Images: var ILuint){.
  importc: "ilDeleteImages".}


proc ilGetInteger*(Mode: ILenum): ILint{.importc.}

{.pop.}

  