import nodes
import ftgl, ftgl_manager

type
  PTextNode* = ref TTextNode
  TTextNode* = object of TNode
    text*: string
    font*: PFont
var
  lastUsedFont: TFontKey

proc free(node: PTextNode) =
  ## do not free the font, its handled in ftgl_manager.cleanup()
  nil

proc newTextNode*(text: string; font: string; fontsize: int32): PTextNode =
  new result, free
  init PNode(result)
  result.text = text
  result.font = getFont(font, fontsize)
  lastUsedFont.name = font
  lastUsedFont.size = fontsize
proc newTextNode*(text: string): PTextNode =
  ## use the last used font
  result = newTextNode(text, lastUsedFont.name, lastUsedFont.size)

method render*(n: PTextNode) =
  n.applyTransform()
  n.font.render(cstring(n.text), RenderAll)
