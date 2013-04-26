import opengl, math, vector_math
type
  TVector2f* = TVector2[GLfloat]
  TVector2i* = TVector2[GLint]
  TVector3f* = TVector3[GLfloat]
  TColor4b* = TVector4[GLubyte]
  TColor3b* = TVector3[GLubyte]
  TColor4f* = TVector4[GLclampf]
  TColor3f* = TVector3[GLclampf]
  TVector2u* = TVector2[GLuint]
let
  Vec2fZero* = vec2[GLfloat](0, 0)
  Vec3fZero* = vec3[GLfloat](0, 0, 0)
var quadObj: PGluQuadric

proc init*() =
  ## call after setting up a context and after opengl.loadExtensions()
  if not isNil(quadObj): 
    gluDeleteQuadric(quadObj)
  quadObj = gluNewQuadric()

proc radians*(deg: float): float = deg * PI / 180.0
proc degrees*(rad: float): float = rad * 180.0 / PI

proc vec2f*[A](x, y: A): TVector2f =
  result.x = GLfloat(x)
  result.y = GLfloat(y)
proc vec3f*[A](x, y, z: A): TVector3f =
  result.x = GLfloat(x)
  result.y = GLfloat(y)
  result.z = GLfloat(z)

proc color*(r, g, b: float; a = 1.0):TColor4b = vec4[GLubyte](
  (r * 255.0).glubyte, (g * 255.0).glubyte, 
  (b * 255.0).glubyte, (a * 255.0).glubyte)
proc color*(r, g, b: GLubyte; a = GLubyte(255)): TColor4b =
  result.x = r
  result.y = g
  result.z = b
  result.w = a
proc color*(r, g, b: int; a = 255): TColor4b = 
  return color(GLubyte(r), GLubyte(g), GLubyte(b), GLubyte(a))
  
proc colorf*(r, g, b: float; a = 1.0): TColor4f = vec4[GLclampf](
  r, g, b, a)
proc colorf*(r, g, b: range[0..255]; 
    a: range[0..255] = 255): TColor4f = vec4[GLclampf](
  r / 255, g / 255, b / 255, a / 255)

template beginGL*(kind: GLenum, body: stmt): stmt =
  glBegin(kind)
  body
  glEnd()

template pushMatrixGL*(body: stmt): stmt =
  glPushMatrix()
  body
  glPopMatrix()

proc glColorFV*(a: var TColor4f) {.inline.} = glColor4FV(addr a.x)
proc glColorFV*(a: var TColor3f) {.inline.} = glColor3fv(addr a.x)
proc glColorFV*(a: var TColor4b) {.inline.} = glColor4ubv(addr a.x)
proc glColorFV*(a: var TColor3b) {.inline.} = glColor3ubv(addr a.x)

proc glColor*(c: TColor4f) {.inline.} = glColor4f(c.x, c.y, c.z, c.w)
proc glColor*(c: TColor4b) {.inline.} = glColor4ub(c.x, c.y, c.z, c.w)
proc glColor*(c: TColor3f) {.inline.} = glColor3f(c.x, c.y, c.z)
proc glColor*(c: TColor3b) {.inline.} = glColor3ub(c.x, c.y, c.z)

proc glClearColor*(c: TColor4f) {.inline.} = glClearColor(c.x, c.y, c.z, c.w)

proc glVertexFV*(a: var TVector3f) {.inline.}=
  glVertex3fv(addr a.x)
proc glVertexFV*(a: var TVector2f) {.inline.}=
  glVertex2fv(addr a.x)

proc randF*(prec = 10_000): float = random(prec)/prec
proc random*[T](s: TSlice[T]): T = T(randf() * float(s.b - s.a)) + s.a


proc drawBox*(size: GLfloat, kind: GLenum) =
  const
    n = [ vec3f(-1, 0, 0),
          vec3f( 0, 1, 0),
          vec3f( 1, 0, 0),
          vec3f( 0,-1, 0),
          vec3f( 0, 0, 1),
          vec3f( 0, 0,-1) ]
    faces = [
      [0, 1, 2, 3],
      [3, 2, 6, 7],
      [7, 6, 5, 4],
      [4, 5, 1, 0],
      [5, 6, 2, 1],
      [7, 4, 0, 3]]
  let
    sz: GLfloat = -size / 2.0
  var
    v = [
      vec3f(-sz, -sz, -sz),
      vec3f(-sz, -sz,  sz),
      vec3f(-sz,  sz,  sz),
      vec3f(-sz,  sz, -sz),
      vec3f( sz, -sz, -sz),
      vec3f( sz, -sz,  sz),
      vec3f( sz,  sz,  sz),
      vec3f( sz,  sz, -sz) ]
  
  for i in countdown(5, 0):
    beginGL(kind):
      glNormal3f(n[i].x, n[i].y, n[i].z)
      glVertex3fv(addr v[faces[i][0]].x)
      glVertex3fv(addr v[faces[i][1]].x)
      glVertex3fv(addr v[faces[i][2]].x)
      glVertex3fv(addr v[faces[i][3]].x)


proc drawWireCube*(size: GLfloat) {.inline.} =
  drawBox(size, GL_LINE_LOOP)

proc drawSolidCube*(size: GLfloat) {.inline.} =
  drawBox(size, GL_QUADS)

proc drawWireSphere*(radius: GLfloat; slices, stacks: GLint) =
  gluQuadricDrawStyle(quadObj, GLU_LINE)
  gluQuadricNormals(quadObj, GLU_SMOOTH)
  gluSphere(quadObj, radius, slices, stacks)

proc drawSolidSphere*(radius: GLfloat; slices, stacks: GLint) =
  gluQuadricDrawStyle(quadObj, GLU_FILL)
  gluQuadricNormals(quadObj, GLU_SMOOTH)
  gluSphere(quadObj, radius, slices, stacks)

proc drawWireCone*(base, height: GLfloat; slices, stacks: GLint) =
  gluQuadricDrawStyle(quadObj, GLU_LINE)
  gluQuadricNormals(quadObj, GLU_SMOOTH)
  gluCylinder(quadObj, base, 0.0, height, slices, stacks)

proc drawSolidCone*(base, height: GLfloat; slices, stacks: GLint) =
  gluQuadricDrawStyle(quadObj, GLU_FILL)
  gluQuadricNormals(quadObj, GLU_SMOOTH)
  gluCylinder(quadObj, base, 0.0, height, slices, stacks)


proc DrawNet*(size: GLfloat, LinesX, LinesZ: GLint) =
  beginGL GL_LINES:
    for i in 0.. <LinesX:
      let xc = GLfloat(i)
      glVertex3f(-size / 2.0 + xc / GLfloat(LinesX-1)*size,
        0.0, size / 2.0)
      glVertex3f(-size / 2.0 + xc / GLfloat(LinesX-1)*size,
        0.0, size / -2.0)
    for i in 0.. <LinesX:
      let zc = GLfloat(i)
      glVertex3f(size / 2.0, 0.0, -size / 2.0 + zc / GLfloat(LinesZ-1)*size)
      glVertex3f(size / -2.0, 0.0, -size / 2.0 + zc / GLfloat(LinesZ-1)*size)

