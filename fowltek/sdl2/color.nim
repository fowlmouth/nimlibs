import fowltek/sdl2, fowltek/vector_math


import colors
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

