import re, tables, strutils
import fowltek/sdl2/image, fowltek/sdl2

type
  PSprite* = ref object
    file*: string
    tex*: sdl2.PTexture
    defaultRect*: TRect
    rows*, cols*: int32
    center*: TPoint

  TSpriteCache* = TTable[string, PSprite] 


proc newSpriteCache*(initialSize = 64): TSpriteCache = initTable[string, PSprite](initialSize)

proc free (some: PSprite) =
  destroy some.tex


let imageFilenamePattern = re"\S+_(\d+)x(\d+)\.\S{3,4}"

proc get* (cache: var TSpriteCache; R: PRenderer; file: string): PSprite =
  result = cache[file]
  if result.isNil:
    new result, free
    result.file = file
    
    var img = img_load(file)
    result.tex = R.createTextureFromSurface(img)
    result.defaultRect.w = img.w
    result.defaultRect.h = img.h
    if file =~ imageFilenamePattern:
      result.defaultRect.w = matches[0].parseInt.cint
      result.defaultRect.h = matches[1].parseInt.cint
    result.center.x = cint(result.defaultRect.w / 2)
    result.center.y = cint(result.defaultRect.h / 2)
    
    result.rows = int32(img.h / result.defaultRect.h)
    result.cols = int32(img.w / result.defaultRect.w)
    img.destroy
    
    cache[file] = result

when false:
  ## an instantiation needs only to copy the defaultRect from the sprite and keep a reference to the sprite
  var cache = newSpriteCache()
  var mySprite: tuple[rect: TRect, sprite: PSprite]
  mySprite.sprite = cache.get(renderer, "char_20x20.png")
  mySprite.rect = mySprite.defaultRect
  
  #now to draw
  var dest = mySprite.rect
  dest.x = 10
  dest.y = 10
  renderer.copy mySprite.sprite.tex, mySprite.rect.addr, dest.addr
  
  
  