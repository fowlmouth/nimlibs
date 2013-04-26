import 
  nodes, opengl, assimp, gl_helpers, pointer_arithm

type
  PModel* = ref TModel
  TModel* = object of nodes.TNode
    aiScene: assimp.PScene
    glList: GLuint


proc apply_material(mtl: PMaterial) =
  ##foo

proc recursiveRender(scn: assimp.PScene; node: assimp.PNode) =
  var matrix = node.transformation
  (addr matrix).transpose
  
  pushMatrixGL:
    glMultMatrixf(addr matrix[0])
    for i in 0.. <node.meshCount:
      let mesh = scn.meshes.offset(node.meshes[i])
      if mesh.normals.isNil: 
        glDisable GL_LIGHTING
      else:
        glEnable GL_LIGHTING
      
      for ii in 0.. <mesh.faceCount:
        let face = mesh.faces.offset(ii)
        
        var faceMode: GLenum
        case face.indexCount
        of 1: faceMode = GL_POINTS
        of 2: faceMode = GL_LINES
        of 3: faceMode = GL_TRIANGLES
        else: faceMode = GL_POLYGON
        
        beginGL faceMode:
          for iii in 0.. <face.indexCount:
            let ind = face.indices[iii] #.offset(iii)
            if not mesh.colors[0].isNil:
              #echo(mesh.colors[0])
              #glColor4fv(addr mesh.colors[0][ind])
              glColor4fv(addr mesh.colors[0].offset(ind).r)
            if not mesh.normals.isNil:
              #echo(mesh.normals + ind)
              #glNormal3fv(addr mesh.normals[ind].x)
              glNormal3fv(addr mesh.normals.offset(ind).x)
            
            glVertex3fv(addr mesh.vertices.offset(ind).x)
    for i in 0.. <node.childrenCount:
      recursiveRender(scn, node.children[i])
      

proc newModel* (fn: string): PModel =
  var model = aiImportFile(fn, aiProcessPreset_TargetRealtime_Quality)
  if model.isNil:
    echo assimp.getError()
    return
  
  echo "materials: ", model.materialCount
  for i in 0..model.materialCount-1:
    var texIndex = 0'i32
    var path: AIstring
    if model.materials[i.int].getTexture(TexDiffuse, texIndex, addr path):
      echo "material from ", path
  
  #writeFile("log.file", repr(model))
  #echo("sizeof(aistring): ", sizeof(AIstring) - 1024)
  
  new(result)
  init(nodes.PNode(result))
  result.aiScene = model
  
  result.glList = glGenLists(1)
  glNewList(result.glList, GL_COMPILE)
  recursive_render(model, model.rootNode)
  glEndList()

method render*(model: PModel) =
  model.applyTransform
  glCallList model.glList

discard """for i in 0.. <model.meshCount:
  var mesh = model.meshes[i]
  var 
    faces = newSeq[array[0..2, cint]](mesh.faceCount)
  for ii in 0.. <mesh.faceCount:
    copyMem(addr faces[ii], mesh.faces[ii].indices, sizeof(cint)*3)
  
  var
    vao: GLUint
    buffer: GLUint
  
  glGenVertexArrays(1, addr vao)
  glBindVertexArray(vao)
  
  glGenBuffers(1, addr buffer)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER"""
