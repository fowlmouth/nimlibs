
import h3d, importc_block

when defined(Linux):
  const LibName = "libHorde3DUtils.so"

{.push callConv: cdecl, dynlib: LibName.}

importcizzle "h3dut":
  
  proc DumpMessages*(): bool

  proc InitOpenGL*(handleDeviceContext: cint): bool
    ## Windows only
  
  proc ReleaseOpenGL*()
    ## Windows only
    

  proc SwapBuffers*()
    ## Windows only

  proc GetResourcePath*(kind: H3DResTypes): cstring
    ## Docs say this is deprecated. TODO: add a warning
  proc SetResourcePath*(kind: H3DResTypes; path: cstring)
    ## Deprecated
      
  proc LoadResourcesFromDisk*(contentDir: cstring): bool
  
    
  proc CreateGeometryRes*(name: cstring; numVertices: cint; 
    numTriangleIndices: cint; posData: ptr cfloat; indexData: ptr cuint; 
    normalData: ptr cshort; tangentData: ptr cshort; bitangentData: ptr cshort;
    texData1: ptr cfloat; texData2: ptr cfloat): H3DRes

  proc CreateTGAImage*(pixels: ptr cuchar; width: cint; height: cint; 
                            bpp: cint; outData: var cstring; outSize: var cint): bool
  
  proc Screenshot*(filename: cstring): bool
  

  proc PickRay*(cameraNode: H3DNode; nwx, nwy: cfloat; ox, oy, oz: var cfloat;
    dx, dy, dz: var cfloat)
    
  proc PickNode*(cameraNode: H3DNode; nwx, mwy: cfloat): H3DNode
  
  proc ShowText*(text: cstring; x, y, size, colR, colG, colB: cfloat; fontMaterialRes: H3DRes)
  
  proc ShowFrameStats*(fontMaterialRes: H3DRes; panelMaterialRes: H3DRes; 
    mode: range[cint(0) .. cint(2)] )  ## the 2 comes from H3DUTMaxStatMode 

  proc FreeMem*(obj: cstringArray)

{.pop.}