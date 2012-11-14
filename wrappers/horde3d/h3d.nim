
import importc_block

when defined(Linux):
  const LibName = "libHorde3D.so"


type 
  H3DRes* = cint
  H3DNode* = cint

  H3DOptions* = enum 
    MaxLogLevel = 1, MaxNumMessages, TrilinearFiltering, MaxAnisotropy, 
    TexCompression, SRGBLinearization, LoadTextures, FastAnimation, 
    ShadowMapSize, SampleCount, WireframeMode, DebugViewMode, DumpFailedShaders, 
    GatherTimeStats
  H3DStats* = enum 
    TriCount = 100, BatchCount, LightPassCount, FrameTime, AnimationTime, 
    GeoUpdateTime, ParticleSimTime, FwdLightsGPUTime, DefLightsGPUTime, 
    ShadowsGPUTime, ParticleGPUTime, TextureVMem, GeometryVMem

  H3DResTypes* = enum 
    ResType_Undefined = 0, ResType_SceneGraph, ResType_Geometry, 
    ResType_Animation, ResType_Material, ResType_Code, ResType_Shader, 
    ResType_Texture, ResType_ParticleEffect, ResType_Pipeline

  H3DResFlags* = enum 
    NoQuery = 1, NoTexCompression = 2, NoTexMipmaps = 4, TexCubemap = 8, 
    TexDynamic = 16, TexRenderable = 32, TexSRGB = 64

  H3DFormats* = enum 
    Unknown = 0, TEX_BGRA8, TEX_DXT1, TEX_DXT3, TEX_DXT5, TEX_RGBA16F, 
    TEX_RGBA32F

  H3DGeoRes* = enum 
    GeometryElem = 200, GeoIndexCountI, GeoVertexCountI, GeoIndices16I, 
    GeoIndexStream, GeoVertPosStream, GeoVertTanStream, GeoVertStaticStream

  H3DAnimRes* = enum 
    EntityElem = 300, EntFrameCountI

  H3DMatRes* = enum 
    MaterialElem = 400, Mat_SamplerElem, Mat_UniformElem, Mat_MatClassStr, MatLinkI, 
    MatShaderI, SampNameStr, SampTexResI, UnifNameStr, UnifValueF4

  H3DShaderRes* = enum 
    Shader_ContextElem = 600, Shader_SamplerElem, Shader_UniformElem, 
    Shader_ContNameStr, Shader_SampNameStr, Shader_SampDefTexResI, 
    Shader_UnifNameStr, Shader_UnifSizeI, Shader_UnifDefValueF4

  H3DTexRes* = enum 
    TextureElem = 700, ImageElem, TexFormatI, TexSliceCountI, ImgWidthI, 
    ImgHeightI, ImgPixelStream

  H3DPartEffRes* = enum 
    ParticleElem = 800, ChanMoveVelElem, ChanRotVelElem, ChanSizeElem, 
    ChanColRElem, ChanColGElem, ChanColBElem, ChanColAElem, PartLifeMinF, 
    PartLifeMaxF, ChanStartMinF, ChanStartMaxF, ChanEndRateF, ChanDragElem

  H3DPipeRes* = enum 
    StageElem = 900, StageNameStr, StageActivationI

  H3DNodeTypes* = enum 
    Undefined = 0, Group, Model, Mesh, Joint, Light, Camera, Emitter

  H3DNodeFlags* = enum 
    NoDraw = 1, NoCastShadow = 2, NoRayQuery = 4, Inactive = 7 # NoDraw | NoCastShadow | NoRayQuery

  H3DNodeParams* = enum 
    NameStr = 1, AttachmentStr

  H3DModel* = enum 
    GeoResI = 200, SWSkinningI, LodDist1F, LodDist2F, LodDist3F, LodDist4F

  H3DMesh* = enum 
    Mesh_MatResI = 300, BatchStartI, BatchCountI, VertRStartI, VertREndI, LodLevelI

  H3DJoint* = enum 
    JointIndexI = 400

  H3DLight* = enum 
    Light_MatResI = 500, RadiusF, FovF, ColorF3, ColorMultiplierF, ShadowMapCountI, 
    ShadowSplitLambdaF, ShadowMapBiasF, LightingContextStr, ShadowContextStr

  H3DCamera* = enum 
    PipeResI = 600, OutTexResI, OutBufIndexI, LeftPlaneF, RightPlaneF, 
    BottomPlaneF, TopPlaneF, NearPlaneF, FarPlaneF, ViewportXI, ViewportYI, 
    ViewportWidthI, ViewportHeightI, OrthoI, OccCullingI

  H3DEmitter* = enum 
    Emitter_MatResI = 700, PartEffResI, MaxCountI, RespawnCountI, DelayF, EmissionRateF, 
    SpreadAngleF, ForceF3

  H3DModelUpdateFlags* = enum 
    Animation = 1, Geometry = 2
  
  H3DTerrainOption* = enum
    Terrain_HeightTexResI = 10000, Terrain_MatResI, Terrain_MeshQualityF,
    Terrain_SkirtHeightF, Terrain_BlockSizeI


{.push: cdecl, dynlib: LibName.}

importcizzle "h3d":
  proc Init*(): bool
  proc Release*()

  proc AddResource*(kind: H3DResTypes; name: cstring; flags: cint): H3DRes

  proc GetVersionString*(): cstring
  
  proc CheckExtension*(extensionName: cstring): bool
  
  proc GetError*(): bool
  
  proc Render*(cameraNode: H3DNode)
  
  proc FinalizeFrame*()
  
  proc Clear*()
  
  
  proc GetMessage*(level: var cint; time: var cfloat): cstring
  
  
  proc GetOption*(param: H3DOptions): cfloat
  
  proc SetOption*(param: H3DOptions; value: cfloat): bool
  
  proc GetStat*(param: H3DStats; reset: bool): cfloat
  

  proc ShowOverlays*(verts: ptr cfloat; vertCount: cint; 
    colR, colG, colB, colA: cfloat; materialRes: H3DRes; flags: cint)

  proc ClearOverlays*()

  proc GetResType*(res: H3DRes): cint

  proc GetResName*(res: H3DRes): cstring
  
  proc GetNextResource*(kind: cint; start: H3DRes): H3DRes

  proc FindResource*(kind: H3DResTypes; name: cstring): H3DRes
  proc CloneResource*(sourceRes: H3DRes; name: cstring): H3DRes

  proc RemoveResource*(res: H3DRes): cint

  proc IsResLoaded*(res: H3DRes): bool

  proc LoadResource*(res: H3DRes; data: cstring; size: cint): bool
  proc UnloadResource*(res: H3DRes)
  proc GetResElemCount*(res: H3DRes; elem: cint): cint
  proc FindResElem*(res: H3DRes; elem: cint; param: cint; value: cstring): cint
  proc GetResParamI*(res: H3DRes; elem: cint; elemIdx: cint; param: cint): cint
  proc SetResParamI*(res: H3DRes; elem: cint; elemIdx: cint; param: cint; 
                        value: cint)
  proc GetResParamF*(res: H3DRes; elem: cint; elemIdx: cint; param: cint; 
                        compIdx: cint): cfloat
  proc SetResParamF*(res: H3DRes; elem: cint; elemIdx: cint; param: cint; 
                        compIdx: cint; value: cfloat)
  proc GetResParamStr*(res: H3DRes; elem: cint; elemIdx: cint; param: cint): cstring
  proc SetResParamStr*(res: H3DRes; elem: cint; elemIdx: cint; param: cint; 
                          value: cstring)
  proc MapResStream*(res: H3DRes; elem: cint; elemIdx: cint; stream: cint; 
                        read: bool; write: bool): pointer
  proc UnmapResStream*(res: H3DRes)
  proc QueryUnloadedResource*(index: cint): H3DRes
  proc ReleaseUnusedResources*()
  proc CreateTexture*(name: cstring; width: cint; height: cint; fmt: cint; 
                         flags: cint): H3DRes
  proc SetShaderPreambles*(vertPreamble: cstring; fragPreamble: cstring)
  proc SetMaterialUniform*(materialRes: H3DRes; name: cstring; a: cfloat; 
                              b: cfloat; c: cfloat; d: cfloat): bool
  proc ResizePipelineBuffers*(pipeRes: H3DRes; width: cint; height: cint)
  proc GetRenderTargetData*(pipelineRes: H3DRes; targetName: cstring; 
                               bufIndex: cint; width: ptr cint; height: ptr cint; 
                               compCount: ptr cint; dataBuffer: pointer; 
                               bufferSize: cint): bool

  proc GetNodeType*(node: H3DNode): cint

  proc GetNodeParent*(node: H3DNode): H3DNode

  proc SetNodeParent*(node: H3DNode; parent: H3DNode): bool
  proc GetNodeChild*(node: H3DNode; index: cint): H3DNode
  proc AddNodes*(parent: H3DNode; sceneGraphRes: H3DRes): H3DNode
  proc RemoveNode*(node: H3DNode)
  proc CheckNodeTransFlag*(node: H3DNode; reset: bool): bool
  proc GetNodeTransform*(node: H3DNode; tx: ptr cfloat; ty: ptr cfloat; 
                            tz: ptr cfloat; rx: ptr cfloat; ry: ptr cfloat; 
                            rz: ptr cfloat; sx: ptr cfloat; sy: ptr cfloat; 
                            sz: ptr cfloat)
  proc SetNodeTransform*(node: H3DNode; tx: cfloat; ty: cfloat; tz: cfloat; 
                            rx: cfloat; ry: cfloat; rz: cfloat; sx: cfloat; 
                            sy: cfloat; sz: cfloat)
  proc GetNodeTransMats*(node: H3DNode; relMat: ptr ptr cfloat; 
                            absMat: ptr ptr cfloat)
  proc SetNodeTransMat*(node: H3DNode; mat4x4: ptr cfloat)
  proc GetNodeParamI*(node: H3DNode; param: cint): cint
  proc SetNodeParamI*(node: H3DNode; param: cint; value: cint)
  proc GetNodeParamF*(node: H3DNode; param: cint; compIdx: cint): cfloat
  proc SetNodeParamF*(node: H3DNode; param: cint; compIdx: cint; value: cfloat)
  proc GetNodeParamStr*(node: H3DNode; param: cint): cstring
  proc SetNodeParamStr*(node: H3DNode; param: cint; value: cstring)
  proc GetNodeFlags*(node: H3DNode): cint
  proc SetNodeFlags*(node: H3DNode; flags: cint; recursive: bool)
  proc GetNodeAABB*(node: H3DNode; minX, minY, minZ, maxX, maxY, maxZ: var cfloat)
  proc FindNodes*(startNode: H3DNode; name: cstring; kind: H3DNodeTypes): cint

  proc GetNodeFindResult*(index: cint): H3DNode

  proc SetNodeUniforms*(node: H3DNode; uniformData: ptr cfloat; count: cint)
  proc CastRay*(node: H3DNode; ox, oy, oz, dx, dy, dz: cfloat; numNearest: cint): cint
  proc GetCastRayResult*(index: cint; node: ptr H3DNode; distance: ptr cfloat; 
                            intersection: ptr array[0.. <3, cfloat]): bool
  proc CheckNodeVisibility*(node: H3DNode; cameraNode: H3DNode; 
                               checkOcclusion: bool; calcLod: bool): cint
  proc AddGroupNode*(parent: H3DNode; name: cstring): H3DNode
  proc AddModelNode*(parent: H3DNode; name: cstring; geometryRes: H3DRes): H3DNode
  proc SetupModelAnimStage*(modelNode: H3DNode; stage: cint; 
                               animationRes: H3DRes; layer: cint; 
                               startNode: cstring; additive: bool)
  proc SetModelAnimParams*(modelNode: H3DNode; stage: cint; time: cfloat; 
                              weight: cfloat)
  proc SetModelMorpher*(modelNode: H3DNode; target: cstring; weight: cfloat): bool
  proc UpdateModel*(modelNode: H3DNode; flags: cint)
  proc AddMeshNode*(parent: H3DNode; name: cstring; materialRes: H3DRes; 
                       batchStart: cint; batchCount: cint; vertRStart: cint; 
                       vertREnd: cint): H3DNode
  proc AddJointNode*(parent: H3DNode; name: cstring; jointIndex: cint): H3DNode
  proc AddLightNode*(parent: H3DNode; name: cstring; materialRes: H3DRes; 
                        lightingContext: cstring; shadowContext: cstring): H3DNode
  proc AddCameraNode*(parent: H3DNode; name: cstring; pipelineRes: H3DRes): H3DNode
  proc SetupCameraView*(cameraNode: H3DNode; fov: cfloat; aspect: cfloat; 
                           nearDist: cfloat; farDist: cfloat)
  proc GetCameraProjMat*(cameraNode: H3DNode; projMat: var array[0.. <16, cfloat])

  proc AddEmitterNode*(parent: H3DNode; name: cstring; materialRes: H3DRes; 
                          particleEffectRes: H3DRes; maxParticleCount: cint; 
                          respawnCount: cint): H3DNode

  proc UpdateEmitter*(emitterNode: H3DNode; timeDelta: cfloat)
  proc HasEmitterFinished*(emitterNode: H3DNode): bool


importcizzle "h3dext":
  proc AddTerrainNode*(parent: H3DNode; name: cstring; heightMapResm, materialRes: H3DRes): H3DNode
  proc CreateTerrainGeoRes*(node: H3DNode; resName: cstring; meshQuality: cfloat): H3DRes


{.pop.}


