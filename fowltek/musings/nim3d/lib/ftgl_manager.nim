import ftgl, tables

type TFontKey* = tuple[name: string; size: int32]
var fonts = initTable[TFontKey, PFont](16)

proc cleanup*() =
  for key in keys(fonts):
    fonts[key].destroy()
    fonts.del key ## tested this, its kosher.

proc getFont*(filename: string; size: int32): PFont =
  result = fonts[(filename, size)]
  if not result.isNil:
    return
  
  result = createTextureFont(filename)
  if not result.setFaceSize(size.cuint, size.cuint):
    echo "Failed to set face size!"
    ## what should happen here? meh
  
  fonts[(filename, size)] = result

