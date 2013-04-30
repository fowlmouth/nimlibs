import re, tables, strutils
import fowltek/sdl2/image, fowltek/sdl2

type
  PSprite* = ref object
    tex*: sdl2.PTexture
    defaultRect*: TRect
    rows*, cols*: int32

  TSpriteCache* = object
    tab: TTable[string, PSprite] 


proc newSpriteCache*(initialSize = 64): TSpriteCache =
  result.tab = initTable[string, PSprite](initialSize)

proc free (some: PSprite) =
  destroy some.tex
  
proc loadSprite*(file: string; R: sdl2.PRenderer): PSprite =
  var surf = IMG_Load(file)
  if surf.isNil:
    return
  var tex = R.createTextureFromSurface(surf)
  if tex.isNil:
    destroy surf
    return
  
  new result, free
  result.tex = tex
  result.defaultRect.w = surf.w
  result.defaultRect.h = surf.h
  destroy surf
  
  if file =~ re".+_(\d+)x(\d+)\.\w+":
    let (w, h) = (matches[0].parseInt.int32, matches[1].parseInt.int32)
    result.rows = (result.defaultRect.h / h).int32
    result.defaultRect.h = h
    result.cols = (result.defaultRect.w / w).int32
    result.defaultRect.w = w
  
  
  
proc get*(cache: var TSpriteCache; file: string; R: sdl2.PRenderer): PSprite =
  result = cache.tab[file]
  if result.isNil:
    result = loadSprite(file, R)
    cache.tab[file] = result
