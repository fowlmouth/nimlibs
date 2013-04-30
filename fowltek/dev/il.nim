import fowltek/importc_block

when defined(Linux):
  const LibName = "libIL.so"
else:
  {.fatal: "Please fill out LibName in devil.nim for your platform.".}


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
  
  ILstring* = cstring
  ILconst_string* = ILstring
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



# Callback functions for file reading
type 
  ILHANDLE* = pointer
  fCloseRProc* = proc (a2: ILHANDLE){.cdecl.}
  fEofProc* = proc (a2: ILHANDLE): ILboolean{.cdecl.}
  fGetcProc* = proc (a2: ILHANDLE): ILint{.cdecl.}
  fOpenRProc* = proc (a2: ILconst_string): ILHANDLE{.cdecl.}
  fReadProc* = proc (a2: pointer; a3: ILuint; a4: ILuint; a5: ILHANDLE): ILint{.
      cdecl.}
  fSeekRProc* = proc (a2: ILHANDLE; a3: ILint; a4: ILint): ILint{.cdecl.}
  fTellRProc* = proc (a2: ILHANDLE): ILint{.cdecl.}
# Callback functions for file writing
type 
  fCloseWProc* = proc (a2: ILHANDLE){.cdecl.}
  fOpenWProc* = proc (a2: ILconst_string): ILHANDLE{.cdecl.}
  fPutcProc* = proc (a2: ILubyte; a3: ILHANDLE): ILint{.cdecl.}
  fSeekWProc* = proc (a2: ILHANDLE; a3: ILint; a4: ILint): ILint{.cdecl.}
  fTellWProc* = proc (a2: ILHANDLE): ILint{.cdecl.}
  fWriteProc* = proc (a2: pointer; a3: ILuint; a4: ILuint; a5: ILHANDLE): ILint{.
      cdecl.}
# Callback functions for allocation and deallocation
type 
  mAlloc* = proc (a2: ILsizei): pointer{.cdecl.}
  mFree* = proc (CONST_RESTRICT: pointer){.cdecl.}
# Registered format procedures
type 
  IL_LOADPROC* = proc (a2: ILconst_string): ILenum{.cdecl.}
  IL_SAVEPROC* = proc (a2: ILconst_string): ILenum{.cdecl.}
  
  


{.push cdecl, dynlib: LibName.}

importcizzle "il":
  # ImageLib Functions
  proc ActiveFace*(Number: ILuint): ILboolean
  proc ActiveImage*(Number: ILuint): ILboolean
  proc ActiveLayer*(Number: ILuint): ILboolean
  proc ActiveMipmap*(Number: ILuint): ILboolean
  proc ApplyPal*(FileName: ILconst_string): ILboolean
  proc ApplyProfile*(InProfile: ILstring; OutProfile: ILstring): ILboolean
  proc BindImage*(Image: ILuint)
  proc Blit*(Source: ILuint; DestX: ILint; DestY: ILint; DestZ: ILint; 
               SrcX: ILuint; SrcY: ILuint; SrcZ: ILuint; Width: ILuint; 
               Height: ILuint; Depth: ILuint): ILboolean
  proc ClampNTSC*(): ILboolean
  proc ClearColour*(Red: ILclampf; Green: ILclampf; Blue: ILclampf; 
                      Alpha: ILclampf)


  proc ClearImage*(): ILboolean
  proc CloneCurImage*(): ILuint
  proc CompressDXT*(Data: ptr ILubyte; Width: ILuint; Height: ILuint; 
      Depth: ILuint; DXTCFormat: ILenum; DXTCSize: ptr ILuint): ptr ILubyte
  proc CompressFunc*(Mode: ILenum): ILboolean
  proc ConvertImage*(DestFormat: ILenum; DestType: ILenum): ILboolean
  proc ConvertPal*(DestFormat: ILenum): ILboolean
  proc CopyImage*(Src: ILuint): ILboolean
  proc CopyPixels*(XOff: ILuint; YOff: ILuint; ZOff: ILuint; Width: ILuint; 
     Height: ILuint; Depth: ILuint; Format: ILenum; 
     Typ: ILenum; Data: pointer): ILuint
  proc CreateSubImage*(Typ: ILenum; Num: ILuint): ILuint
  proc DefaultImage*(): ILboolean
  proc DeleteImage*(Num: ILuint)
  proc DeleteImages*(Num: ILsizei; Images: ptr ILuint)
  proc DetermineType*(FileName: ILconst_string): ILenum
  proc DetermineTypeF*(File: ILHANDLE): ILenum
  proc DetermineTypeL*(Lump: pointer; Size: ILuint): ILenum
  proc Disable*(Mode: ILenum): ILboolean
  proc DxtcDataToImage*(): ILboolean
  proc DxtcDataToSurface*(): ILboolean
  proc Enable*(Mode: ILenum): ILboolean
  proc FlipSurfaceDxtcData*()
  proc FormatFunc*(Mode: ILenum): ILboolean
  proc GenImages*(Num: ILsizei; Images: ptr ILuint)
  proc GenImage*(): ILuint
  proc GetAlpha*(Typ: ILenum): ptr ILubyte
  proc GetBoolean*(Mode: ILenum): ILboolean
  proc GetBooleanv*(Mode: ILenum; Param: ptr ILboolean)
  proc GetData*(): ptr ILubyte
  proc GetDXTCData*(Buffer: pointer; BufferSize: ILuint; DXTCFormat: ILenum): ILuint
  proc GetError*(): ILenum
  proc GetInteger*(Mode: ILenum): ILint
  proc GetIntegerv*(Mode: ILenum; Param: ptr ILint)
  proc GetLumpPos*(): ILuint
  proc GetPalette*(): ptr ILubyte
  proc GetString*(StringName: ILenum): ILconst_string
  proc Hint*(Target: ILenum; Mode: ILenum)
  proc InvertSurfaceDxtcDataAlpha*(): ILboolean
  proc Init*()
  proc ImageToDxtcData*(Format: ILenum): ILboolean
  proc IsDisabled*(Mode: ILenum): ILboolean
  proc IsEnabled*(Mode: ILenum): ILboolean
  proc IsImage*(Image: ILuint): ILboolean
  proc IsValid*(Typ: ILenum; FileName: ILconst_string): ILboolean
  proc IsValidF*(Typ: ILenum; File: ILHANDLE): ILboolean
  proc IsValidL*(Typ: ILenum; Lump: pointer; Size: ILuint): ILboolean{.
      cdecl.}
  
  
  proc KeyColour*(Red: ILclampf; Green: ILclampf; Blue: ILclampf; 
                    Alpha: ILclampf)
  proc Load*(Typ: ILenum; FileName: ILconst_string): ILboolean
  proc LoadF*(Typ: ILenum; File: ILHANDLE): ILboolean
  proc LoadImage*(FileName: ILconst_string): ILboolean
  proc LoadL*(Typ: ILenum; Lump: pointer; Size: ILuint): ILboolean
  proc LoadPal*(FileName: ILconst_string): ILboolean
  proc ModAlpha*(AlphaValue: ILdouble)
  proc OriginFunc*(Mode: ILenum): ILboolean
  proc OverlayImage*(Source: ILuint; XCoord: ILint; YCoord: ILint; 
                       ZCoord: ILint): ILboolean
  proc PopAttrib*()
  proc PushAttrib*(Bits: ILuint)
  proc RegisterFormat*(Format: ILenum)
  proc RegisterLoad*(Ext: ILconst_string; Load: IL_LOADPROC): ILboolean{.
      cdecl.}
  proc RegisterMipNum*(Num: ILuint): ILboolean
  proc RegisterNumFaces*(Num: ILuint): ILboolean
  proc RegisterNumImages*(Num: ILuint): ILboolean
  proc RegisterOrigin*(Origin: ILenum)
  proc RegisterPal*(Pal: pointer; Size: ILuint; Typ: ILenum)
  proc RegisterSave*(Ext: ILconst_string; Save: IL_SAVEPROC): ILboolean{.
      cdecl.}
  proc RegisterType*(Typ: ILenum)
  proc RemoveLoad*(Ext: ILconst_string): ILboolean
  proc RemoveSave*(Ext: ILconst_string): ILboolean
  proc ResetMemory*()
  # Deprecated
  proc ResetRead*()
  proc ResetWrite*()
  proc Save*(Typ: ILenum; FileName: ILconst_string): ILboolean
  proc SaveF*(Typ: ILenum; File: ILHANDLE): ILuint
  proc SaveImage*(FileName: ILconst_string): ILboolean
  proc SaveL*(Typ: ILenum; Lump: pointer; Size: ILuint): ILuint
  proc SavePal*(FileName: ILconst_string): ILboolean
  proc SetAlpha*(AlphaValue: ILdouble): ILboolean
  proc SetData*(Data: pointer): ILboolean
  proc SetDuration*(Duration: ILuint): ILboolean
  proc SetInteger*(Mode: ILenum; Param: ILint)
  proc SetMemory*(a2: mAlloc; a3: mFree)
  proc SetPixels*(XOff: ILint; YOff: ILint; ZOff: ILint; Width: ILuint; 
                    Height: ILuint; Depth: ILuint; Format: ILenum; 
                    Typ: ILenum; Data: pointer)
  proc SetRead*(a2: fOpenRProc; a3: fCloseRProc; a4: fEofProc; 
                  a5: fGetcProc; a6: fReadProc; a7: fSeekRProc; a8: fTellRProc){.
      cdecl.}
  proc SetString*(Mode: ILenum; String: cstring)
  proc SetWrite*(a2: fOpenWProc; a3: fCloseWProc; a4: fPutcProc; 
                   a5: fSeekWProc; a6: fTellWProc; a7: fWriteProc)
  proc ShutDown*()
  proc SurfaceToDxtcData*(Format: ILenum): ILboolean
  proc TexImage*(Width: ILuint; Height: ILuint; Depth: ILuint; 
                   NumChannels: ILubyte; Format: ILenum; Typ: ILenum; 
                   Data: pointer): ILboolean
  proc TexImageDxtc*(w: ILint; h: ILint; d: ILint; DxtFormat: ILenum; 
                       data: ptr ILubyte): ILboolean
  proc TypeFromExt*(FileName: ILconst_string): ILenum
  proc TypeFunc*(Mode: ILenum): ILboolean
  proc LoadData*(FileName: ILconst_string; Width: ILuint; Height: ILuint; 
                   Depth: ILuint; Bpp: ILubyte): ILboolean
  proc LoadDataF*(File: ILHANDLE; Width: ILuint; Height: ILuint; 
                    Depth: ILuint; Bpp: ILubyte): ILboolean
  proc LoadDataL*(Lump: pointer; Size: ILuint; Width: ILuint; 
                    Height: ILuint; Depth: ILuint; Bpp: ILubyte): ILboolean{.
      cdecl.}
  proc SaveData*(FileName: ILconst_string): ILboolean

{.pop.}

proc ClearColor*(R, G, B, A: ILclampf) {.inline.} = ClearColour(R, G, B, A)
proc KeyColor*(R,G,B,A: ILclampf) {.inline.} = KeyColour(R,G,B,A)

