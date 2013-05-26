

const 
  LibC = "libBulletCollision.so"
  LibD = "libBulletDynamics.so"

type
  ## C interface handles from Bullet-C-Api.h
  PPhysicsSDK = ptr TPhysicsSDK
  TPhysicsSDK {.pure.} = object
  PDynamicsWorld = ptr TDynamicsWorld
  TDynamicsWorld {.pure.} = object
  PRigidBody = ptr TRigidBody
  TRigidBody {.pure.} = object
  PCollisionShape = ptr TCollisionShape
  TCollisionShape {.pure.} = object
  PConstraint = ptr TConstraint
  TConstraint {.pure.} = object

  PCollisionBroadphase = ptr TCollisionBroadphase
  TCollisionBroadphase {.pure.} = object
  
  PBroadphaseProxy = ptr TBroadphaseProxy
  TBroadphaseProxy {.pure.} = object

## note: bullet called this `plReal`, but that name sucks
when defined(BulletUseFloat):
  type BFloat* = cfloat
else:
  type BFloat* = cdouble

type
  TVector3* = tuple[x, y, z: BFloat] #array[0..2, BFloat]
  TQuaternion* = array[0..3, BFloat]
type 
    TBT_BroadphaseCallback* = proc(clientData, object1, object2: pointer){.
      cdecl.}


{.push callConv: cdecl.}
proc newBulletSDK*(): PPhysicsSDK {.
  dynlib: LibD, importc: "plNewBulletSdk".}
proc destroy*(handle: PPhysicsSDK) {.
  dynlib: LibD, importc: "plDeletePhysicsSdk".}

discard """proc createSapBroadphase*(beginCallback: TbtBroadphaseCallback;
      endCallback: TbtBroadphaseCallback): PCollisionBroadphase{.
  importc: "plCreateSapBroadphase", dynlib: LibD.}
proc DestroyBroadphase*(bp: PCollisionBroadphase){.
  importc: "plDestroyBroadphase", dynlib: LibD.}
proc CreateProxy*(bp: PCollisionBroadphase; clientData: pointer; 
      minX, minY, minZ, maxX, maxY, maxZ: BFloat): PBroadphaseProxy{.
  importc: "plCreateProxy", dynlib: LibD.}
proc DestroyProxy*(bp: PCollisionBroadphase; proxyHandle: PBroadphaseProxy){.
  importc: "plDestroyProxy", dynlib: LibD.}"""

# Dynamics World 
proc CreateDynamicsWorld*(physicsSdk: PPhysicsSDK): PDynamicsWorld{.
  importc: "plCreateDynamicsWorld", dynlib: LibD.}
proc destroy*(world: PDynamicsWorld){.
  importc: "plDeleteDynamicsWorld", dynlib: LibD.}
proc StepSimulation*(world: PDynamicsWorld; timeStep: BFloat){.
  importc: "plStepSimulation", dynlib: LibD.}
proc AddRigidBody*(world: PDynamicsWorld; obj: PRigidBody){.
  importc: "plAddRigidBody", dynlib: LibD.}
proc RemoveRigidBody*(world: PDynamicsWorld; obj: PRigidBody){.
  importc: "plRemoveRigidBody", dynlib: LibD.}

# Convex Meshes 
proc NewConvexHullShape*(): PCollisionShape{.
  importc: "plNewConvexHullShape", dynlib: LibD.}
proc AddVertex*(convexHull: PCollisionShape; x, y, z: BFloat) {.
  importc: "plAddVertex", dynlib: LibD.}

# Collision Shape definition 
proc NewSphereShape*(radius: BFloat): PCollisionShape{.
  importc: "plNewSphereShape", dynlib: LibD.}
proc NewBoxShape*(x, y, z: BFloat): PCollisionShape{.
  importc: "plNewBoxShape", dynlib: LibD.}
proc NewCapsuleShape*(radius, height: BFloat): PCollisionShape{.
  importc: "plNewCapsuleShape", dynlib: LibD.}
proc NewConeShape*(radius, height: BFloat): PCollisionShape{.
  importc: "plNewConeShape", dynlib: LibD.}
proc NewCylinderShape*(radius, height: BFloat): PCollisionShape{.
  importc: "plNewCylinderShape", dynlib: LibD.}
proc NewCompoundShape*(): PCollisionShape{.
  importc: "plNewCompoundShape", dynlib: LibD.}
proc AddChildShape*(shape, child: PCollisionShape; childPos: TVector3; 
                    childOrn: TQuaternion){.
    importc: "plAddChildShape", dynlib: LibD.}
proc destroy*(shape: PCollisionShape){.
  importc: "plDeleteShape", dynlib: LibD.}
# Rigid Body  
proc CreateRigidBody*(user_data: pointer; mass: cfloat; 
                    cshape: PCollisionShape): PRigidBody{.
  importc: "plCreateRigidBody", dynlib: LibD.}
proc DeleteRigidBody*(body: PRigidBody){.
  importc: "plDeleteRigidBody", dynlib: LibD.}

# set world transform (position/orientation) 
proc SetPosition*(obj: PRigidBody; position: TVector3){.
  importc: "plSetPosition", dynlib: LibD.}
proc SetOrientation*(obj: PRigidBody; orientation: TQuaternion){.
  importc: "plSetOrientation", dynlib: LibD.}
proc SetEuler*(yaw, pitch, roll: BFloat; orient: TQuaternion){.
  importc: "plSetEuler", dynlib: LibD.}
proc SetOpenGLMatrix*(obj: PRigidBody; matrix: ptr BFloat){.
  importc: "plSetOpenGLMatrix", dynlib: LibD.}

{.pop.}

proc vec3(x, y, z: float): TVector3 =
  result.x = BFloat(x)
  result.y = BFloat(y)
  result.z = BFloat(z)

when isMainModule:
  ## bullet/demos/..?/BulletDino.c 
  import gl, glut, glu
  
  proc draw*() {.cdecl.} =
    nil
  
  let floorverts = [
    [TglFLoat(-20.0), 0.0, 20.0],
    [TglFloat(20.0), 0.0, 20.0],
    [TglFloat(20.0), 0.0, -20.0],
    [TglFloat(-20.0), 0.0, -20.0]]  
  var lightColor = [TglFloat(0.8), 1.0, 0.8, 1.0]
  
  var sdk = newBulletSDK()
  var world = sdk.createDynamicsWorld()
  var floorShape = newConvexHullShape()
  for i in 0.. <4:
    floorshape.addVertex(floorVerts[i][0], floorVerts[i][1], floorVerts[i][2])
  var floorBody = newBoxShape(120.0, 0.0, 120.0)
  var floorRigidBody = createRigidBody(nil, 0.0, floorShape)
  var floorpos, childpos: TVector3
  floorRigidBody.setPosition(floorpos)
  
  world.addRigidBody floorRigidBody
  
  ## dino
  var dinoChildShape = newBoxShape(8.5, 8.5, 8.5)
  var dinoShape = newCompoundShape()
  var childOrn, dinoOrient: TQuaternion
  dinoShape.addChildShape(dinoChildShape, childpos, childorn)
  var dinoRigidBody = createRigidBody(nil, 1.0, dinoShape)
  dinoRigidBody.setPosition(vec3(-10.0, 28.0, 0.0))
  seteuler(0.0, 0.0, 3.15*0.20, dinoOrient)
  addRigidbody(world, dinoRigidBody)
  
  glutInit()
  glutInitDisplayMode GLUT_RGB or GLUT_DOUBLE or GLUT_DEPTH or GLUT_STENCIL or GLUT_MULTISAMPLE
  
  echo(glutCreateWindow("Shadowy Leapin' Lizards"))
  
  glutDisplayFunc draw
  
  
  glEnable(constGL_CULL_FACE)
  glEnable GL_DEPTH_TEST
  glEnable GL_TEXTURE_2D
  glLineWidth 3.0
  
  glMatrixMode GL_PROJECTION
  gluPerspective 40.0, 1.0, 20.0, 100.0
  
  glMatrixMode GL_MODELVIEW
  gluLookat 0.0, 8.0, 6.0, 0.0, 8.0, 0.0, 0.0, 1.0, 0.0
  
  glLightmodelI GL_LIGHT_MODEL_LOCAL_VIEWER, 1
  glLightfv(GL_LIGHT0, GL_DIFFUSE, addr(lightcolor[0]))
  
  
  
  glutMainLoop()
  
  
  sdk.destroy
  