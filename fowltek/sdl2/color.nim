import fowltek/sdl2, fowltek/vector_math

import colors
export colors

proc toSdlColor*(c: colors.TColor): sdl2.TColor =
  ## Convert colors.TColor to SDL2.TColor
  let x = c.extractRGB  
  result.r = x.r and 0xff
  result.g = x.g and 0xff
  result.b = x.b and 0xff
  result.a = 255

  
{.pragma: id, inline, discardable.}
proc setDrawColor*(R: PRenderer; COL: sdl2.TColor): SDL_Return{.id.}=R.SetDrawColor(col.R, col.G, col.B, col.A) 

import fowltek/sdl2/gfx

proc stringColor*(RE: PRenderer; X,Y: int16, S: cstring; COL: sdl2.TColor): SDL_Return{.
  inline, discardable.} = stringRGBA(RE,X,Y,S,COL.R,COL.G,COL.B,COL.A)
proc stringRGBA*(RE: PRenderer; X,Y: int16; S: cstring; COL: sdl2.TColor): SDL_Return{.
  inline, discardable.} = stringRGBA(RE,X,Y,S,COL.R,COL.G,COL.B,COL.A)
proc mlStringColor*(RE:PRenderer;X,Y: int16, S: string; COL: sdl2.TColor; LineSpacing = 2'i16): SDL_Return{.
  inline, discardable.} = mlStringRGBA(RE,X,Y,S,COL.R,COL.G,COL.B,COL.A,LineSpacing)
proc mlStringColor*(RE:PRenderer;X,Y:int16;S:seq[string];COL: sdl2.TColor; LineSpacing = 2'i16): SDL_Return{.
  inline,discardable.}=mlStringRGBA(RE,X,Y,S,COL.R,COL.G,COL.B,COL.A,LineSpacing)


#color packing for sdl2/gfx functions
converter toint (c: colors.TColor): int = c.int
proc pack* (c: colors.TColor; alpha = 255): uint32 =
  let x = c.extractRGB
  result = ((alpha and 0xFF) or 
    (c shl 24  and 0xff) or 
    (c shl 16  and 0xff) or
    (c shl 8   and 0xff)).uint32 
  var xz = [(x.r and 0xFF).uint8, (x.g and 0xFF).uint8, (x.b and 0xFF).uint8, (alpha and 0xFF).uint8]
  result = cast[ptr uint32](xz[0].addr)[] 
proc unpack* (c: uint32): sdl2.TColor = 
  result.r = c shr 24 and 0xff
  result.g = c shr 16 and 0xff
  result.b = c shr 8  and 0xff
  result.a = c and 0xff 