when defined(Linux):
  const LibName = "libode.so.1"
else:
  {.error: "Your platform has not been accounted for.".}

import importc_block

## as of this moment, debian has a separate package for ODE built in single
## precision, otherwise you should know how you compiled ODE. Or you could
## just try both configs to find out (hint: one of them wont work)
when defined(OdeUseFloat):
  type dReal* = float32
elif defined(OdeUseDouble):
  type dReal* = float64
else:
  type dReal* = float ##biggest 

converter toReal*(some: float32): dReal = dReal(some)

when defined(OdeTriIndexShort):
  type dTriIndex* = uint16
else:
  type dTriIndex* = uint32


when defined(OdeUseVectorTypes):
  import vector_math
  type 
    TVector3d* = TVector3[dReal]
    TVector4d* = TVector4[dReal]
else:
  type
    TVector3d* = array[0.. <3, dReal]
    TVector4d* = array[0.. <4, dReal]

type
  PWorld* = ptr object{.pure.}
  PSpace* = ptr object{.pure.}
  PBody* = ptr object{.pure.}
  PGeom* = ptr object{.pure.}
  PJoint* = ptr object{.pure.}
  PJointGroup* = ptr object{.pure.}
  
  PMass* = ptr TMass
  TMass* {.pure.} = object  
    mass*: dReal
    c*: TVector3d
    I*: TMatrix3 
  
  TContactGeom* {.pure.} = object
  
  TNearCallback* = proc(data: pointer; o1, o2: PGeom){.cdecl.}
   
  TTriMeshDataID* = ptr object{.pure, final.}
  
  # contact info used by contact joint 
  dContact* {.pure.} = object 
    surface*: dSurfaceParameters
    geom*: dContactGeom
    fdir1*: TVector3d

  dContactGeom* {.pure.} = object 
    pos*: TVector3d          #/< contact position
    normal*: TVector3d       #/< normal vector
    depth*: dReal           #/< penetration depth
    g1*: PGeom
    g2*: PGeom            #/< the colliding geoms
    side1*: cint
    side2*: cint            #/< (to be documented)
  
  dSurfaceParameters* {.pure.} = object 
    mode*: cint             # must always be defined 
    mu*: dReal              # only defined if the corresponding flag is set in mode 
    mu2*: dReal
    bounce*: dReal
    bounce_vel*: dReal
    soft_erp*: dReal
    soft_cfm*: dReal
    motion1*: dReal
    motion2*: dReal
    motionN*: dReal
    slip1*: dReal
    slip2*: dReal
    
  TerrNum* {.size: sizeof(cint).} = enum
    ErrUnknown = 0, ErrInternalAssert, ErrUserAssert, ErrLCP
  
  TJointFeedback* {.pure.} = object
    f1*, t1*, f2*, t2*: TVector3d  ## force, torque, force, torque

  TJointType* {.size: sizeof(cint).} = enum
    JointUnknown = 0, JointBall, JointHinge, JointSlider,
    JointContact, JointUniversal, JointHinge2, JointFixed,
    JointNull, JointAMotor, JointLMotor, JointPlane2d, JointPR,
    JointPU, JointPiston

  TMatrix3* = array[0.. <12, dReal]
  TMatrix4* = array[0.. <16, dReal]
  TMatrix6* = array[0.. <48, dReal]
  TQuaternion* = array[0..3, dReal]
  
  # ************************************************************************ 
  # heightfield functions 
  # Data storage for heightfield data.
  THeightfieldData* {.pure, final.} = object
  PHeightfieldDataID* = ptr THeightfieldData
  
  dHeightfieldGetHeight* = proc(p_user_data: pointer; x, z: cint): dReal{.cdecl.}
    ##  Used by the callback heightfield data type to sample a height for a
    ##  given cell position.

  dTriCallback* = proc(TriMesh: PGeom; RefObject: PGeom; TriangleIndex: cint): cint
  dTriArrayCallback* = proc (TriMesh: PGeom; RefObject: PGeom; 
                             TriIndices: ptr cint; TriCount: cint)
  dTriRayCallback* = proc(TriMesh: PGeom; Ray: PGeom; TriangleIndex: cint; u: dReal; v: dReal): cint
  dTriTriMergeCallback* = proc (TriMesh: PGeom; FirstTriangleIndex: cint; 
                                SecondTriangleIndex: cint): cint

const 
  dContactMu2* = 0x00000001
  dContactFDir1* = 0x00000002
  dContactBounce* = 0x00000004
  dContactSoftERP* = 0x00000008
  dContactSoftCFM* = 0x00000010
  dContactMotion1* = 0x00000020
  dContactMotion2* = 0x00000040
  dContactMotionN* = 0x00000080
  dContactSlip1* = 0x00000100
  dContactSlip2* = 0x00000200
  dContactApprox0* = 0x00000000
  dContactApprox1_1* = 0x00001000
  dContactApprox1_2* = 0x00002000
  dContactApprox1* = 0x00003000


{.push callConv: cdecl.}
{.push dynlib: LibName.}

importCizzle "dGeom":
  proc Destroy*(geom: PGeom)
    ## Destroy a geom, removing it from any space.
    ## 
    ## Destroy a geom, removing it from any space it is in first. This one
    ## function destroys a geom of any type, but to create a geom you must call
    ## a creation function for that type.
    ## 
    ## When a space is destroyed, if its cleanup mode is 1 (the default) then all
    ## the geoms in that space are automatically destroyed as well.


  proc SetData*(geom: PGeom; data: pointer)
    ## Set the user-defined data pointer stored in the geom.
    #*
    #  @brief 
    # 
    #  @param geom the geom containing the data
    #  @ingroup collide
    # 
  proc GetData*(geom: PGeom): pointer
    ##Get the user-defined data pointer stored in the geom.
    
  proc SetBody*(geom: PGeom; body: PBody) 
    ## Set the body associated with a placeable geom.
    # 
    #  Setting a body on a geom automatically combines the position vector and
    #  rotation matrix of the body and geom, so that setting the position or
    #  orientation of one will set the value for both objects. Setting a body
    #  ID of zero gives the geom its own position and rotation, independent
    #  from any body. If the geom was previously connected to a body then its
    #  new independent position/rotation is set to the current position/rotation
    #  of the body.
    # 
    #  Calling these functions on a non-placeable geom results in a runtime
    #  error in the debug build of ODE.
  proc GetBody*(geom: PGeom): PBody
    ##Get the body associated with a placeable geom.
    ##  @param geom the geom to query.

  proc SetPosition*(geom: PGeom; x, y, z: dReal)
    ## Set the position vector of a placeable geom.
  
  proc SetRotation*(geom: PGeom; R: TMatrix3) 
    ## Set the rotation matrix of a placeable geom.
  proc SetQuaternion*(geom: PGeom; Q: TQuaternion) 
    ##  Set the rotation of a placeable geom.
  proc GetPosition*(geom: PGeom): ptr TVector3d 
    ## Get the position vector of a placeable geom.
  
  proc CopyPosition*(geom: PGeom; pos: TVector3d)
    
  #  @brief Copy the position of a geom into a vector.
  #  @ingroup collide
  #  @param geom  the geom to query
  #  @param pos   a copy of the geom position
  #  @sa dGeomGetPosition
  
  
  proc GetRotation*(geom: PGeom): ptr TMatrix3 ##dReal  \
    ## Get the rotation matrix of a placeable geom. \
    ## returns A pointer to the geom's rotation matrix. (was ptr dreal)
#*
#  @brief Get the rotation matrix of a placeable geom.
# 
#  If the geom is attached to a body, the body's rotation will be returned.
# 
#  Calling this function on a non-placeable geom results in a runtime error in
#  the debug build of ODE.
# 
#  @param geom   the geom to query.
#  @param R      a copy of the geom rotation
#  @sa dGeomGetRotation
#  @ingroup collide
# 
proc dGeomCopyRotation*(geom: PGeom; R: TMatrix3) {.importc.}
#*
#  @brief Get the rotation quaternion of a placeable geom.
# 
#  If the geom is attached to a body, the body's quaternion will be returned.
# 
#  Calling this function on a non-placeable geom results in a runtime error in
#  the debug build of ODE.
# 
#  @param geom the geom to query.
#  @param result a copy of the rotation quaternion.
#  @sa dBodyGetQuaternion
#  @ingroup collide
# 
proc dGeomGetQuaternion*(geom: PGeom; result: TQuaternion) {.importc.}

importcizzle "dGeom":
  proc IsSpace*(geom: PGeom): cint 
    ## returns non-zero if the geom is a space, zero otherwise.
  proc GetAABB*(geom: PGeom; aabb: array[0..6 - 1, dReal])
    ## Return the axis-aligned bounding box.
  proc GetSpace*(a2: PGeom): PSpace
    ## Query for the space containing a particular geom.

#*
#  @brief Given a geom, this returns its class.
# 
#  The ODE classes are:
#   @li dSphereClass
#   @li dBoxClass
#   @li dCylinderClass
#   @li dPlaneClass
#   @li dRayClass
#   @li dConvexClass
#   @li dGeomTransformClass
#   @li dTriMeshClass
#   @li dSimpleSpaceClass
#   @li dHashSpaceClass
#   @li dQuadTreeSpaceClass
#   @li dFirstUserClass
#   @li dLastUserClass
# 
#  User-defined class will return their own number.
# 
#  @param geom the geom to query
#  @returns The geom class ID.
#  @ingroup collide
# 
proc dGeomGetClass*(geom: PGeom): cint {.importc.}
#*
#  @brief Set the "category" bitfield for the given geom.
# 
#  The category bitfield is used by spaces to govern which geoms will
#  interact with each other. The bitfield is guaranteed to be at least
#  32 bits wide. The default category values for newly created geoms
#  have all bits set.
# 
#  @param geom the geom to set
#  @param bits the new bitfield value
#  @ingroup collide
# 
proc dGeomSetCategoryBits*(geom: PGeom; bits: culong) {.importc.}
#*
#  @brief Set the "collide" bitfield for the given geom.
# 
#  The collide bitfield is used by spaces to govern which geoms will
#  interact with each other. The bitfield is guaranteed to be at least
#  32 bits wide. The default category values for newly created geoms
#  have all bits set.
# 
#  @param geom the geom to set
#  @param bits the new bitfield value
#  @ingroup collide
# 
proc dGeomSetCollideBits*(geom: PGeom; bits: culong){.importc.}
#*
#  @brief Get the "category" bitfield for the given geom.
# 
#  @param geom the geom to set
#  @param bits the new bitfield value
#  @sa dGeomSetCategoryBits
#  @ingroup collide
# 
proc dGeomGetCategoryBits*(a2: PGeom): culong {.importc.}
#*
#  @brief Get the "collide" bitfield for the given geom.
# 
#  @param geom the geom to set
#  @param bits the new bitfield value
#  @sa dGeomSetCollideBits
#  @ingroup collide
# 
proc dGeomGetCollideBits*(a2: PGeom): culong {.importc.}
#*
#  @brief Enable a geom.
# 
#  Disabled geoms are completely ignored by dSpaceCollide and dSpaceCollide2,
#  although they can still be members of a space. New geoms are created in
#  the enabled state.
# 
#  @param geom   the geom to enable
#  @sa dGeomDisable
#  @sa dGeomIsEnabled
#  @ingroup collide
# 
proc dGeomEnable*(geom: PGeom) {.importc.}
#*
#  @brief Disable a geom.
# 
#  Disabled geoms are completely ignored by dSpaceCollide and dSpaceCollide2,
#  although they can still be members of a space. New geoms are created in
#  the enabled state.
# 
#  @param geom   the geom to disable
#  @sa dGeomDisable
#  @sa dGeomIsEnabled
#  @ingroup collide
# 
proc dGeomDisable*(geom: PGeom) {.importc.}
#*
#  @brief Check to see if a geom is enabled.
# 
#  Disabled geoms are completely ignored by dSpaceCollide and dSpaceCollide2,
#  although they can still be members of a space. New geoms are created in
#  the enabled state.
# 
#  @param geom   the geom to query
#  @returns Non-zero if the geom is enabled, zero otherwise.
#  @sa dGeomDisable
#  @sa dGeomIsEnabled
#  @ingroup collide
# 
proc dGeomIsEnabled*(geom: PGeom): cint {.importc.}
# ************************************************************************ 
# geom offset from body 
#*
#  @brief Set the local offset position of a geom from its body.
# 
#  Sets the geom's positional offset in local coordinates.
#  After this call, the geom will be at a new position determined from the
#  body's position and the offset.
#  The geom must be attached to a body.
#  If the geom did not have an offset, it is automatically created.
# 
#  @param geom the geom to set.
#  @param x the new X coordinate.
#  @param y the new Y coordinate.
#  @param z the new Z coordinate.
#  @ingroup collide
# 
proc dGeomSetOffsetPosition*(geom: PGeom; x: dReal; y: dReal; z: dReal) {.importc.}
#*
#  @brief Set the local offset rotation matrix of a geom from its body.
# 
#  Sets the geom's rotational offset in local coordinates.
#  After this call, the geom will be at a new position determined from the
#  body's position and the offset.
#  The geom must be attached to a body.
#  If the geom did not have an offset, it is automatically created.
# 
#  @param geom the geom to set.
#  @param R the new rotation matrix.
#  @ingroup collide
# 
proc dGeomSetOffsetRotation*(geom: PGeom; R: TMatrix3) {.importc.}
#*
#  @brief Set the local offset rotation of a geom from its body.
# 
#  Sets the geom's rotational offset in local coordinates.
#  After this call, the geom will be at a new position determined from the
#  body's position and the offset.
#  The geom must be attached to a body.
#  If the geom did not have an offset, it is automatically created.
# 
#  @param geom the geom to set.
#  @param Q the new rotation.
#  @ingroup collide
# 
proc dGeomSetOffsetQuaternion*(geom: PGeom; Q: TQuaternion) {.importc.}
#*
#  @brief Set the offset position of a geom from its body.
# 
#  Sets the geom's positional offset to move it to the new world
#  coordinates.
#  After this call, the geom will be at the world position passed in,
#  and the offset will be the difference from the current body position.
#  The geom must be attached to a body.
#  If the geom did not have an offset, it is automatically created.
# 
#  @param geom the geom to set.
#  @param x the new X coordinate.
#  @param y the new Y coordinate.
#  @param z the new Z coordinate.
#  @ingroup collide
# 
proc dGeomSetOffsetWorldPosition*(geom: PGeom; x,y,z: dReal) {.importc.}
#*
#  @brief Set the offset rotation of a geom from its body.
# 
#  Sets the geom's rotational offset to orient it to the new world
#  rotation matrix.
#  After this call, the geom will be at the world orientation passed in,
#  and the offset will be the difference from the current body orientation.
#  The geom must be attached to a body.
#  If the geom did not have an offset, it is automatically created.
# 
#  @param geom the geom to set.
#  @param R the new rotation matrix.
#  @ingroup collide
# 
proc dGeomSetOffsetWorldRotation*(geom: PGeom; R: TMatrix3) {.importc.}
#*
#  @brief Set the offset rotation of a geom from its body.
# 
#  Sets the geom's rotational offset to orient it to the new world
#  rotation matrix.
#  After this call, the geom will be at the world orientation passed in,
#  and the offset will be the difference from the current body orientation.
#  The geom must be attached to a body.
#  If the geom did not have an offset, it is automatically created.
# 
#  @param geom the geom to set.
#  @param Q the new rotation.
#  @ingroup collide
# 
proc dGeomSetOffsetWorldQuaternion*(geom: PGeom; a3: TQuaternion) {.importc.}
#*
#  @brief Clear any offset from the geom.
# 
#  If the geom has an offset, it is eliminated and the geom is
#  repositioned at the body's position.  If the geom has no offset,
#  this function does nothing.
#  This is more efficient than calling dGeomSetOffsetPosition(zero)
#  and dGeomSetOffsetRotation(identiy), because this function actually
#  eliminates the offset, rather than leaving it as the identity transform.
# 
#  @param geom the geom to have its offset destroyed.
#  @ingroup collide
# 
proc dGeomClearOffset*(geom: PGeom) {.importc.}
#*
#  @brief Check to see whether the geom has an offset.
# 
#  This function will return non-zero if the offset has been created.
#  Note that there is a difference between a geom with no offset,
#  and a geom with an offset that is the identity transform.
#  In the latter case, although the observed behaviour is identical,
#  there is a unnecessary computation involved because the geom will
#  be applying the transform whenever it needs to recalculate its world
#  position.
# 
#  @param geom the geom to query.
#  @returns Non-zero if the geom has an offset, zero otherwise.
#  @ingroup collide
# 
proc dGeomIsOffset*(geom: PGeom): cint {.importc.}
#*
#  @brief Get the offset position vector of a geom.
# 
#  Returns the positional offset of the geom in local coordinates.
#  If the geom has no offset, this function returns the zero vector.
# 
#  @param geom the geom to query.
#  @returns A pointer to the geom's offset vector.
#  @remarks The returned value is a pointer to the geom's internal
#           data structure. It is valid until any changes are made
#           to the geom.
#  @ingroup collide
# 
proc dGeomGetOffsetPosition*(geom: PGeom): ptr dReal {.importc.}
#*
#  @brief Copy the offset position vector of a geom.
# 
#  Returns the positional offset of the geom in local coordinates.
#  If the geom has no offset, this function returns the zero vector.
# 
#  @param geom   the geom to query.
#  @param pos    returns the offset position
#  @ingroup collide
# 
proc dGeomCopyOffsetPosition*(geom: PGeom; pos: TVector3d) {.importc.}
#*
#  @brief Get the offset rotation matrix of a geom.
# 
#  Returns the rotational offset of the geom in local coordinates.
#  If the geom has no offset, this function returns the identity
#  matrix.
# 
#  @param geom the geom to query.
#  @returns A pointer to the geom's offset rotation matrix.
#  @remarks The returned value is a pointer to the geom's internal
#           data structure. It is valid until any changes are made
#           to the geom.
#  @ingroup collide
# 
proc dGeomGetOffsetRotation*(geom: PGeom): ptr dReal  {.importc.}
#* 
#  @brief Copy the offset rotation matrix of a geom.
# 
#  Returns the rotational offset of the geom in local coordinates.
#  If the geom has no offset, this function returns the identity
#  matrix.
# 
#  @param geom   the geom to query.
#  @param R      returns the rotation matrix.
#  @ingroup collide
# 
proc dGeomCopyOffsetRotation*(geom: PGeom; R: TMatrix3) {.importc.}
#*
#  @brief Get the offset rotation quaternion of a geom.
# 
#  Returns the rotation offset of the geom as a quaternion.
#  If the geom has no offset, the identity quaternion is returned.
# 
#  @param geom the geom to query.
#  @param result a copy of the rotation quaternion.
#  @ingroup collide
# 
proc dGeomGetOffsetQuaternion*(geom: PGeom; result: TQuaternion) {.importc.}



#  @brief Given two geoms o1 and o2 that potentially intersect,
#  generate contact information for them.
# 
#  Internally, this just calls the correct class-specific collision
#  functions for o1 and o2.
# 
#  @param o1 The first geom to test.
#  @param o2 The second geom to test.
# 
#  @param flags The flags specify how contacts should be generated if
#  the geoms touch. The lower 16 bits of flags is an integer that
#  specifies the maximum number of contact points to generate. You must
#  ask for at least one contact. 
#  Additionally, following bits may be set:
#  CONTACTS_UNIMPORTANT -- just generate any contacts (skip contact refining).
#  All other bits in flags must be set to zero. In the future the other bits 
#  may be used to select from different contact generation strategies.
# 
#  @param contact Points to an array of dContactGeom structures. The array
#  must be able to hold at least the maximum number of contacts. These
#  dContactGeom structures may be embedded within larger structures in the
#  array -- the skip parameter is the byte offset from one dContactGeom to
#  the next in the array. If skip is sizeof(dContactGeom) then contact
#  points to a normal (C-style) array. It is an error for skip to be smaller
#  than sizeof(dContactGeom).
# 
#  @returns If the geoms intersect, this function returns the number of contact
#  points generated (and updates the contact array), otherwise it returns 0
#  (and the contact array is not touched).
# 
#  @remarks If a space is passed as o1 or o2 then this function will collide
#  all objects contained in o1 with all objects contained in o2, and return
#  the resulting contact points. This method for colliding spaces with geoms
#  (or spaces with spaces) provides no user control over the individual
#  collisions. To get that control, use dSpaceCollide or dSpaceCollide2 instead.
# 
#  @remarks If o1 and o2 are the same geom then this function will do nothing
#  and return 0. Technically speaking an object intersects with itself, but it
#  is not useful to find contact points in this case.
# 
#  @remarks This function does not care if o1 and o2 are in the same space or not
#  (or indeed if they are in any space at all).
# 
#  @ingroup collide
# 
proc dCollide*(o1, o2: PGeom; flags: cint; contact: ptr dContactGeom; 
                skip: cint): cint {.importc.}
#*
#  @brief 
# 
#  @param space The space to test.
# 
#  @param data Passed from dSpaceCollide directly to the callback
#  function. Its meaning is user defined. The o1 and o2 arguments are the
#  geoms that may be near each other.
# 
#  @param callback A callback function is of type @ref TNearCallback.
# 
#  @remarks Other spaces that are contained within the colliding space are
#  not treated specially, i.e. they are not recursed into. The callback
#  function may be passed these contained spaces as one or both geom
#  arguments.
# 
#  @remarks dSpaceCollide() is guaranteed to pass all intersecting geom
#  pairs to the callback function, but may also pass close but
#  non-intersecting pairs. The number of these calls depends on the
#  internal algorithms used by the space. Thus you should not expect
#  that dCollide will return contacts for every pair passed to the
#  callback.
# 
#  @sa dSpaceCollide2
#  @ingroup collide
# 

importcizzle "dSpace":
  proc Collide*(space: PSpace; data: pointer; 
                 callback: TNearCallback)
    ## Determines which pairs of geoms in a space may potentially intersect,
    ## and calls the callback function for each candidate pair.

proc Collide*(space1: PGeom; space2: PGeom; data: pointer; 
                     callback: ptr TNearCallback) {.importc: "dSpaceCollide2".}
  ## Determines which geoms from one space may potentially intersect with 
  ## geoms from another space, and calls the callback function for each candidate 
  ## pair. 


# ************************************************************************ 
# standard classes 
# the maximum number of user classes that are supported 
const 
  dMaxUserClasses* = 4
# class numbers - each geometry object needs a unique number 
const 
  dSphereClass* = 0
  dBoxClass* = 1
  dCapsuleClass* = 2
  dCylinderClass* = 3
  dPlaneClass* = 4
  dRayClass* = 5
  dConvexClass* = 6
  dGeomTransformClass* = 7
  dTriMeshClass* = 8
  dHeightfieldClass* = 9
  dFirstSpaceClass* = 10    #dSimpleSpaceClass = dFirstSpaceClass,
  dHashSpaceClass* = 11
  dSweepAndPruneSpaceClass* = 12 # SAP
  dQuadTreeSpaceClass* = 13 #dLastSpaceClass = dQuadTreeSpaceClass,
  dFirstUserClass* = 14     #dLastUserClass = dFirstUserClass + dMaxUserClasses - 1,
  dGeomNumClasses* = 15
#*

importcizzle "dGeom":
  proc SphereSetRadius*(sphere: PGeom; radius: dReal)
    ##  Set the radius of a sphere geom.
  proc SphereGetRadius*(sphere: PGeom): dReal
    ## Retrieves the radius of a sphere geom.
  proc SpherePointDepth*(sphere: PGeom; x, y, z: dReal): dReal
    ## Calculate the depth of the a given point within a sphere.
    
  proc SetConvex*(g: PGeom; planes: ptr dReal; count: cuint; 
    points: ptr dReal; pointcount: cuint; polygons: ptr cuint)
    
  proc BoxSetLengths*(box: PGeom; lx, ly, lz: dReal) 
  proc BoxGetLengths*(box: PGeom; result: var TVector3d)
    ## Get the side lengths of a box.
  proc BoxPointDepth*(box: PGeom; x, y, z: dReal): dReal 
    ## Return the depth of a point in a box.
    
  proc PlaneSetParams*(plane: PGeom; a, b, c, d: dReal)
  proc PlaneGetParams*(plane: PGeom; result: var TVector4d)
  proc PlanePointDepth*(plane: PGeom; x, y, z: dReal): dReal
    
  proc CapsuleSetParams*(ccylinder: PGeom; radius, length: dReal)
  proc CapsuleGetParams*(ccylinder: PGeom; radius: var dReal; length: var dReal)
  proc CapsulePointDepth*(ccylinder: PGeom; x, y, z: dReal): dReal 

  proc CylinderSetParams*(cylinder: PGeom; radius, length: dReal)
  proc CylinderGetParams*(cylinder: PGeom; radius, length: var dReal)
  
  proc RaySetLength*(ray: PGeom; length: dReal)
  proc RayGetLength*(ray: PGeom): dReal
  proc RaySet*(ray: PGeom; px, py, pz: dReal; dx, dy, dz: dReal)
  proc RayGet*(ray: PGeom; start: TVector3d; dir: TVector3d)
  proc RaySetParams*(g: PGeom; FirstContact: cint; BackfaceCull: cint)
  proc RayGetParams*(g: PGeom; FirstContact: var cint; BackfaceCull: var cint)
  proc RaySetClosestHit*(g: PGeom; closestHit: cint)
  proc RayGetClosestHit*(g: PGeom): cint 

  proc TransformSetGeom*(g: PGeom; obj: PGeom)
  proc TransformGetGeom*(g: PGeom): PGeom
  proc TransformSetCleanup*(g: PGeom; mode: cint)
  proc TransformGetCleanup*(g: PGeom): cint
  proc TransformSetInfo*(g: PGeom; mode: cint)
  proc TransformGetInfo*(g: PGeom): cint

importcizzle "d":
  proc CreateSphere*(space: PSpace; radius: dReal): PGeom
  proc CreateConvex*(space: PSpace; planes: ptr dReal; planecount: cuint; 
    points: ptr dReal; pointcount: cuint; polygons: ptr cuint): PGeom 
  proc CreateBox*(space: PSpace; lx, ly, lz: dReal): PGeom 
  proc CreatePlane*(space: PSpace; a, b, c, d: dReal): PGeom 
  proc CreateCapsule*(space: PSpace; radius, length: dReal): PGeom
  proc CreateRay*(space: PSpace; length: dReal): PGeom 
  proc CreateCylinder*(space: PSpace; radius, length: dReal): PGeom 
  proc CreateGeomTransform*(space: PSpace): PGeom{.importc.}
  
# For now we want to have a backwards compatible C-API, note: C++ API is not.
## TODO these translated as const for some reason, they should be template or
## inline procs
discard """const 
dCreateCCylinder* = dCreateCapsule
dGeomCCylinderSetParams* = dGeomCapsuleSetParams
dGeomCCylinderGetParams* = dGeomCapsuleGetParams
dGeomCCylinderPointDepth* = dGeomCapsulePointDepth
dCCylinderClass* = dCapsuleClass
"""

#
#  Set/get ray flags that influence ray collision detection.
#  These flags are currently only noticed by the trimesh collider, because
#  they can make a major differences there.
# 

#*
#  @brief Creates a heightfield geom.
# 
#  Uses the information in the given PHeightfieldDataID to construct
#  a geom representing a heightfield in a collision space.
# 
#  @param space The space to add the geom to.
#  @param data The PHeightfieldDataID created by dGeomHeightfieldDataCreate and
#  setup by dGeomHeightfieldDataBuildCallback, dGeomHeightfieldDataBuildByte,
#  dGeomHeightfieldDataBuildShort or dGeomHeightfieldDataBuildFloat.
#  @param bPlaceable If non-zero this geom can be transformed in the world using the
#  usual functions such as dGeomSetPosition and dGeomSetRotation. If the geom is
#  not set as placeable, then it uses a fixed orientation where the global y axis
#  represents the dynamic 'height' of the heightfield.
# 
#  @return A geom id to reference this geom in other calls.
# 
#  @ingroup collide
# 
proc dCreateHeightfield*(space: PSpace; data: PHeightfieldDataID; 
                         bPlaceable: cint): PGeom{.importc.}
#*
#  @brief Creates a new empty PHeightfieldDataID.
# 
#  Allocates a new PHeightfieldDataID and returns it. You must call
#  dGeomHeightfieldDataDestroy to destroy it after the geom has been removed.
#  The PHeightfieldDataID value is used when specifying a data format type.
# 
#  @return A PHeightfieldDataID for use with dGeomHeightfieldDataBuildCallback,
#  dGeomHeightfieldDataBuildByte, dGeomHeightfieldDataBuildShort or
#  dGeomHeightfieldDataBuildFloat.
#  @ingroup collide
# 
proc dGeomHeightfieldDataCreate*(): PHeightfieldDataID{.importc.}
#*
#  @brief Destroys a PHeightfieldDataID.
# 
#  Deallocates a given PHeightfieldDataID and all managed resources.
# 
#  @param d A PHeightfieldDataID created by dGeomHeightfieldDataCreate
#  @ingroup collide
# 
proc dGeomHeightfieldDataDestroy*(d: PHeightfieldDataID){.importc.}
#*
#  @brief Configures a PHeightfieldDataID to use a callback to
#  retrieve height data.
# 
#  Before a PHeightfieldDataID can be used by a geom it must be
#  configured to specify the format of the height data.
#  This call specifies that the heightfield data is computed by
#  the user and it should use the given callback when determining
#  the height of a given element of it's shape.
# 
#  @param d A new PHeightfieldDataID created by dGeomHeightfieldDataCreate
# 
#  @param width Specifies the total 'width' of the heightfield along
#  the geom's local x axis.
#  @param depth Specifies the total 'depth' of the heightfield along
#  the geom's local z axis.
# 
#  @param widthSamples Specifies the number of vertices to sample
#  along the width of the heightfield. Each vertex has a corresponding
#  height value which forms the overall shape.
#  Naturally this value must be at least two or more.
#  @param depthSamples Specifies the number of vertices to sample
#  along the depth of the heightfield.
# 
#  @param scale A uniform scale applied to all raw height data.
#  @param offset An offset applied to the scaled height data.
# 
#  @param thickness A value subtracted from the lowest height
#  value which in effect adds an additional cuboid to the base of the
#  heightfield. This is used to prevent geoms from looping under the
#  desired terrain and not registering as a collision. Note that the
#  thickness is not affected by the scale or offset parameters.
# 
#  @param bWrap If non-zero the heightfield will infinitely tile in both
#  directions along the local x and z axes. If zero the heightfield is
#  bounded from zero to width in the local x axis, and zero to depth in
#  the local z axis.
# 
#  @ingroup collide
# 
proc dGeomHeightfieldDataBuildCallback*(d: PHeightfieldDataID; 
    pUserData: pointer; pCallback: ptr dHeightfieldGetHeight; width: dReal; 
    depth: dReal; widthSamples: cint; depthSamples: cint; scale: dReal; 
    offset: dReal; thickness: dReal; bWrap: cint){.importc.}
#*
#  @brief Configures a PHeightfieldDataID to use height data in byte format.
# 
#  Before a PHeightfieldDataID can be used by a geom it must be
#  configured to specify the format of the height data.
#  This call specifies that the heightfield data is stored as a rectangular
#  array of bytes (8 bit unsigned) representing the height at each sample point.
# 
#  @param d A new PHeightfieldDataID created by dGeomHeightfieldDataCreate
# 
#  @param pHeightData A pointer to the height data.
#  @param bCopyHeightData When non-zero the height data is copied to an
#  internal store. When zero the height data is accessed by reference and
#  so must persist throughout the lifetime of the heightfield.
# 
#  @param width Specifies the total 'width' of the heightfield along
#  the geom's local x axis.
#  @param depth Specifies the total 'depth' of the heightfield along
#  the geom's local z axis.
# 
#  @param widthSamples Specifies the number of vertices to sample
#  along the width of the heightfield. Each vertex has a corresponding
#  height value which forms the overall shape.
#  Naturally this value must be at least two or more.
#  @param depthSamples Specifies the number of vertices to sample
#  along the depth of the heightfield.
# 
#  @param scale A uniform scale applied to all raw height data.
#  @param offset An offset applied to the scaled height data.
# 
#  @param thickness A value subtracted from the lowest height
#  value which in effect adds an additional cuboid to the base of the
#  heightfield. This is used to prevent geoms from looping under the
#  desired terrain and not registering as a collision. Note that the
#  thickness is not affected by the scale or offset parameters.
# 
#  @param bWrap If non-zero the heightfield will infinitely tile in both
#  directions along the local x and z axes. If zero the heightfield is
#  bounded from zero to width in the local x axis, and zero to depth in
#  the local z axis.
# 
#  @ingroup collide
# 
proc dGeomHeightfieldDataBuildByte*(d: PHeightfieldDataID; 
                                    pHeightData: ptr cuchar; 
                                    bCopyHeightData: cint; width: dReal; 
                                    depth: dReal; widthSamples: cint; 
                                    depthSamples: cint; scale: dReal; 
                                    offset: dReal; thickness: dReal; 
                                    bWrap: cint){.importc.}
#*
#  @brief Configures a PHeightfieldDataID to use height data in short format.
# 
#  Before a PHeightfieldDataID can be used by a geom it must be
#  configured to specify the format of the height data.
#  This call specifies that the heightfield data is stored as a rectangular
#  array of shorts (16 bit signed) representing the height at each sample point.
# 
#  @param d A new PHeightfieldDataID created by dGeomHeightfieldDataCreate
# 
#  @param pHeightData A pointer to the height data.
#  @param bCopyHeightData When non-zero the height data is copied to an
#  internal store. When zero the height data is accessed by reference and
#  so must persist throughout the lifetime of the heightfield.
# 
#  @param width Specifies the total 'width' of the heightfield along
#  the geom's local x axis.
#  @param depth Specifies the total 'depth' of the heightfield along
#  the geom's local z axis.
# 
#  @param widthSamples Specifies the number of vertices to sample
#  along the width of the heightfield. Each vertex has a corresponding
#  height value which forms the overall shape.
#  Naturally this value must be at least two or more.
#  @param depthSamples Specifies the number of vertices to sample
#  along the depth of the heightfield.
# 
#  @param scale A uniform scale applied to all raw height data.
#  @param offset An offset applied to the scaled height data.
# 
#  @param thickness A value subtracted from the lowest height
#  value which in effect adds an additional cuboid to the base of the
#  heightfield. This is used to prevent geoms from looping under the
#  desired terrain and not registering as a collision. Note that the
#  thickness is not affected by the scale or offset parameters.
# 
#  @param bWrap If non-zero the heightfield will infinitely tile in both
#  directions along the local x and z axes. If zero the heightfield is
#  bounded from zero to width in the local x axis, and zero to depth in
#  the local z axis.
# 
#  @ingroup collide
# 
proc dGeomHeightfieldDataBuildShort*(d: PHeightfieldDataID; 
                                     pHeightData: ptr cshort; 
                                     bCopyHeightData: cint; width: dReal; 
                                     depth: dReal; widthSamples: cint; 
                                     depthSamples: cint; scale: dReal; 
                                     offset: dReal; thickness: dReal; 
                                     bWrap: cint){.importc.}
#*
#  @brief Configures a PHeightfieldDataID to use height data in 
#  single precision floating point format.
# 
#  Before a PHeightfieldDataID can be used by a geom it must be
#  configured to specify the format of the height data.
#  This call specifies that the heightfield data is stored as a rectangular
#  array of single precision floats representing the height at each
#  sample point.
# 
#  @param d A new PHeightfieldDataID created by dGeomHeightfieldDataCreate
# 
#  @param pHeightData A pointer to the height data.
#  @param bCopyHeightData When non-zero the height data is copied to an
#  internal store. When zero the height data is accessed by reference and
#  so must persist throughout the lifetime of the heightfield.
# 
#  @param width Specifies the total 'width' of the heightfield along
#  the geom's local x axis.
#  @param depth Specifies the total 'depth' of the heightfield along
#  the geom's local z axis.
# 
#  @param widthSamples Specifies the number of vertices to sample
#  along the width of the heightfield. Each vertex has a corresponding
#  height value which forms the overall shape.
#  Naturally this value must be at least two or more.
#  @param depthSamples Specifies the number of vertices to sample
#  along the depth of the heightfield.
# 
#  @param scale A uniform scale applied to all raw height data.
#  @param offset An offset applied to the scaled height data.
# 
#  @param thickness A value subtracted from the lowest height
#  value which in effect adds an additional cuboid to the base of the
#  heightfield. This is used to prevent geoms from looping under the
#  desired terrain and not registering as a collision. Note that the
#  thickness is not affected by the scale or offset parameters.
# 
#  @param bWrap If non-zero the heightfield will infinitely tile in both
#  directions along the local x and z axes. If zero the heightfield is
#  bounded from zero to width in the local x axis, and zero to depth in
#  the local z axis.
# 
#  @ingroup collide
# 
proc dGeomHeightfieldDataBuildSingle*(d: PHeightfieldDataID; 
                                      pHeightData: ptr cfloat; 
                                      bCopyHeightData: cint; width: dReal; 
                                      depth: dReal; widthSamples: cint; 
                                      depthSamples: cint; scale: dReal; 
                                      offset: dReal; thickness: dReal; 
                                      bWrap: cint){.importc.}
#*
#  @brief Configures a PHeightfieldDataID to use height data in 
#  double precision floating point format.
# 
#  Before a PHeightfieldDataID can be used by a geom it must be
#  configured to specify the format of the height data.
#  This call specifies that the heightfield data is stored as a rectangular
#  array of double precision floats representing the height at each
#  sample point.
# 
#  @param d A new PHeightfieldDataID created by dGeomHeightfieldDataCreate
# 
#  @param pHeightData A pointer to the height data.
#  @param bCopyHeightData When non-zero the height data is copied to an
#  internal store. When zero the height data is accessed by reference and
#  so must persist throughout the lifetime of the heightfield.
# 
#  @param width Specifies the total 'width' of the heightfield along
#  the geom's local x axis.
#  @param depth Specifies the total 'depth' of the heightfield along
#  the geom's local z axis.
# 
#  @param widthSamples Specifies the number of vertices to sample
#  along the width of the heightfield. Each vertex has a corresponding
#  height value which forms the overall shape.
#  Naturally this value must be at least two or more.
#  @param depthSamples Specifies the number of vertices to sample
#  along the depth of the heightfield.
# 
#  @param scale A uniform scale applied to all raw height data.
#  @param offset An offset applied to the scaled height data.
# 
#  @param thickness A value subtracted from the lowest height
#  value which in effect adds an additional cuboid to the base of the
#  heightfield. This is used to prevent geoms from looping under the
#  desired terrain and not registering as a collision. Note that the
#  thickness is not affected by the scale or offset parameters.
# 
#  @param bWrap If non-zero the heightfield will infinitely tile in both
#  directions along the local x and z axes. If zero the heightfield is
#  bounded from zero to width in the local x axis, and zero to depth in
#  the local z axis.
# 
#  @ingroup collide
# 
proc dGeomHeightfieldDataBuildDouble*(d: PHeightfieldDataID; 
                                      pHeightData: ptr cdouble; 
                                      bCopyHeightData: cint; width: dReal; 
                                      depth: dReal; widthSamples: cint; 
                                      depthSamples: cint; scale: dReal; 
                                      offset: dReal; thickness: dReal; 
                                      bWrap: cint){.importc.}
#*
#  @brief Manually set the minimum and maximum height bounds.
# 
#  This call allows you to set explicit min / max values after initial
#  creation typically for callback heightfields which default to +/- infinity,
#  or those whose data has changed. This must be set prior to binding with a
#  geom, as the the AABB is not recomputed after it's first generation.
# 
#  @remarks The minimum and maximum values are used to compute the AABB
#  for the heightfield which is used for early rejection of collisions.
#  A close fit will yield a more efficient collision check.
# 
#  @param d A PHeightfieldDataID created by dGeomHeightfieldDataCreate
#  @param min_height The new minimum height value. Scale, offset and thickness is then applied.
#  @param max_height The new maximum height value. Scale and offset is then applied.
#  @ingroup collide
# 
proc dGeomHeightfieldDataSetBounds*(d: PHeightfieldDataID; minHeight: dReal; 
                                    maxHeight: dReal){.importc.}
#*
#  @brief Assigns a PHeightfieldDataID to a heightfield geom.
# 
#  Associates the given PHeightfieldDataID with a heightfield geom.
#  This is done without affecting the GEOM_PLACEABLE flag.
# 
#  @param g A geom created by dCreateHeightfield
#  @param d A PHeightfieldDataID created by dGeomHeightfieldDataCreate
#  @ingroup collide
# 
proc dGeomHeightfieldSetHeightfieldData*(g: PGeom; d: PHeightfieldDataID){.importc.}
#*
#  @brief Gets the PHeightfieldDataID bound to a heightfield geom.
# 
#  Returns the PHeightfieldDataID associated with a heightfield geom.
# 
#  @param g A geom created by dCreateHeightfield
#  @return The PHeightfieldDataID which may be NULL if none was assigned.
#  @ingroup collide
# 
proc dGeomHeightfieldGetHeightfieldData*(g: PGeom): PHeightfieldDataID{.importc.}
# ************************************************************************ 
# utility functions 
proc dClosestLineSegmentPoints*(a1: TVector3d; a2: TVector3d; b1: TVector3d; 
                                b2: TVector3d; cp1: TVector3d; cp2: TVector3d){.importc.}
proc dBoxTouchesBox*(p1: TVector3d; R1: TMatrix3; side1: TVector3d; 
                     p2: TVector3d; R2: TMatrix3; side2: TVector3d): cint {.importc.}
# The meaning of flags parameter is the same as in dCollide()
proc dBoxBox*(p1: TVector3d; R1: TMatrix3; side1: TVector3d; p2: TVector3d; 
              R2: TMatrix3; side2: TVector3d; normal: TVector3d; 
              depth: ptr dReal; return_code: ptr cint; flags: cint; 
              contact: ptr dContactGeom; skip: cint): cint{.importc.}
proc dInfiniteAABB*(geom: PGeom; aabb: array[0..6 - 1, dReal]){.importc.}
# ************************************************************************ 
# custom classes 
type 
  dGetAABBFn* = proc (a2: PGeom; aabb: array[0..6 - 1, dReal]){.cdecl.}
  dColliderFn* = proc (o1: PGeom; o2: PGeom; flags: cint; 
                       contact: ptr dContactGeom; skip: cint): cint{.cdecl.}
  dGetColliderFnFn* = proc (num: cint): ptr dColliderFn {.cdecl.}
  dGeomDtorFn* = proc (o: PGeom) {.cdecl.}
  dAABBTestFn* = proc (o1: PGeom; o2: PGeom; aabb: array[0..6 - 1, dReal]): cint{.cdecl.}
  dGeomClass* {.pure, final.} = object 
    bytes*: cint
    collider*: ptr dGetColliderFnFn
    aabb*: ptr dGetAABBFn
    aabb_test*: ptr dAABBTestFn
    dtor*: ptr dGeomDtorFn

proc dCreateGeomClass*(classptr: ptr dGeomClass): cint{.importc.}
proc dGeomGetClassData*(a2: PGeom): pointer{.importc.}
proc dCreateGeom*(classnum: cint): PGeom{.importc.}
#*
#  @brief Sets a custom collider function for two geom classes. 
# 
#  @param i The first geom class handled by this collider
#  @param j The second geom class handled by this collider
#  @param fn The collider function to use to determine collisions.
#  @ingroup collide
# 
proc dSetColliderOverride*(i: cint; j: cint; fn: ptr dColliderFn){.importc.}



proc CreateSimpleSpace*(space: PSpace): PSpace {.importc: "dSimpleSpaceCreate".}
proc CreateHashSpace*(space: PSpace): PSpace {.importc: "dHashSpaceCreate".}
proc CreateQuadTreeSpace*(space: PSpace; Center: TVector3d; Extents: TVector3d;
  Depth: cint): PSpace{.importc: "dQuadTreeSpaceCreate".}
# SAP
# Order XZY or ZXY usually works best, if your Y is up.
const 
  dSAP_AXES_XYZ* = ((0) or (1 shl 2) or (2 shl 4))
  dSAP_AXES_XZY* = ((0) or (2 shl 2) or (1 shl 4))
  dSAP_AXES_YXZ* = ((1) or (0 shl 2) or (2 shl 4))
  dSAP_AXES_YZX* = ((1) or (2 shl 2) or (0 shl 4))
  dSAP_AXES_ZXY* = ((2) or (0 shl 2) or (1 shl 4))
  dSAP_AXES_ZYX* = ((2) or (1 shl 2) or (0 shl 4))
proc dSweepAndPruneSpaceCreate*(space: PSpace; axisorder: cint): PSpace{.importc.}
proc dSpaceDestroy*(a2: PSpace){.importc.}
proc dHashSpaceSetLevels*(space: PSpace; minlevel: cint; maxlevel: cint){.importc.}
proc dHashSpaceGetLevels*(space: PSpace; minlevel: ptr cint; 
                          maxlevel: ptr cint){.importc.}
proc dSpaceSetCleanup*(space: PSpace; mode: cint){.importc.}
proc dSpaceGetCleanup*(space: PSpace): cint{.importc.}
#*
# @brief Sets sublevel value for a space.
#
# Sublevel affects how the space is handled in dSpaceCollide2 when it is collided
# with another space. If sublevels of both spaces match, the function iterates 
# geometries of both spaces and collides them with each other. If sublevel of one
# space is greater than the sublevel of another one, only the geometries of the 
# space with greater sublevel are iterated, another space is passed into 
# collision callback as a geometry itself. By default all the spaces are assigned
# zero sublevel.
#
# @note
# The space sublevel @e IS @e NOT automatically updated when one space is inserted
# into another or removed from one. It is a client's responsibility to update sublevel
# value if necessary.
#
# @param space the space to modify
# @param sublevel the sublevel value to be assigned
# @ingroup collide
# @see dSpaceGetSublevel
# @see dSpaceCollide2
#
proc dSpaceSetSublevel*(space: PSpace; sublevel: cint){.importc.}
#*
# @brief Gets sublevel value of a space.
#
# Sublevel affects how the space is handled in dSpaceCollide2 when it is collided
# with another space. See @c dSpaceSetSublevel for more details.
#
# @param space the space to query
# @returns the sublevel value of the space
# @ingroup collide
# @see dSpaceSetSublevel
# @see dSpaceCollide2
#
proc dSpaceGetSublevel*(space: PSpace): cint{.importc.}
#*
# @brief Sets manual cleanup flag for a space.
#
# Manual cleanup flag marks a space as eligible for manual thread data cleanup.
# This function should be called for every space object right after creation in 
# case if ODE has been initialized with @c dInitFlagManualThreadCleanup flag.
# 
# Failure to set manual cleanup flag for a space may lead to some resources 
# remaining leaked until the program exit.
#
# @param space the space to modify
# @param mode 1 for manual cleanup mode and 0 for default cleanup mode
# @ingroup collide
# @see dSpaceGetManualCleanup
# @see dInitODE2
#
proc dSpaceSetManualCleanup*(space: PSpace; mode: cint){.importc.}
#*
# @brief Get manual cleanup flag of a space.
#
# Manual cleanup flag marks a space space as eligible for manual thread data cleanup.
# See @c dSpaceSetManualCleanup for more details.
# 
# @param space the space to query
# @returns 1 for manual cleanup mode and 0 for default cleanup mode of the space
# @ingroup collide
# @see dSpaceSetManualCleanup
# @see dInitODE2
#
proc dSpaceGetManualCleanup*(space: PSpace): cint{.importc.}
proc dSpaceAdd*(a2: PSpace; a3: PGeom){.importc.}
proc dSpaceRemove*(a2: PSpace; a3: PGeom){.importc.}
proc dSpaceQuery*(a2: PSpace; a3: PGeom): cint{.importc.}
proc dSpaceClean*(a2: PSpace){.importc.}
proc dSpaceGetNumGeoms*(a2: PSpace): cint{.importc.}
proc dSpaceGetGeom*(a2: PSpace; i: cint): PGeom{.importc.}
#*
#  @brief Given a space, this returns its class.
# 
#  The ODE classes are:
#   @li dSimpleSpaceClass
#   @li dHashSpaceClass
#   @li dSweepAndPruneSpaceClass
#   @li dQuadTreeSpaceClass
#   @li dFirstUserClass
#   @li dLastUserClass
# 
#  The class id not defined by the user should be between
#  dFirstSpaceClass and dLastSpaceClass.
# 
#  User-defined class will return their own number.
# 
#  @param space the space to query
#  @returns The space class ID.
#  @ingroup collide
# 
proc dSpaceGetClass*(space: PSpace): cint{.importc.}



proc CreateWorld*(): PWorld {.importc: "dWorldCreate".} 
  # The world object is a container for rigid bodies and joints. Objects in
  #  different worlds can not interact, for example rigid bodies from two
  #  different worlds can not collide.
  # 
  #  All the objects in a world exist at the same point in time, thus one
  #  reason to use separate worlds is to simulate systems at different rates.
  #  Most applications will only need one world.
  # 
  #*
  #  @brief Destroy a world and everything in it.
  # 
  #  This includes all bodies, and all joints that are not part of a joint
  #  group. Joints that are part of a joint group will be deactivated, and
  #  can be destroyed by calling, for example, dJointGroupEmpty().

importCizzle "dWorld":
  proc Destroy*(world: PWorld)
  #*
  #  @brief Set the world's global gravity vector.
  # 
  #  The units are m/s^2, so Earth's gravity vector would be (0,0,-9.81),
  #  assuming that +z is up. The default is no gravity, i.e. (0,0,0).
  # 
  #  @ingroup world
  # 
  proc SetGravity*(a2: PWorld; x: dReal; y: dReal; z: dReal)
  #*{.importc.}
  #  @brief Get the gravity vector for a given world.
  #  @ingroup world
  # 
  proc GetGravity*(a2: PWorld; gravity: var TVector3d)


  #*
  #  @brief Set the global ERP value, that controls how much error
  #  correction is performed in each time step.
  #  @ingroup world
  #  @param PWorld the identifier of the world.
  #  @param erp Typical values are in the range 0.1--0.8. The default is 0.2.
  # 
  proc SetERP*(a2: PWorld; erp: dReal)
  #*
  #  @brief Get the error reduction parameter.
  #  @ingroup world
  #  @return ERP value
  # 
  proc GetERP*(a2: PWorld): dReal
  #*
  #  @brief Set the global CFM (constraint force mixing) value.
  #  @ingroup world
  #  @param cfm Typical values are in the range @m{10^{-9}} -- 1.
  #  The default is 10^-5 if single precision is being used, or 10^-10
  #  if double precision is being used.
  # 
  proc SetCFM*(a2: PWorld; cfm: dReal)
  #*
  #  @brief Get the constraint force mixing value.
  #  @ingroup world
  #  @return CFM value
  # 
  proc GetCFM*(a2: PWorld): dReal
  # 
  #  This uses a "big matrix" method that takes time on the order of m^3
  #  and memory on the order of m^2, where m is the total number of constraint
  #  rows. For large systems this will use a lot of memory and can be very slow,
  #  but this is currently the most accurate method.
  #  @ingroup world
  #  @param stepsize The number of seconds that the simulation has to advance.
  # 
  proc Step*(a2: PWorld; stepsize: dReal)
  #*
  #  @brief Converts an impulse to a force.
  #  @ingroup world
  #  @remarks
  #  If you want to apply a linear or angular impulse to a rigid body,
  #  instead of a force or a torque, then you can use this function to convert
  #  the desired impulse into a force/torque vector before calling the
  #  BodyAdd... function.
  #  The current algorithm simply scales the impulse by 1/stepsize,
  #  where stepsize is the step size for the next step that will be taken.
  #  This function is given a PWorld because, in the future, the force
  #  computation may depend on integrator parameters that are set as
  #  properties of the world.
  # 
  proc ImpulseToForce*(a2: PWorld; stepsize: dReal; ix, iy, iz: dReal; 
                        force: TVector3d)
  #*
  #  @brief Step the world.
  #  @ingroup world
  #  @remarks
  #  This uses an iterative method that takes time on the order of m*N
  #  and memory on the order of m, where m is the total number of constraint
  #  rows N is the number of iterations.
  #  For large systems this is a lot faster than dWorldStep(),
  #  but it is less accurate.
  #  @remarks
  #  QuickStep is great for stacks of objects especially when the
  #  auto-disable feature is used as well.
  #  However, it has poor accuracy for near-singular systems.
  #  Near-singular systems can occur when using high-friction contacts, motors,
  #  or certain articulated structures. For example, a robot with multiple legs
  #  sitting on the ground may be near-singular.
  #  @remarks
  #  There are ways to help overcome QuickStep's inaccuracy problems:
  #  \li Increase CFM.
  #  \li Reduce the number of contacts in your system (e.g. use the minimum
  #      number of contacts for the feet of a robot or creature).
  #  \li Don't use excessive friction in the contacts.
  #  \li Use contact slip if appropriate
  #  \li Avoid kinematic loops (however, kinematic loops are inevitable in
  #      legged creatures).
  #  \li Don't use excessive motor strength.
  #  \liUse force-based motors instead of velocity-based motors.
  # 
  #  Increasing the number of QuickStep iterations may help a little bit, but
  #  it is not going to help much if your system is really near singular.
  # 
  proc QuickStep*(w: PWorld; stepsize: dReal)
#*
#  @brief Set the number of iterations that the QuickStep method performs per
#         step.
#  @ingroup world
#  @remarks
#  More iterations will give a more accurate solution, but will take
#  longer to compute.
#  @param num The default is 20 iterations.
# 
proc dWorldSetQuickStepNumIterations*(a2: PWorld; num: cint){.importc.}
#*
#  @brief Get the number of iterations that the QuickStep method performs per
#         step.
#  @ingroup world
#  @return nr of iterations
# 
proc dWorldGetQuickStepNumIterations*(a2: PWorld): cint{.importc.}
#*
#  @brief Set the SOR over-relaxation parameter
#  @ingroup world
#  @param over_relaxation value to use by SOR
# 
proc dWorldSetQuickStepW*(a2: PWorld; over_relaxation: dReal){.importc.}
#*
#  @brief Get the SOR over-relaxation parameter
#  @ingroup world
#  @returns the over-relaxation setting
# 
proc dWorldGetQuickStepW*(a2: PWorld): dReal{.importc.}
# World contact parameter functions 
#*
#  @brief Set the maximum correcting velocity that contacts are allowed
#  to generate.
#  @ingroup world
#  @param vel The default value is infinity (i.e. no limit).
#  @remarks
#  Reducing this value can help prevent "popping" of deeply embedded objects.
# 
proc dWorldSetContactMaxCorrectingVel*(a2: PWorld; vel: dReal){.importc.}
#*
#  @brief Get the maximum correcting velocity that contacts are allowed
#  to generated.
#  @ingroup world
# 
proc dWorldGetContactMaxCorrectingVel*(a2: PWorld): dReal{.importc.}
#*
#  @brief Set the depth of the surface layer around all geometry objects.
#  @ingroup world
#  @remarks
#  Contacts are allowed to sink into the surface layer up to the given
#  depth before coming to rest.
#  @param depth The default value is zero.
#  @remarks
#  Increasing this to some small value (e.g. 0.001) can help prevent
#  jittering problems due to contacts being repeatedly made and broken.
# 
proc dWorldSetContactSurfaceLayer*(a2: PWorld; depth: dReal){.importc.}
#*
#  @brief Get the depth of the surface layer around all geometry objects.
#  @ingroup world
#  @returns the depth
# 
proc dWorldGetContactSurfaceLayer*(a2: PWorld): dReal{.importc.}
# StepFast1 functions 
#*
#  @brief Step the world using the StepFast1 algorithm.
#  @param stepsize the nr of seconds to advance the simulation.
#  @param maxiterations The number of iterations to perform.
#  @ingroup world
# 
proc dWorldStepFast1*(a2: PWorld; stepsize: dReal; maxiterations: cint){.importc.}
#*
#  @defgroup disable Automatic Enabling and Disabling
#  @ingroup world bodies
# 
#  Every body can be enabled or disabled. Enabled bodies participate in the
#  simulation, while disabled bodies are turned off and do not get updated
#  during a simulation step. New bodies are always created in the enabled state.
# 
#  A disabled body that is connected through a joint to an enabled body will be
#  automatically re-enabled at the next simulation step.
# 
#  Disabled bodies do not consume CPU time, therefore to speed up the simulation
#  bodies should be disabled when they come to rest. This can be done automatically
#  with the auto-disable feature.
# 
#  If a body has its auto-disable flag turned on, it will automatically disable
#  itself when
#    @li It has been idle for a given number of simulation steps.
#    @li It has also been idle for a given amount of simulation time.
# 
#  A body is considered to be idle when the magnitudes of both its
#  linear average velocity and angular average velocity are below given thresholds.
#  The sample size for the average defaults to one and can be disabled by setting
#  to zero with 
# 
#  Thus, every body has six auto-disable parameters: an enabled flag, a idle step
#  count, an idle time, linear/angular average velocity thresholds, and the
#  average samples count.
# 
#  Newly created bodies get these parameters from world.
# 
#*
#  @brief Set the AutoEnableDepth parameter used by the StepFast1 algorithm.
#  @ingroup disable
# 
proc dWorldSetAutoEnableDepthSF1*(a2: PWorld; autoEnableDepth: cint){.importc.}
#*
#  @brief Get the AutoEnableDepth parameter used by the StepFast1 algorithm.
#  @ingroup disable
# 
proc dWorldGetAutoEnableDepthSF1*(a2: PWorld): cint{.importc.}
#*
#  @brief Get auto disable linear threshold for newly created bodies.
#  @ingroup disable
#  @return the threshold
# 
#proc  dWorldGetAutoDisableLinearThreshold*(a2: PWorld): dReal{.importc.}
#*
#  @brief Set auto disable linear threshold for newly created bodies.
#  @param linear_threshold default is 0.01
#  @ingroup disable
# 
proc dWorldSetAutoDisableLinearThreshold*(a2: PWorld; 
    linear_threshold: dReal){.importc.}
#*
#  @brief Get auto disable angular threshold for newly created bodies.
#  @ingroup disable
#  @return the threshold
# 
proc dWorldGetAutoDisableAngularThreshold*(a2: PWorld): dReal{.importc.}
#*
#  @brief Set auto disable angular threshold for newly created bodies.
#  @param linear_threshold default is 0.01
#  @ingroup disable
# 
proc dWorldSetAutoDisableAngularThreshold*(a2: PWorld; 
    angular_threshold: dReal){.importc.}
#*
#  @brief Get auto disable linear average threshold for newly created bodies.
#  @ingroup disable
#  @return the threshold
# 
##proc dWorldGetAutoDisableLinearAverageThreshold*(a2: PWorld): dReal{.importc.}
#*
#  @brief Set auto disable linear average threshold for newly created bodies.
#  @param linear_average_threshold default is 0.01
#  @ingroup disable
# 
#proc dWorldSetAutoDisableLinearAverageThreshold*(a2: PWorld; 

#KEEP
#    linear_average_threshold: dReal){.importc.}
#*
#  @brief Get auto disable angular average threshold for newly created bodies.
#  @ingroup disable
#  @return the threshold
# 
#proc dWorldGetAutoDisableAngularAverageThreshold*(a2: PWorld): dReal{.importc.}

#KEEP
#*
#  @brief Set auto disable angular average threshold for newly created bodies.
#  @param linear_average_threshold default is 0.01
#  @ingroup disable
#  
#proc dWorldSetAutoDisableAngularAverageThreshold*(a2: PWorld; 
#    angular_average_threshold: dReal){.importc.}
#*
#  @brief Get auto disable sample count for newly created bodies.
#  @ingroup disable
#  @return number of samples used
# 
proc dWorldGetAutoDisableAverageSamplesCount*(a2: PWorld): cint{.importc.}
#*
#  @brief Set auto disable average sample count for newly created bodies.
#  @ingroup disable
#  @param average_samples_count Default is 1, meaning only instantaneous velocity is used.
#  Set to zero to disable sampling and thus prevent any body from auto-disabling.
# 
proc dWorldSetAutoDisableAverageSamplesCount*(a2: PWorld; 
    average_samples_count: cuint){.importc.}
#*
#  @brief Get auto disable steps for newly created bodies.
#  @ingroup disable
#  @return nr of steps
# 
proc dWorldGetAutoDisableSteps*(a2: PWorld): cint{.importc.}
#*
#  @brief Set auto disable steps for newly created bodies.
#  @ingroup disable
#  @param steps default is 10
# 
proc dWorldSetAutoDisableSteps*(a2: PWorld; steps: cint){.importc.}
#*
#  @brief Get auto disable time for newly created bodies.
#  @ingroup disable
#  @return nr of seconds
# 
proc dWorldGetAutoDisableTime*(a2: PWorld): dReal{.importc.}
#*
#  @brief Set auto disable time for newly created bodies.
#  @ingroup disable
#  @param time default is 0 seconds
# 
proc dWorldSetAutoDisableTime*(a2: PWorld; time: dReal){.importc.}
#*
#  @brief Get auto disable flag for newly created bodies.
#  @ingroup disable
#  @return 0 or 1
# 
proc dWorldGetAutoDisableFlag*(a2: PWorld): cint{.importc.}
#*
#  @brief Set auto disable flag for newly created bodies.
#  @ingroup disable
#  @param do_auto_disable default is false.
# 
proc dWorldSetAutoDisableFlag*(a2: PWorld; do_auto_disable: cint){.importc.}
#*
#  @defgroup damping Damping
#  @ingroup bodies world
# 
#  Damping serves two purposes: reduce simulation instability, and to allow
#  the bodies to come to rest (and possibly auto-disabling them).
# 
#  Bodies are constructed using the world's current damping parameters. Setting
#  the scales to 0 disables the damping.
# 
#  Here is how it is done: after every time step linear and angular
#  velocities are tested against the corresponding thresholds. If they
#  are above, they are multiplied by (1 - scale). So a negative scale value
#  will actually increase the speed, and values greater than one will
#  make the object oscillate every step; both can make the simulation unstable.
# 
#  To disable damping just set the damping scale to zero.
# 
#  You can also limit the maximum angular velocity. In contrast to the damping
#  functions, the angular velocity is affected before the body is moved.
#  This means that it will introduce errors in joints that are forcing the body
#  to rotate too fast. Some bodies have naturally high angular velocities
#  (like cars' wheels), so you may want to give them a very high (like the default,
#  dInfinity) limit.
# 
#  @note The velocities are damped after the stepper function has moved the
#  object. Otherwise the damping could introduce errors in joints. First the
#  joint constraints are processed by the stepper (moving the body), then
#  the damping is applied.
# 
#  @note The damping happens right after the moved callback is called; this way 
#  it still possible use the exact velocities the body has acquired during the
#  step. You can even use the callback to create your own customized damping.
# 
#*
#  @brief Get the world's linear damping threshold.
#  @ingroup damping
# 
proc dWorldGetLinearDampingThreshold*(w: PWorld): dReal {.importc.}
#*
#  @brief Set the world's linear damping threshold.
#  @param threshold The damping won't be applied if the linear speed is
#         below this threshold. Default is 0.01.
#  @ingroup damping
# 
proc dWorldSetLinearDampingThreshold*(w: PWorld; threshold: dReal) {.importc.}
#*
#  @brief Get the world's angular damping threshold.
#  @ingroup damping
# 
proc dWorldGetAngularDampingThreshold*(w: PWorld): dReal {.importc.}
#*
#  @brief Set the world's angular damping threshold.
#  @param threshold The damping won't be applied if the angular speed is
#         below this threshold. Default is 0.01.
#  @ingroup damping
# 
proc dWorldSetAngularDampingThreshold*(w: PWorld; threshold: dReal) {.importc.}
#*
#  @brief Get the world's linear damping scale.
#  @ingroup damping
# 
proc dWorldGetLinearDamping*(w: PWorld): dReal {.importc.}
#*
#  @brief Set the world's linear damping scale.
#  @param scale The linear damping scale that is to be applied to bodies.
#  Default is 0 (no damping). Should be in the interval [0, 1].
#  @ingroup damping
# 
proc dWorldSetLinearDamping*(w: PWorld; scale: dReal) {.importc.}
#*
#  @brief Get the world's angular damping scale.
#  @ingroup damping
# 
proc dWorldGetAngularDamping*(w: PWorld): dReal {.importc.}
#*
#  @brief Set the world's angular damping scale.
#  @param scale The angular damping scale that is to be applied to bodies.
#  Default is 0 (no damping). Should be in the interval [0, 1].
#  @ingroup damping
# 
proc dWorldSetAngularDamping*(w: PWorld; scale: dReal) {.importc.}
#*
#  @brief Convenience function to set body linear and angular scales.
#  @param linear_scale The linear damping scale that is to be applied to bodies.
#  @param angular_scale The angular damping scale that is to be applied to bodies.
#  @ingroup damping
# 
proc dWorldSetDamping*(w: PWorld; linear_scale: dReal; angular_scale: dReal) {.importc.}
#*
#  @brief Get the default maximum angular speed.
#  @ingroup damping
#  @sa dBodyGetMaxAngularSpeed()
# 
proc dWorldGetMaxAngularSpeed*(w: PWorld): dReal {.importc.}
#*
#  @brief Set the default maximum angular speed for new bodies.
#  @ingroup damping
#  @sa dBodySetMaxAngularSpeed()
# 
proc dWorldSetMaxAngularSpeed*(w: PWorld; max_speed: dReal) {.importc.}
#*
#  @defgroup bodies Rigid Bodies
# 
#  A rigid body has various properties from the point of view of the
#  simulation. Some properties change over time:
# 
#   @li Position vector (x,y,z) of the body's point of reference.
#       Currently the point of reference must correspond to the body's center of mass.
#   @li Linear velocity of the point of reference, a vector (vx,vy,vz).
#   @li Orientation of a body, represented by a quaternion (qs,qx,qy,qz) or
#       a 3x3 rotation matrix.
#   @li Angular velocity vector (wx,wy,wz) which describes how the orientation
#       changes over time.
# 
#  Other body properties are usually constant over time:
# 
#   @li Mass of the body.
#   @li Position of the center of mass with respect to the point of reference.
#       In the current implementation the center of mass and the point of
#       reference must coincide.
#   @li Inertia matrix. This is a 3x3 matrix that describes how the body's mass
#       is distributed around the center of mass. Conceptually each body has an
#       x-y-z coordinate frame embedded in it that moves and rotates with the body.
# 
#  The origin of this coordinate frame is the body's point of reference. Some values
#  in ODE (vectors, matrices etc) are relative to the body coordinate frame, and others
#  are relative to the global coordinate frame.
# 
#  Note that the shape of a rigid body is not a dynamical property (except insofar as
#  it influences the various mass properties). It is only collision detection that cares
#  about the detailed shape of the body.
# 
#*
#  @brief Get auto disable linear average threshold.
#  @ingroup bodies disable
#  @return the threshold
# 
proc dBodyGetAutoDisableLinearThreshold*(body: PBody): dReal {.importc.}
#*
#  @brief Set auto disable linear average threshold.
#  @ingroup bodies disable
#  @return the threshold
# 
proc dBodySetAutoDisableLinearThreshold*(body: PBody; 
    linear_average_threshold: dReal) {.importc.}
#*
#  @brief Get auto disable angular average threshold.
#  @ingroup bodies disable
#  @return the threshold
# 
proc dBodyGetAutoDisableAngularThreshold*(body: PBody): dReal {.importc.}
#*
#  @brief Set auto disable angular average threshold.
#  @ingroup bodies disable
#  @return the threshold
# 
proc dBodySetAutoDisableAngularThreshold*(body: PBody; 
    angular_average_threshold: dReal) {.importc.}
#*
#  @brief Get auto disable average size (samples count).
#  @ingroup bodies disable
#  @return the nr of steps/size.
# 
proc dBodyGetAutoDisableAverageSamplesCount*(body: PBody): cint {.importc.}
#*
#  @brief Set auto disable average buffer size (average steps).
#  @ingroup bodies disable
#  @param average_samples_count the nr of samples to review.
# 
proc dBodySetAutoDisableAverageSamplesCount*(body: PBody; 
    average_samples_count: cuint) {.importc.}
#*
#  @brief Get auto steps a body must be thought of as idle to disable
#  @ingroup bodies disable
#  @return the nr of steps
# 
proc dBodyGetAutoDisableSteps*(body: PBody): cint {.importc.}
#*
#  @brief Set auto disable steps.
#  @ingroup bodies disable
#  @param steps the nr of steps.
# 
proc dBodySetAutoDisableSteps*(body: PBody; steps: cint) {.importc.}
#*
#  @brief Get auto disable time.
#  @ingroup bodies disable
#  @return nr of seconds
# 
proc dBodyGetAutoDisableTime*(body: PBody): dReal {.importc.}
#*
#  @brief Set auto disable time.
#  @ingroup bodies disable
#  @param time nr of seconds.
# 
proc dBodySetAutoDisableTime*(body: PBody; time: dReal) {.importc.}
#*
#  @brief Get auto disable flag.
#  @ingroup bodies disable
#  @return 0 or 1
# 
proc dBodyGetAutoDisableFlag*(body: PBody): cint {.importc.}
#*
#  @brief Set auto disable flag.
#  @ingroup bodies disable
#  @param do_auto_disable 0 or 1
# 
proc dBodySetAutoDisableFlag*(body: PBody; do_auto_disable: cint) {.importc.}
#*
#  @brief Set auto disable defaults.
#  @remarks
#  Set the values for the body to those set as default for the world.
#  @ingroup bodies disable
# 
proc dBodySetAutoDisableDefaults*(body: PBody){.importc.}
#*
#  @brief Retrieves the world attached to te given body.
#  @remarks
#  
#  @ingroup bodies
# 
proc dBodyGetWorld*(body: PBody): PWorld{.importc.} 
#*
#  @brief Create a body in given world.
#  @remarks
#  Default mass parameters are at position (0,0,0).
#  @ingroup bodies
# 
proc CreateBody*(world: PWorld): PBody {.importc: "dBodyCreate".}

importcizzle "dBody":
  proc Destroy*(body: PBody)
    ## All joints that are attached to this body will be put into limbo:
    ## i.e. unattached and not affecting the simulation, but they will NOT be
    ## deleted.
    
  proc SetData*(body: PBody; data: pointer)
    ##  Set the body's user-data pointer.
  
  proc GetData*(body: PBody): pointer
    ## Get the body's user-data pointer.
  
  proc SetPosition*(body: PBody; x, y, z: dReal)
    ## Set position of a body.
    ## @remarks
    ## After setting, the outcome of the simulation is undefined
    ## if the new configuration is inconsistent with the joints/constraints
    ## that are present.
  
  proc SetRotation*(body: PBody; R: TMatrix3)
    ## After setting, the outcome of the simulation is undefined
    ## if the new configuration is inconsistent with the joints/constraints
    ## that are present.
  proc SetQuaternion*(body: PBody; q: TQuaternion)
    ## Set the orientation of a body.
  proc SetLinearVel*(body: PBody; x, y, z: dReal)
    ## Set the linear velocity of a body.
  proc SetAngularVel*(body: PBody; x, y, z: dReal)
    ## Set the angular velocity of a body.
  proc GetPosition*(body: PBody): ptr TVector3d
    ## Get the position of a body.
    #  @ingroup bodies
    #  @remarks
    #  When getting, the returned values are pointers to internal data structures,
    #  so the vectors are valid until any changes are made to the rigid body
    #  system structure.
  proc CopyPosition*(body: PBody; pos: TVector3d)
    ## Copy the position of a body into a vector.
  proc GetRotation*(body: PBody): ptr TMatrix3 ## ptr dReal  ## TODO: verify this \
    ## Get the rotation of a body. \
    ## returns pointer to a 4x3 rotation matrix.
  proc CopyRotation*(body: PBody; R: TMatrix3)
    ## Copy the rotation of a body.
  proc GetQuaternion*(body: PBody): ptr dReal
    ## Get the rotation of a body.
    ##@return pointer to 4 scalars that represent the quaternion.
#*
#  @brief Copy the orientation of a body into a quaternion.
#  @ingroup bodies
#  @param body  the body to query
#  @param quat  a copy of the orientation quaternion
#  @sa dBodyGetQuaternion
# 
proc dBodyCopyQuaternion*(body: PBody; quat: TQuaternion){.importc.}
#*
#  @brief Get the linear velocity of a body.
#  @ingroup bodies
# 
proc dBodyGetLinearVel*(body: PBody): ptr dReal{.importc.}
#*
#  @brief Get the angular velocity of a body.
#  @ingroup bodies
# 
proc dBodyGetAngularVel*(body: PBody): ptr dReal{.importc.}


importcizzle "dBody":
  proc SetMass*(body: PBody; mass: PMass)
    ## Set the mass of a body.
  proc GetMass*(body: PBody; mass: var TMass)
    ## Get the mass of a body.
  proc AddForce*(body: PBody; fx, fy, fz: dReal)
    ## Add force at centre of mass of body in absolute coordinates.
    
  proc AddTorque*(body: PBody; fx, fy, fz: dReal)
    ## Add torque at centre of mass of body in absolute coordinates.
  proc AddRelForce*(body: PBody; fx, fy, fz: dReal)
    ## Add force at centre of mass of body in coordinates relative to body.
    
  proc AddRelTorque*(body: PBody; fx, fy, fz: dReal)
    ##Add torque at centre of mass of body in coordinates relative to body.
  proc AddForceAtPos*(body: PBody; fx, fy, fz: dReal; px, py, pz: dReal)
    ## Add force at specified point in body in global coordinates.
    
  proc AddForceAtRelPos*(body: PBody; fx, fy, fz: dReal; px, py, pz: dReal)
    ##Add force at specified point in body in local coordinates.
  proc AddRelForceAtPos*(body: PBody; fx, fy, fz: dReal; px, py, pz: dReal)
    ##Add force at specified point in body in global coordinates.
  proc AddRelForceAtRelPos*(body: PBody; fx, fy, fz: dReal; px, py, pz: dReal)
    ## Add force at specified point in body in local coordinates.
  
#  @brief Return the current accumulated force vector.
#  @return points to an array of 3 reals.
#  @remarks
#  The returned values are pointers to internal data structures, so
#  the vectors are only valid until any changes are made to the rigid
#  body system.
#  @ingroup bodies
# 
proc dBodyGetForce*(body: PBody): ptr dReal{.importc.}
#*
#  @brief Return the current accumulated torque vector.
#  @return points to an array of 3 reals.
#  @remarks
#  The returned values are pointers to internal data structures, so
#  the vectors are only valid until any changes are made to the rigid
#  body system.
#  @ingroup bodies
# 
proc dBodyGetTorque*(body: PBody): ptr dReal{.importc.}
#*
#  @brief Set the body force accumulation vector.
#  @remarks
#  This is mostly useful to zero the force and torque for deactivated bodies
#  before they are reactivated, in the case where the force-adding functions
#  were called on them while they were deactivated.
#  @ingroup bodies
# 
proc dBodySetForce*(body: PBody; x: dReal; y: dReal; z: dReal){.importc.}
#*
#  @brief Set the body torque accumulation vector.
#  @remarks
#  This is mostly useful to zero the force and torque for deactivated bodies
#  before they are reactivated, in the case where the force-adding functions
#  were called on them while they were deactivated.
#  @ingroup bodies
# 
proc dBodySetTorque*(body: PBody; x: dReal; y: dReal; z: dReal){.importc.}
#*
#  @brief Get world position of a relative point on body.
#  @ingroup bodies
#  @param result will contain the result.
# 
proc dBodyGetRelPointPos*(body: PBody; px, py, pz: dReal; 
                          result: TVector3d){.importc.}
#*
#  @brief Get velocity vector in global coords of a relative point on body.
#  @ingroup bodies
#  @param result will contain the result.
# 
proc dBodyGetRelPointVel*(body: PBody; px, py, pz: dReal; 
                          result: TVector3d){.importc.}
#*
#  @brief Get velocity vector in global coords of a globally
#  specified point on a body.
#  @ingroup bodies
#  @param result will contain the result.
# 
proc dBodyGetPointVel*(body: PBody; px, py, pz: dReal; 
                       result: TVector3d){.importc.}
#*
#  @brief takes a point in global coordinates and returns
#  the point's position in body-relative coordinates.
#  @remarks
#  This is the inverse of dBodyGetRelPointPos()
#  @ingroup bodies
#  @param result will contain the result.
# 
proc dBodyGetPosRelPoint*(body: PBody; px, py, pz: dReal; 
                          result: TVector3d){.importc.}
#*
#  @brief Convert from local to world coordinates.
#  @ingroup bodies
#  @param result will contain the result.
# 
proc dBodyVectorToWorld*(body: PBody; px, py, pz: dReal; 
                         result: TVector3d){.importc.}
#*
#  @brief Convert from world to local coordinates.
#  @ingroup bodies
#  @param result will contain the result.
# 
proc dBodyVectorFromWorld*(body: PBody; px, py, pz: dReal; 
                           result: TVector3d){.importc.}
#*
#  @brief controls the way a body's orientation is updated at each timestep.
#  @ingroup bodies
#  @param mode can be 0 or 1:
#  \li 0: An ``infinitesimal'' orientation update is used.
#  This is fast to compute, but it can occasionally cause inaccuracies
#  for bodies that are rotating at high speed, especially when those
#  bodies are joined to other bodies.
#  This is the default for every new body that is created.
#  \li 1: A ``finite'' orientation update is used.
#  This is more costly to compute, but will be more accurate for high
#  speed rotations.
#  @remarks
#  Note however that high speed rotations can result in many types of
#  error in a simulation, and the finite mode will only fix one of those
#  sources of error.
# 
proc dBodySetFiniteRotationMode*(body: PBody; mode: cint){.importc.}
#*
#  @brief sets the finite rotation axis for a body.
#  @ingroup bodies
#  @remarks
#  This is axis only has meaning when the finite rotation mode is set
#  If this axis is zero (0,0,0), full finite rotations are performed on
#  the body.
#  If this axis is nonzero, the body is rotated by performing a partial finite
#  rotation along the axis direction followed by an infinitesimal rotation
#  along an orthogonal direction.
#  @remarks
#  This can be useful to alleviate certain sources of error caused by quickly
#  spinning bodies. For example, if a car wheel is rotating at high speed
#  you can call this function with the wheel's hinge axis as the argument to
#  try and improve its behavior.
# 
proc dBodySetFiniteRotationAxis*(body: PBody; x: dReal; y: dReal; z: dReal){.importc.}
#*
#  @brief Get the way a body's orientation is updated each timestep.
#  @ingroup bodies
#  @return the mode 0 (infitesimal) or 1 (finite).
# 
proc dBodyGetFiniteRotationMode*(body: PBody): cint{.importc.}
#*
#  @brief Get the finite rotation axis.
#  @param result will contain the axis.
#  @ingroup bodies
# 
proc dBodyGetFiniteRotationAxis*(body: PBody; result: TVector3d){.importc.}
#*
#  @brief Get the number of joints that are attached to this body.
#  @ingroup bodies
#  @return nr of joints
# 
proc dBodyGetNumJoints*(body: PBody): cint{.importc.}
#*
#  @brief Return a joint attached to this body, given by index.
#  @ingroup bodies
#  @param index valid range is  0 to n-1 where n is the value returned by
#  dBodyGetNumJoints().
# 
proc dBodyGetJoint*(body: PBody; index: cint): PJoint{.importc.}
#*
#  @brief Set rigid body to dynamic state (default).
#  @param PBody identification of body.
#  @ingroup bodies
# 
proc dBodySetDynamic*(body: PBody){.importc.}
#*
#  @brief Set rigid body to kinematic state.
#  When in kinematic state the body isn't simulated as a dynamic
#  body (it's "unstoppable", doesn't respond to forces),
#  but can still affect dynamic bodies (e.g. in joints).
#  Kinematic bodies can be controlled by position and velocity.
#  @note A kinematic body has infinite mass. If you set its mass
#  to something else, it loses the kinematic state and behaves
#  as a normal dynamic body.
#  @param PBody identification of body.
#  @ingroup bodies
# 
proc dBodySetKinematic*(body: PBody){.importc.}
#*
#  @brief Check wether a body is in kinematic state.
#  @ingroup bodies
#  @return 1 if a body is kinematic or 0 if it is dynamic.
# 
proc dBodyIsKinematic*(body: PBody): cint{.importc.}
#*
#  @brief Manually enable a body.
#  @param PBody identification of body.
#  @ingroup bodies
# 
proc dBodyEnable*(body: PBody){.importc.}
#*
#  @brief Manually disable a body.
#  @ingroup bodies
#  @remarks
#  A disabled body that is connected through a joint to an enabled body will
#  be automatically re-enabled at the next simulation step.
# 
proc dBodyDisable*(body: PBody){.importc.}
#*
#  @brief Check wether a body is enabled.
#  @ingroup bodies
#  @return 1 if a body is currently enabled or 0 if it is disabled.
# 
proc dBodyIsEnabled*(body: PBody): cint{.importc.}
#*
#  @brief Set whether the body is influenced by the world's gravity or not.
#  @ingroup bodies
#  @param mode when nonzero gravity affects this body.
#  @remarks
#  Newly created bodies are always influenced by the world's gravity.
# 
proc dBodySetGravityMode*(body: PBody; mode: cint){.importc.}
#*
#  @brief Get whether the body is influenced by the world's gravity or not.
#  @ingroup bodies
#  @return nonzero means gravity affects this body.
# 
proc dBodyGetGravityMode*(body: PBody): cint{.importc.}
#*
#  @brief Set the 'moved' callback of a body.
# 
#  Whenever a body has its position or rotation changed during the
#  timestep, the callback will be called (with body as the argument).
#  Use it to know which body may need an update in an external
#  structure (like a 3D engine).
# 
#  @param b the body that needs to be watched.
#  @param callback the callback to be invoked when the body moves. Set to zero
#  to disable.
#  @ingroup bodies
# 
#ODE_API void dBodySetMovedCallback(PBody b, void (*callback)(PBody));
#*
#  @brief Return the first geom associated with the body.
#  
#  You can traverse through the geoms by repeatedly calling
#  dBodyGetNextGeom().
# 
#  @return the first geom attached to this body, or 0.
#  @ingroup bodies
# 
proc getFirstGeom*(body: PBody): PGeom{.importc: "dBodyGetFirstGeom".}
#*
#  @brief returns the next geom associated with the same body.
#  @param g a geom attached to some body.
#  @return the next geom attached to the same body, or 0.
#  @sa dBodyGetFirstGeom
#  @ingroup bodies
# 
proc dBodyGetNextGeom*(g: PGeom): PGeom{.importc.}
proc setDampingDefaults*(body: PBody){.importc: "dBodySetDampingDefaults".}
proc getLinearDamping*(body: PBody): dReal{.importc: "dBodyGetLinearDamping".}
#*
#  @brief Set the body's linear damping scale.
#  @param scale The linear damping scale. Should be in the interval [0, 1].
#  @ingroup bodies damping
#  @remarks From now on the body will not use the world's linear damping
#  scale until dBodySetDampingDefaults() is called.
#  @sa dBodySetDampingDefaults()
# 
proc setLinearDamping*(body: PBody; scale: dReal){.importc: "dBodySetLinearDamping".}
#*
#  @brief Get the body's angular damping scale.
#  @ingroup bodies damping
#  @remarks If the body's angular damping scale was not set, this function
#  returns the world's angular damping scale.
# 
proc getAngularDamping*(body: PBody): dReal{.importc: "dBodyGetAngularDamping".}
#*
#  @brief Set the body's angular damping scale.
#  @param scale The angular damping scale. Should be in the interval [0, 1].
#  @ingroup bodies damping
#  @remarks From now on the body will not use the world's angular damping
#  scale until dBodyResetAngularDamping() is called.
#  @sa dBodyResetAngularDamping()
# 
proc getAngularDamping*(body: PBody; scale: dReal){.importc: "dBodyGetAngularDamping".}
#*
#  @brief Convenience function to set linear and angular scales at once.
#  @param linear_scale The linear damping scale. Should be in the interval [0, 1].
#  @param angular_scale The angular damping scale. Should be in the interval [0, 1].
#  @ingroup bodies damping
#  @sa dBodySetLinearDamping() dBodySetAngularDamping()
# 
proc setDamping*(body: PBody; linear_scale: dReal; angular_scale: dReal){.importc: "dBodySetDamping".}

proc getLinearDampingThreshold*(body: PBody): dReal{.
  importc: "dBodyGetLinearDampingThreshold".}
#*
#  @brief Set the body's linear damping threshold.
#  @param threshold The linear threshold to be used. Damping
#       is only applied if the linear speed is above this limit.
#  @ingroup bodies damping
# 
proc setLinearDampingThreshold*(body: PBody; threshold: dReal){.
  importc: "dBodySetLinearDampingThreshold".}
proc getAngularDampingThreshold*(body: PBody): dReal{.
  importc: "dBodyGetAngularDampingThreshold".}
#*
#  @brief Set the body's angular damping threshold.
#  @param threshold The angular threshold to be used. Damping is
#       only used if the angular speed is above this limit.
#  @ingroup bodies damping
# 
proc getAngularDampingThreshold*(body: PBody; threshold: dReal){.
  importc: "dBodyGetAngularDampingThreshold".}
proc getMaxAngularSpeed*(body: PBody): dReal{.
  importc: "dBodyGetMaxAngularSpeed".}
#*
#  @brief Set the body's maximum angular speed.
#  @ingroup damping bodies
#  @sa dWorldSetMaxAngularSpeed() dBodyResetMaxAngularSpeed()
#  The default value is dInfinity, but it's a good idea to limit
#  it at less than 500 if the body has the gyroscopic term
#  enabled.
# 
proc dBodySetMaxAngularSpeed*(body: PBody; max_speed: dReal){.importc.}
#*
#  @brief Get the body's gyroscopic state.
# 
#  @return nonzero if gyroscopic term computation is enabled (default),
#  zero otherwise.
#  @ingroup bodies
# 
proc dBodyGetGyroscopicMode*(body: PBody): cint{.importc.}
#*
#  @brief Enable/disable the body's gyroscopic term.
# 
#  Disabling the gyroscopic term of a body usually improves
#  stability. It also helps turning spining objects, like cars'
#  wheels.
# 
#  @param enabled   nonzero (default) to enable gyroscopic term, 0
#  to disable.
#  @ingroup bodies
# 
proc dBodySetGyroscopicMode*(body: PBody; enabled: cint){.importc.}
#*
#  @defgroup joints Joints
# 
#  In real life a joint is something like a hinge, that is used to connect two
#  objects.
#  In ODE a joint is very similar: It is a relationship that is enforced between
#  two bodies so that they can only have certain positions and orientations
#  relative to each other.
#  This relationship is called a constraint -- the words joint and
#  constraint are often used interchangeably.
# 
#  A joint has a set of parameters that can be set. These include:
# 
# 
#  \li  dParamLoStop Low stop angle or position. Setting this to
# 	-dInfinity (the default value) turns off the low stop.
# 	For rotational joints, this stop must be greater than -pi to be
# 	effective.
#  \li  dParamHiStop High stop angle or position. Setting this to
# 	dInfinity (the default value) turns off the high stop.
# 	For rotational joints, this stop must be less than pi to be
# 	effective.
# 	If the high stop is less than the low stop then both stops will
# 	be ineffective.
#  \li  dParamVel Desired motor velocity (this will be an angular or
# 	linear velocity).
#  \li  dParamFMax The maximum force or torque that the motor will use to
# 	achieve the desired velocity.
# 	This must always be greater than or equal to zero.
# 	Setting this to zero (the default value) turns off the motor.
#  \li  dParamFudgeFactor The current joint stop/motor implementation has
# 	a small problem:
# 	when the joint is at one stop and the motor is set to move it away
# 	from the stop, too much force may be applied for one time step,
# 	causing a ``jumping'' motion.
# 	This fudge factor is used to scale this excess force.
# 	It should have a value between zero and one (the default value).
# 	If the jumping motion is too visible in a joint, the value can be
# 	reduced.
# 	Making this value too small can prevent the motor from being able to
# 	move the joint away from a stop.
#  \li  dParamBounce The bouncyness of the stops.
# 	This is a restitution parameter in the range 0..1.
# 	0 means the stops are not bouncy at all, 1 means maximum bouncyness.
#  \li  dParamCFM The constraint force mixing (CFM) value used when not
# 	at a stop.
#  \li  dParamStopERP The error reduction parameter (ERP) used by the
# 	stops.
#  \li  dParamStopCFM The constraint force mixing (CFM) value used by the
# 	stops. Together with the ERP value this can be used to get spongy or
# 	soft stops.
# 	Note that this is intended for unpowered joints, it does not really
# 	work as expected when a powered joint reaches its limit.
#  \li  dParamSuspensionERP Suspension error reduction parameter (ERP).
# 	Currently this is only implemented on the hinge-2 joint.
#  \li  dParamSuspensionCFM Suspension constraint force mixing (CFM) value.
# 	Currently this is only implemented on the hinge-2 joint.
# 
#  If a particular parameter is not implemented by a given joint, setting it
#  will have no effect.
#  These parameter names can be optionally followed by a digit (2 or 3)
#  to indicate the second or third set of parameters, e.g. for the second axis
#  in a hinge-2 joint, or the third axis in an AMotor joint.
# 
#*
#  @brief Create a new joint of the ball type.
#  @ingroup joints
#  @remarks
#  The joint is initially in "limbo" (i.e. it has no effect on the simulation)
#  because it does not connect to any bodies.
#  @param PJointGroup set to 0 to allocate the joint normally.
#  If it is nonzero the joint is allocated in the given joint group.
# 
proc dJointCreateBall*(a2: PWorld; a3: PJointGroup): PJoint{.importc.}
#*
#  @brief Create a new joint of the hinge type.
#  @ingroup joints
#  @param PJointGroup set to 0 to allocate the joint normally.
#  If it is nonzero the joint is allocated in the given joint group.
# 
proc dJointCreateHinge*(a2: PWorld; a3: PJointGroup): PJoint{.importc.}
#*
#  @brief Create a new joint of the slider type.
#  @ingroup joints
#  @param PJointGroup set to 0 to allocate the joint normally.
#  If it is nonzero the joint is allocated in the given joint group.
# 
proc dJointCreateSlider*(a2: PWorld; a3: PJointGroup): PJoint{.importc.}
#*
#  @brief Create a new joint of the contact type.
#  @ingroup joints
#  @param PJointGroup set to 0 to allocate the joint normally.
#  If it is nonzero the joint is allocated in the given joint group.
# 
proc dJointCreateContact*(a2: PWorld; a3: PJointGroup; a4: ptr dContact): PJoint{.importc.}
#*
#  @brief Create a new joint of the hinge2 type.
#  @ingroup joints
#  @param PJointGroup set to 0 to allocate the joint normally.
#  If it is nonzero the joint is allocated in the given joint group.
# 
proc dJointCreateHinge2*(a2: PWorld; a3: PJointGroup): PJoint{.importc.}
#*
#  @brief Create a new joint of the universal type.
#  @ingroup joints
#  @param PJointGroup set to 0 to allocate the joint normally.
#  If it is nonzero the joint is allocated in the given joint group.
# 
proc dJointCreateUniversal*(a2: PWorld; a3: PJointGroup): PJoint{.importc.}
#*
#  @brief Create a new joint of the PR (Prismatic and Rotoide) type.
#  @ingroup joints
#  @param PJointGroup set to 0 to allocate the joint normally.
#  If it is nonzero the joint is allocated in the given joint group.
# 
proc dJointCreatePR*(a2: PWorld; a3: PJointGroup): PJoint{.importc.}
#*
#    @brief Create a new joint of the PU (Prismatic and Universal) type.
#    @ingroup joints
#    @param PJointGroup set to 0 to allocate the joint normally.
#    If it is nonzero the joint is allocated in the given joint group.
#   
proc dJointCreatePU*(a2: PWorld; a3: PJointGroup): PJoint{.importc.}
#*
#    @brief Create a new joint of the Piston type.
#    @ingroup joints
#    @param PJointGroup set to 0 to allocate the joint normally.
#                         If it is nonzero the joint is allocated in the given
#                         joint group.
#   
proc dJointCreatePiston*(a2: PWorld; a3: PJointGroup): PJoint{.importc.}
#*
#  @brief Create a new joint of the fixed type.
#  @ingroup joints
#  @param PJointGroup set to 0 to allocate the joint normally.
#  If it is nonzero the joint is allocated in the given joint group.
# 
proc dJointCreateFixed*(a2: PWorld; a3: PJointGroup): PJoint{.importc.}
proc dJointCreateNull*(a2: PWorld; a3: PJointGroup): PJoint{.importc.}
#*
#  @brief Create a new joint of the A-motor type.
#  @ingroup joints
#  @param PJointGroup set to 0 to allocate the joint normally.
#  If it is nonzero the joint is allocated in the given joint group.
# 
proc dJointCreateAMotor*(a2: PWorld; a3: PJointGroup): PJoint{.importc.}
#*
#  @brief Create a new joint of the L-motor type.
#  @ingroup joints
#  @param PJointGroup set to 0 to allocate the joint normally.
#  If it is nonzero the joint is allocated in the given joint group.
# 
proc dJointCreateLMotor*(a2: PWorld; a3: PJointGroup): PJoint{.importc.}

importcizzle "dJoint":
  proc CreatePlane2D*(world: PWorld, group: PJointGroup = nil): PJoint 
    ## Creates a new joint of the plane-2d type.
  proc Destroy*(joint: PJoint)
    ## Destroy a joint.
    ##  @ingroup joints
    ## 
    ##  disconnects it from its attached bodies and removing it from the world.
    ##  However, if the joint is a member of a group then this function has no
    ##  effect - to destroy that joint the group must be emptied or destroyed.
  
  proc GetNumBodies*(joint: PJoint): cint
    ## Return the number of bodies attached to the joint
  
  proc Attach*(joint: PJoint; body1: PBody; body2: PBody = nil)
    ## If the joint is already attached, it will be detached from the old bodies
    ##  first.
    ##  To attach this joint to only one body, set body1 or body2 to zero - a zero
    ##  body refers to the static environment.
    ##  Setting both bodies to zero puts the joint into "limbo", i.e. it will
    ##  have no effect on the simulation.
    ##  @remarks
    ##  Some joints, like hinge-2 need to be attached to two bodies to work.
    
  proc Enable*(joint: PJoint)
    ## Manually enable a joint.

importcizzle "dJointGroup":
  proc Destroy*(a2: PJointGroup)
    ## Destroy a joint group.
    #  @ingroup joints
    # 
    #  All joints in the joint group will be destroyed.
  # 
  # 
  proc Empty*(a2: PJointGroup)
  ## Empty a joint group.
  ## 
  ## All joints in the joint group will be destroyed,
  ## but the joint group itself will not be destroyed.
#*
#  @brief Create a joint group
#  @ingroup joints
#  @param max_size deprecated. Set to 0.
# {.importc.}
proc CreateJointGroup*(max_size: cint = 0): PJointGroup{.importc: "dJointGroupCreate".}
#*
#  @brief 
# 

#*
#  @brief Manually disable a joint.
#  @ingroup joints
#  @remarks
#  A disabled joint will not affect the simulation, but will maintain the anchors and
#  axes so it can be enabled later.
# 
proc dJointDisable*(a2: PJoint){.importc.}
#*
#  @brief Check wether a joint is enabled.
#  @ingroup joints
#  @return 1 if a joint is currently enabled or 0 if it is disabled.
# 
proc dJointIsEnabled*(a2: PJoint): cint{.importc.}
#*
#  @brief Set the user-data pointer
#  @ingroup joints
# 
proc dJointSetData*(a2: PJoint; data: pointer){.importc.}
#*
#  @brief Get the user-data pointer
#  @ingroup joints
# 
proc dJointGetData*(a2: PJoint): pointer{.importc.}
#*
#  @brief Get the type of the joint
#  @ingroup joints
#  @return the type, being one of these:
#  \li TJointTypeBall
#  \li TJointTypeHinge
#  \li TJointTypeSlider
#  \li TJointTypeContact
#  \li TJointTypeUniversal
#  \li TJointTypeHinge2
#  \li TJointTypeFixed
#  \li TJointTypeNull
#  \li TJointTypeAMotor
#  \li TJointTypeLMotor
#  \li TJointTypePlane2D
#  \li TJointTypePR
#  \li TJointTypePU
#  \li TJointTypePiston
# 
proc dJointGetType*(a2: PJoint): TJointType{.importc.}
#*
#  @brief Return the bodies that this joint connects.
#  @ingroup joints
#  @param index return the first (0) or second (1) body.
#  @remarks
#  If one of these returned body IDs is zero, the joint connects the other body
#  to the static environment.
#  If both body IDs are zero, the joint is in ``limbo'' and has no effect on
#  the simulation.
# 
proc dJointGetBody*(a2: PJoint; index: cint): PBody{.importc.}
#*
#  @brief Sets the datastructure that is to receive the feedback.
# 
#  The feedback can be used by the user, so that it is known how
#  much force an individual joint exerts.
#  @ingroup joints
# 
proc dJointSetFeedback*(a2: PJoint; a3: ptr TJointFeedback){.importc.}
#*
#  @brief Gets the datastructure that is to receive the feedback.
#  @ingroup joints
# 
proc dJointGetFeedback*(a2: PJoint): ptr TJointFeedback{.importc.}
#*
#  @brief Set the joint anchor point.
#  @ingroup joints
# 
#  The joint will try to keep this point on each body
#  together. The input is specified in world coordinates.
# 
proc dJointSetBallAnchor*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
proc dJointSetBallAnchor2*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
proc dJointSetBallParam*(a2: PJoint; parameter: cint; value: dReal){.importc.}
proc dJointSetHingeAnchor*(a2: PJoint; x: dReal; y: dReal; z: dReal) {.importc.}
proc dJointSetHingeAnchorDelta*(a2: PJoint; x: dReal; y: dReal; z: dReal; 
                                ax: dReal; ay: dReal; az: dReal){.importc.}
proc dJointSetHingeAxis*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#  @brief Set the Hinge axis as if the 2 bodies were already at angle appart.
#  @ingroup joints
# 
#  This function initialize the Axis and the relative orientation of each body
#  as if body1 was rotated around the axis by the angle value. \br
#  Ex:
#  <PRE>
#  dJointSetHingeAxis(jId, 1, 0, 0);
#  // If you request the position you will have: dJointGetHingeAngle(jId) == 0
#  dJointSetHingeAxisDelta(jId, 1, 0, 0, 0.23);
#  // If you request the position you will have: dJointGetHingeAngle(jId) == 0.23
#  </PRE>
#
#  @param j The Hinge joint ID for which the axis will be set
#  @param x The X component of the axis in world frame
#  @param y The Y component of the axis in world frame
#  @param z The Z component of the axis in world frame
#  @param angle The angle for the offset of the relative orientation.
#               As if body1 was rotated by angle when the Axis was set (see below).
#               The rotation is around the new Hinge axis.
# 
#  @note Usually the function dJointSetHingeAxis set the current position of body1
#        and body2 as the zero angle position. This function set the current position
#        as the if the 2 bodies where \b angle appart.
#  @warning Calling dJointSetHingeAnchor or dJointSetHingeAxis will reset the "zero"
#           angle position.
# 
proc setHingeAxisOffset*(j: PJoint; x, y, z: dReal; angle: dReal){.
  importc: "dJointSetHingeAxisOffset".}
#*
#  @brief set joint parameter
#  @ingroup joints
# 
proc setHingeParam*(a2: PJoint; parameter: cint; value: dReal){.
  importc: "dJointSetHingeParam".}
#*
#  @brief Applies the torque about the hinge axis.
# 
#  That is, it applies a torque with specified magnitude in the direction
#  of the hinge axis, to body 1, and with the same magnitude but in opposite
#  direction to body 2. This function is just a wrapper for dBodyAddTorque()}
#  @ingroup joints
# 
proc addHingeTorque*(joint: PJoint; torque: dReal){.
  importc: "dJointAddHingeTorque".}
proc setSliderAxis*(a2: PJoint; x, y, z: dReal){.
  importc: "dJointSetSliderAxis".}
proc setSliderAxisDelta*(a2: PJoint; x, y, z, ax, ay, az: dReal){.
  importc: "dJointSetSliderAxisDelta".}
#*
#  @brief set joint parameter
#  @ingroup joints
# 
proc setSliderParam*(a2: PJoint; parameter: cint; value: dReal){.
  importc: "dJointSetSliderParam".}
#*
#  @brief Applies the given force in the slider's direction.
# 
#  That is, it applies a force with specified magnitude, in the direction of
#  slider's axis, to body1, and with the same magnitude but opposite
#  direction to body2.  This function is just a wrapper for dBodyAddForce().
#  @ingroup joints
# 
proc addSliderForce*(joint: PJoint; force: dReal){.
  importc: "dJointAddSliderForce".}
#*
#  @brief set anchor
#  @ingroup joints
# 
proc dJointSetHinge2Anchor*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#  @brief set axis
#  @ingroup joints
# 
proc dJointSetHinge2Axis1*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#  @brief set axis
#  @ingroup joints
# 
proc dJointSetHinge2Axis2*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#  @brief set joint parameter
#  @ingroup joints
# 
proc dJointSetHinge2Param*(a2: PJoint; parameter: cint; value: dReal){.importc.}
#*
#  @brief Applies torque1 about the hinge2's axis 1, torque2 about the
#  hinge2's axis 2.
#  @remarks  This function is just a wrapper for dBodyAddTorque().
#  @ingroup joints
# 
proc dJointAddHinge2Torques*(joint: PJoint; torque1: dReal; torque2: dReal){.importc.}
#*
#  @brief set anchor
#  @ingroup joints
# 
proc dJointSetUniversalAnchor*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#  @brief set axis
#  @ingroup joints
# 
proc dJointSetUniversalAxis1*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#  @brief Set the Universal axis1 as if the 2 bodies were already at 
#         offset1 and offset2 appart with respect to axis1 and axis2.
#  @ingroup joints
# 
#  This function initialize the axis1 and the relative orientation of 
#  each body as if body1 was rotated around the new axis1 by the offset1 
#  value and as if body2 was rotated around the axis2 by offset2. \br
#  Ex:
# <PRE>
#  dJointSetHuniversalAxis1(jId, 1, 0, 0);
#  // If you request the position you will have: dJointGetUniversalAngle1(jId) == 0
#  // If you request the position you will have: dJointGetUniversalAngle2(jId) == 0
#  dJointSetHuniversalAxis1Offset(jId, 1, 0, 0, 0.2, 0.17);
#  // If you request the position you will have: dJointGetUniversalAngle1(jId) == 0.2
#  // If you request the position you will have: dJointGetUniversalAngle2(jId) == 0.17
#  </PRE>
# 
#  @param j The Hinge joint ID for which the axis will be set
#  @param x The X component of the axis in world frame
#  @param y The Y component of the axis in world frame
#  @param z The Z component of the axis in world frame
#  @param angle The angle for the offset of the relative orientation.
#               As if body1 was rotated by angle when the Axis was set (see below).
#               The rotation is around the new Hinge axis.
# 
#  @note Usually the function dJointSetHingeAxis set the current position of body1
#        and body2 as the zero angle position. This function set the current position
#        as the if the 2 bodies where \b offsets appart.
# 
#  @note Any previous offsets are erased.
# 
#  @warning Calling dJointSetUniversalAnchor, dJointSetUnivesalAxis1, 
#           dJointSetUniversalAxis2, dJointSetUniversalAxis2Offset 
#           will reset the "zero" angle position.
# 
proc dJointSetUniversalAxis1Offset*(a2: PJoint; x: dReal; y: dReal; 
                                    z: dReal; offset1: dReal; offset2: dReal){.importc.}
#*
#  @brief set axis
#  @ingroup joints
# 
proc dJointSetUniversalAxis2*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#  @brief Set the Universal axis2 as if the 2 bodies were already at 
#         offset1 and offset2 appart with respect to axis1 and axis2.
#  @ingroup joints
# 
#  This function initialize the axis2 and the relative orientation of 
#  each body as if body1 was rotated around the axis1 by the offset1 
#  value and as if body2 was rotated around the new axis2 by offset2. \br
#  Ex:
#  <PRE>
#  dJointSetHuniversalAxis2(jId, 0, 1, 0);
#  // If you request the position you will have: dJointGetUniversalAngle1(jId) == 0
#  // If you request the position you will have: dJointGetUniversalAngle2(jId) == 0
#  dJointSetHuniversalAxis2Offset(jId, 0, 1, 0, 0.2, 0.17);
#  // If you request the position you will have: dJointGetUniversalAngle1(jId) == 0.2
#  // If you request the position you will have: dJointGetUniversalAngle2(jId) == 0.17
#  </PRE>
#
#  @param j The Hinge joint ID for which the axis will be set
#  @param x The X component of the axis in world frame
#  @param y The Y component of the axis in world frame
#  @param z The Z component of the axis in world frame
#  @param angle The angle for the offset of the relative orientation.
#               As if body1 was rotated by angle when the Axis was set (see below).
#               The rotation is around the new Hinge axis.
# 
#  @note Usually the function dJointSetHingeAxis set the current position of body1
#        and body2 as the zero angle position. This function set the current position
#        as the if the 2 bodies where \b offsets appart.
# 
#  @note Any previous offsets are erased.
# 
#  @warning Calling dJointSetUniversalAnchor, dJointSetUnivesalAxis1, 
#           dJointSetUniversalAxis2, dJointSetUniversalAxis2Offset 
#           will reset the "zero" angle position.
# 
proc dJointSetUniversalAxis2Offset*(a2: PJoint; x: dReal; y: dReal; 
                                    z: dReal; offset1: dReal; offset2: dReal){.importc.}
#*
#  @brief set joint parameter
#  @ingroup joints
# 
proc dJointSetUniversalParam*(a2: PJoint; parameter: cint; value: dReal){.importc.}
#*
#  @brief Applies torque1 about the universal's axis 1, torque2 about the
#  universal's axis 2.
#  @remarks This function is just a wrapper for dBodyAddTorque().
#  @ingroup joints
# 
proc dJointAddUniversalTorques*(joint: PJoint; torque1: dReal; 
                                torque2: dReal){.importc.}
#*
#  @brief set anchor
#  @ingroup joints
# 
proc dJointSetPRAnchor*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#  @brief set the axis for the prismatic articulation
#  @ingroup joints
# 
proc dJointSetPRAxis1*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#  @brief set the axis for the rotoide articulation
#  @ingroup joints
# 
proc dJointSetPRAxis2*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#  @brief set joint parameter
#  @ingroup joints
# 
#  @note parameterX where X equal 2 refer to parameter for the rotoide articulation
# 
proc dJointSetPRParam*(a2: PJoint; parameter: cint; value: dReal){.importc.}
#*
#  @brief Applies the torque about the rotoide axis of the PR joint
# 
#  That is, it applies a torque with specified magnitude in the direction 
#  of the rotoide axis, to body 1, and with the same magnitude but in opposite
#  direction to body 2. This function is just a wrapper for dBodyAddTorque()}
#  @ingroup joints
# 
proc dJointAddPRTorque*(j: PJoint; torque: dReal){.importc.}
#*
#   @brief set anchor
#   @ingroup joints
#  
proc dJointSetPUAnchor*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#    @brief set anchor
#    @ingroup joints
#   
proc dJointSetPUAnchorDelta*(a2: PJoint; x: dReal; y: dReal; z: dReal; 
                             dx: dReal; dy: dReal; dz: dReal){.importc.}
#*
#    @brief Set the PU anchor as if the 2 bodies were already at [dx, dy, dz] appart.
#    @ingroup joints
#   
#    This function initialize the anchor and the relative position of each body
#    as if the position between body1 and body2 was already the projection of [dx, dy, dz]
#    along the Piston axis. (i.e as if the body1 was at its current position - [dx,dy,dy] when the
#    axis is set).
#    Ex:
#    <PRE>
#    dReal offset = 3;
#    TVector3d axis;
#    dJointGetPUAxis(jId, axis);
#    dJointSetPUAnchor(jId, 0, 0, 0);
#    // If you request the position you will have: dJointGetPUPosition(jId) == 0
#    dJointSetPUAnchorOffset(jId, 0, 0, 0, axis[X]*offset, axis[Y]*offset, axis[Z]*offset);
#    // If you request the position you will have: dJointGetPUPosition(jId) == offset
#    </PRE>
#    @param j The PU joint for which the anchor point will be set
#    @param x The X position of the anchor point in world frame
#    @param y The Y position of the anchor point in world frame
#    @param z The Z position of the anchor point in world frame
#    @param dx A delta to be substracted to the X position as if the anchor was set
#              when body1 was at current_position[X] - dx
#    @param dx A delta to be substracted to the Y position as if the anchor was set
#              when body1 was at current_position[Y] - dy
#    @param dx A delta to be substracted to the Z position as if the anchor was set
#              when body1 was at current_position[Z] - dz
#   
proc dJointSetPUAnchorOffset*(a2: PJoint; x: dReal; y: dReal; z: dReal; 
                              dx: dReal; dy: dReal; dz: dReal){.importc.}
#*
#    @brief set the axis for the first axis or the universal articulation
#    @ingroup joints
#   
proc dJointSetPUAxis1*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#    @brief set the axis for the second axis or the universal articulation
#    @ingroup joints
#   
proc dJointSetPUAxis2*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
proc dJointSetPUAxis3*(a2: PJoint; x, y, z: dReal){.importc.}
#*
#    @brief set the axis for the prismatic articulation
#    @ingroup joints
#    @note This function was added for convenience it is the same as
#          dJointSetPUAxis3
#   
proc dJointSetPUAxisP*(id: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#    @brief set joint parameter
#    @ingroup joints
#   
#    @note parameterX where X equal 2 refer to parameter for second axis of the
#          universal articulation
#    @note parameterX where X equal 3 refer to parameter for prismatic
#          articulation
#   
proc dJointSetPUParam*(a2: PJoint; parameter: cint; value: dReal){.importc.}
#*
#    @brief Applies the torque about the rotoide axis of the PU joint
#   
#    That is, it applies a torque with specified magnitude in the direction
#    of the rotoide axis, to body 1, and with the same magnitude but in opposite
#    direction to body 2. This function is just a wrapper for dBodyAddTorque()}
#    @ingroup joints
# 
##im missing this one ._>  
##proc dJointAddPUTorque*(j: PJoint; torque: dReal){.importc.}
#*
#    @brief set the joint anchor
#    @ingroup joints
#   
proc dJointSetPistonAnchor*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#    @brief Set the Piston anchor as if the 2 bodies were already at [dx,dy, dz] appart.
#    @ingroup joints
#   
#    This function initialize the anchor and the relative position of each body
#    as if the position between body1 and body2 was already the projection of [dx, dy, dz]
#    along the Piston axis. (i.e as if the body1 was at its current position - [dx,dy,dy] when the
#    axis is set).
#    Ex:
#    <PRE>
#    dReal offset = 3;
#    TVector3d axis;
#    dJointGetPistonAxis(jId, axis);
#    dJointSetPistonAnchor(jId, 0, 0, 0);
#    // If you request the position you will have: dJointGetPistonPosition(jId) == 0
#    dJointSetPistonAnchorOffset(jId, 0, 0, 0, axis[X]*offset, axis[Y]*offset, axis[Z]*offset);
#    // If you request the position you will have: dJointGetPistonPosition(jId) == offset
#    </PRE>
#    @param j The Piston joint for which the anchor point will be set
#    @param x The X position of the anchor point in world frame
#    @param y The Y position of the anchor point in world frame
#    @param z The Z position of the anchor point in world frame
#    @param dx A delta to be substracted to the X position as if the anchor was set
#              when body1 was at current_position[X] - dx
#    @param dx A delta to be substracted to the Y position as if the anchor was set
#              when body1 was at current_position[Y] - dy
#    @param dx A delta to be substracted to the Z position as if the anchor was set
#              when body1 was at current_position[Z] - dz
#   
proc dJointSetPistonAnchorOffset*(j: PJoint; x: dReal; y: dReal; z: dReal; 
                                  dx: dReal; dy: dReal; dz: dReal){.importc.}
#*
#      @brief set the joint axis
#    @ingroup joints
#   
proc dJointSetPistonAxis*(a2: PJoint; x: dReal; y: dReal; z: dReal){.importc.}
#*
#    This function set prismatic axis of the joint and also set the position
#    of the joint.
#   
#    @ingroup joints
#    @param j The joint affected by this function
#    @param x The x component of the axis
#    @param y The y component of the axis
#    @param z The z component of the axis
#    @param dx The Initial position of the prismatic join in the x direction
#    @param dy The Initial position of the prismatic join in the y direction
#    @param dz The Initial position of the prismatic join in the z direction
#   
proc dJointSetPistonAxisDelta*(j: PJoint; x: dReal; y: dReal; z: dReal; 
                               ax: dReal; ay: dReal; az: dReal){.importc.}
#*
#    @brief set joint parameter
#    @ingroup joints
#   
proc dJointSetPistonParam*(a2: PJoint; parameter: cint; value: dReal){.importc.}
#*
#    @brief Applies the given force in the slider's direction.
#   
#    That is, it applies a force with specified magnitude, in the direction of
#    prismatic's axis, to body1, and with the same magnitude but opposite
#    direction to body2.  This function is just a wrapper for dBodyAddForce().
#    @ingroup joints
#   
proc dJointAddPistonForce*(joint: PJoint; force: dReal){.importc.}
#*
#  @brief Call this on the fixed joint after it has been attached to
#  remember the current desired relative offset and desired relative
#  rotation between the bodies.
#  @ingroup joints
# 
proc dJointSetFixed*(a2: PJoint){.importc.}
#
#  @brief Sets joint parameter
# 
#  @ingroup joints
# 
proc dJointSetFixedParam*(a2: PJoint; parameter: cint; value: dReal){.importc.}
#*
#  @brief set the nr of axes
#  @param num 0..3
#  @ingroup joints
# 
proc dJointSetAMotorNumAxes*(a2: PJoint; num: cint){.importc.}
#*
#  @brief set axis
#  @ingroup joints
# 
proc dJointSetAMotorAxis*(a2: PJoint; anum: cint; rel: cint; x: dReal; 
                          y: dReal; z: dReal){.importc.}
#*
#  @brief Tell the AMotor what the current angle is along axis anum.
# 
#  This function should only be called in dAMotorUser mode, because in this
#  mode the AMotor has no other way of knowing the joint angles.
#  The angle information is needed if stops have been set along the axis,
#  but it is not needed for axis motors.
#  @ingroup joints
# 
proc dJointSetAMotorAngle*(a2: PJoint; anum: cint; angle: dReal){.importc.}
#*
#  @brief set joint parameter
#  @ingroup joints
# 
proc dJointSetAMotorParam*(a2: PJoint; parameter: cint; value: dReal){.importc.}
#*
#  @brief set mode
#  @ingroup joints
# 
proc dJointSetAMotorMode*(a2: PJoint; mode: cint){.importc.}
#*
#  @brief Applies torque0 about the AMotor's axis 0, torque1 about the
#  AMotor's axis 1, and torque2 about the AMotor's axis 2.
#  @remarks
#  If the motor has fewer than three axes, the higher torques are ignored.
#  This function is just a wrapper for dBodyAddTorque().
#  @ingroup joints
# 
proc dJointAddAMotorTorques*(a2: PJoint; torque1: dReal; torque2: dReal; 
                             torque3: dReal){.importc.}
#*
#  @brief Set the number of axes that will be controlled by the LMotor.
#  @param num can range from 0 (which effectively deactivates the joint) to 3.
#  @ingroup joints
# 
proc dJointSetLMotorNumAxes*(a2: PJoint; num: cint){.importc.}
#*
#  @brief Set the AMotor axes.
#  @param anum selects the axis to change (0,1 or 2).
#  @param rel Each axis can have one of three ``relative orientation'' modes
#  \li 0: The axis is anchored to the global frame.
#  \li 1: The axis is anchored to the first body.
#  \li 2: The axis is anchored to the second body.
#  @remarks The axis vector is always specified in global coordinates
#  regardless of the setting of rel.
#  @ingroup joints
# 
proc dJointSetLMotorAxis*(a2: PJoint; anum: cint; rel: cint; x: dReal; 
                          y: dReal; z: dReal){.importc.}
#*
#  @brief set joint parameter
#  @ingroup joints
# 
proc dJointSetLMotorParam*(a2: PJoint; parameter: cint; value: dReal){.importc.}
#*
#  @ingroup joints
# 
proc dJointSetPlane2DXParam*(a2: PJoint; parameter: cint; value: dReal){.importc.}
#*
#  @ingroup joints
# 
proc dJointSetPlane2DYParam*(a2: PJoint; parameter: cint; value: dReal){.importc.}
#*
#  @ingroup joints
# 
proc dJointSetPlane2DAngleParam*(a2: PJoint; parameter: cint; value: dReal){.importc.}
#*
#  @brief Get the joint anchor point, in world coordinates.
# 
#  This returns the point on body 1. If the joint is perfectly satisfied,
#  this will be the same as the point on body 2.
# 
proc dJointGetBallAnchor*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief Get the joint anchor point, in world coordinates.
# 
#  This returns the point on body 2. You can think of a ball and socket
#  joint as trying to keep the result of dJointGetBallAnchor() and
#  dJointGetBallAnchor2() the same.  If the joint is perfectly satisfied,
#  this function will return the same value as dJointGetBallAnchor() to
#  within roundoff errors. dJointGetBallAnchor2() can be used, along with
#  dJointGetBallAnchor(), to see how far the joint has come apart.
# 
proc dJointGetBallAnchor2*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief get joint parameter
#  @ingroup joints
# 
proc dJointGetBallParam*(a2: PJoint; parameter: cint): dReal{.importc.}
#*
#  @brief Get the hinge anchor point, in world coordinates.
# 
#  This returns the point on body 1. If the joint is perfectly satisfied,
#  this will be the same as the point on body 2.
#  @ingroup joints
# 
proc dJointGetHingeAnchor*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief Get the joint anchor point, in world coordinates.
#  @return The point on body 2. If the joint is perfectly satisfied,
#  this will return the same value as dJointGetHingeAnchor().
#  If not, this value will be slightly different.
#  This can be used, for example, to see how far the joint has come apart.
#  @ingroup joints
# 
proc dJointGetHingeAnchor2*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief get axis
#  @ingroup joints
# 
proc dJointGetHingeAxis*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief get joint parameter
#  @ingroup joints
# 
proc dJointGetHingeParam*(a2: PJoint; parameter: cint): dReal{.importc.}
#*
#  @brief Get the hinge angle.
# 
#  The angle is measured between the two bodies, or between the body and
#  the static environment.
#  The angle will be between -pi..pi.
#  Give the relative rotation with respect to the Hinge axis of Body 1 with
#  respect to Body 2.
#  When the hinge anchor or axis is set, the current position of the attached
#  bodies is examined and that position will be the zero angle.
#  @ingroup joints
# 
proc dJointGetHingeAngle*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get the hinge angle time derivative.
#  @ingroup joints
# 
proc dJointGetHingeAngleRate*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get the slider linear position (i.e. the slider's extension)
# 
#  When the axis is set, the current position of the attached bodies is
#  examined and that position will be the zero position.
#
#  The position is the distance, with respect to the zero position,
#  along the slider axis of body 1 with respect to
#  body 2. (A NULL body is replaced by the world).
#  @ingroup joints
# 
proc dJointGetSliderPosition*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get the slider linear position's time derivative.
#  @ingroup joints
# 
proc dJointGetSliderPositionRate*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get the slider axis
#  @ingroup joints
# 
proc dJointGetSliderAxis*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief get joint parameter
#  @ingroup joints
# 
proc dJointGetSliderParam*(a2: PJoint; parameter: cint): dReal{.importc.}
#*
#  @brief Get the joint anchor point, in world coordinates.
#  @return the point on body 1.  If the joint is perfectly satisfied,
#  this will be the same as the point on body 2.
#  @ingroup joints
# 
proc dJointGetHinge2Anchor*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief Get the joint anchor point, in world coordinates.
#  This returns the point on body 2. If the joint is perfectly satisfied,
#  this will return the same value as dJointGetHinge2Anchor.
#  If not, this value will be slightly different.
#  This can be used, for example, to see how far the joint has come apart.
#  @ingroup joints
# 
proc dJointGetHinge2Anchor2*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief Get joint axis
#  @ingroup joints
# 
proc dJointGetHinge2Axis1*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief Get joint axis
#  @ingroup joints
# 
proc dJointGetHinge2Axis2*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief get joint parameter
#  @ingroup joints
# 
proc dJointGetHinge2Param*(a2: PJoint; parameter: cint): dReal{.importc.}
#*
#  @brief Get angle
#  @ingroup joints
# 
proc dJointGetHinge2Angle1*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get time derivative of angle
#  @ingroup joints
# 
proc dJointGetHinge2Angle1Rate*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get time derivative of angle
#  @ingroup joints
# 
proc dJointGetHinge2Angle2Rate*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get the joint anchor point, in world coordinates.
#  @return the point on body 1. If the joint is perfectly satisfied,
#  this will be the same as the point on body 2.
#  @ingroup joints
# 
proc dJointGetUniversalAnchor*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief Get the joint anchor point, in world coordinates.
#  @return This returns the point on body 2.
#  @remarks
#  You can think of the ball and socket part of a universal joint as
#  trying to keep the result of dJointGetBallAnchor() and
#  dJointGetBallAnchor2() the same. If the joint is
#  perfectly satisfied, this function will return the same value
#  as dJointGetUniversalAnchor() to within roundoff errors.
#  dJointGetUniversalAnchor2() can be used, along with
#  dJointGetUniversalAnchor(), to see how far the joint has come apart.
#  @ingroup joints
# 
proc dJointGetUniversalAnchor2*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief Get axis
#  @ingroup joints
# 
proc dJointGetUniversalAxis1*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief Get axis
#  @ingroup joints
# 
proc dJointGetUniversalAxis2*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief get joint parameter
#  @ingroup joints
# 
proc dJointGetUniversalParam*(a2: PJoint; parameter: cint): dReal{.importc.}
#*
#  @brief Get both angles at the same time.
#  @ingroup joints
# 
#  @param joint   The universal joint for which we want to calculate the angles
#  @param angle1  The angle between the body1 and the axis 1
#  @param angle2  The angle between the body2 and the axis 2
# 
#  @note This function combine getUniversalAngle1 and getUniversalAngle2 together
#        and try to avoid redundant calculation
# 
proc dJointGetUniversalAngles*(a2: PJoint; angle1: ptr dReal; 
                               angle2: ptr dReal){.importc.}
#*
#  @brief Get angle
#  @ingroup joints
# 
proc dJointGetUniversalAngle1*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get angle
#  @ingroup joints
# 
proc dJointGetUniversalAngle2*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get time derivative of angle
#  @ingroup joints
# 
proc dJointGetUniversalAngle1Rate*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get time derivative of angle
#  @ingroup joints
# 
proc dJointGetUniversalAngle2Rate*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get the joint anchor point, in world coordinates.
#  @return the point on body 1. If the joint is perfectly satisfied, 
#  this will be the same as the point on body 2.
#  @ingroup joints
# 
proc dJointGetPRAnchor*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief Get the PR linear position (i.e. the prismatic's extension)
# 
#  When the axis is set, the current position of the attached bodies is
#  examined and that position will be the zero position.
# 
#  The position is the "oriented" length between the
#  position = (Prismatic axis) dot_product [(body1 + offset) - (body2 + anchor2)]
# 
#  @ingroup joints
# 
proc dJointGetPRPosition*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get the PR linear position's time derivative
# 
#  @ingroup joints
# 
proc dJointGetPRPositionRate*(a2: PJoint): dReal{.importc.}
#*
#    @brief Get the PR angular position (i.e. the  twist between the 2 bodies)
#   
#    When the axis is set, the current position of the attached bodies is
#    examined and that position will be the zero position.
#    @ingroup joints
#   
proc dJointGetPRAngle*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get the PR angular position's time derivative
# 
#  @ingroup joints
# 
proc dJointGetPRAngleRate*(a2: PJoint): dReal{.importc.}
#*
#  @brief Get the prismatic axis
#  @ingroup joints
# 
proc dJointGetPRAxis1*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief Get the Rotoide axis
#  @ingroup joints
# 
proc dJointGetPRAxis2*(a2: PJoint; result: TVector3d){.importc.}
#*
#  @brief get joint parameter
#  @ingroup joints
# 
proc dJointGetPRParam*(a2: PJoint; parameter: cint): dReal{.importc.}
#*
#    @brief Get the joint anchor point, in world coordinates.
#    @return the point on body 1. If the joint is perfectly satisfied,
#    this will be the same as the point on body 2.
#    @ingroup joints
#   
proc dJointGetPUAnchor*(a2: PJoint; result: TVector3d){.importc.}
#*
#    @brief Get the PU linear position (i.e. the prismatic's extension)
#   
#    When the axis is set, the current position of the attached bodies is
#    examined and that position will be the zero position.
#   
#    The position is the "oriented" length between the
#    position = (Prismatic axis) dot_product [(body1 + offset) - (body2 + anchor2)]
#   
#    @ingroup joints
#   
proc dJointGetPUPosition*(a2: PJoint): dReal{.importc.}
#*
#    @brief Get the PR linear position's time derivative
#   
#    @ingroup joints
#   
proc dJointGetPUPositionRate*(a2: PJoint): dReal{.importc.}
#*
#    @brief Get the first axis of the universal component of the joint
#    @ingroup joints
#   
proc dJointGetPUAxis1*(a2: PJoint; result: TVector3d){.importc.}
#*
#    @brief Get the second axis of the Universal component of the joint
#    @ingroup joints
#   
proc dJointGetPUAxis2*(a2: PJoint; result: TVector3d){.importc.}
#*
#    @brief Get the prismatic axis
#    @ingroup joints
#   
proc dJointGetPUAxis3*(a2: PJoint; result: TVector3d){.importc.}
#*
#    @brief Get the prismatic axis
#    @ingroup joints
#   
#    @note This function was added for convenience it is the same as
#          dJointGetPUAxis3
#   
proc dJointGetPUAxisP*(id: PJoint; result: TVector3d){.importc.}
#*
#    @brief Get both angles at the same time.
#    @ingroup joints
#   
#    @param joint   The Prismatic universal joint for which we want to calculate the angles
#    @param angle1  The angle between the body1 and the axis 1
#    @param angle2  The angle between the body2 and the axis 2
#   
#    @note This function combine dJointGetPUAngle1 and dJointGetPUAngle2 together
#          and try to avoid redundant calculation
#   
proc getPUAngles*(a2: PJoint; angle1, angle2: ptr dReal){.importc: "dJointGetPUAngles".}
proc getPUAngle1*(a2: PJoint): dReal{.importc: "dJointGetPUAngle1".}
proc getPUAngle1Rate*(a2: PJoint): dReal{.importc: "dJointGetPUAngle1Rate".}
proc getPUAngle2*(a2: PJoint): dReal{.importc: "dJointGetPUAngle2".}
proc getPUAngle2Rate*(a2: PJoint): dReal{.importc: "dJointGetPUAngle2Rate".}
proc getPUParam*(a2: PJoint; parameter: cint): dReal{.importc: "dJointGetPUParam".}
proc getPistonPosition*(a2: PJoint): dReal{.importc: "dJointGetPistonPosition".}
proc getPistonPositionRate*(a2: PJoint): dReal{.importc: "dJointGetPistonPositionRate".}
proc getPistonAngle*(a2: PJoint): dReal{.importc: "dJointGetPistonAngle".}
proc getPistonAngleRate*(a2: PJoint): dReal{.importc: "dJointGetPistonAngleRate".}
proc getPistonAnchor*(a2: PJoint; result: TVector3d){.importc: "dJointGetPistonAnchor".}
proc dJointGetPistonAnchor2*(a2: PJoint; result: TVector3d) {.importc.}
proc dJointGetPistonAxis*(a2: PJoint; result: TVector3d) {.importc.}
proc dJointGetPistonParam*(a2: PJoint; parameter: cint): dReal {.importc.}
proc dJointGetAMotorNumAxes*(a2: PJoint): cint {.importc.}
proc dJointGetAMotorAxis*(a2: PJoint; anum: cint; result: TVector3d) {.importc.}
proc dJointGetAMotorAxisRel*(a2: PJoint; anum: cint): cint {.importc.}
proc dJointGetAMotorAngle*(a2: PJoint; anum: cint): dReal {.importc.}
proc dJointGetAMotorAngleRate*(a2: PJoint; anum: cint): dReal {.importc.}
proc dJointGetAMotorParam*(a2: PJoint; parameter: cint): dReal {.importc.}
proc dJointGetAMotorMode*(a2: PJoint): cint {.importc.}
proc dJointGetLMotorNumAxes*(a2: PJoint): cint {.importc.}
proc dJointGetLMotorAxis*(a2: PJoint; anum: cint; result: TVector3d) {.importc.}
proc dJointGetLMotorParam*(a2: PJoint; parameter: cint): dReal {.importc.}
proc dJointGetFixedParam*(a2: PJoint; parameter: cint): dReal {.importc.}
#*
#  @ingroup joints
# 
proc dConnectingJoint*(body: PBody; a3: PBody): PJoint {.importc.}
#*
#  @ingroup joints
# 
proc dConnectingJointList*(body: PBody; a3: PBody; a4: ptr PJoint): cint {.importc.}
#*
#  @brief Utility function
#  @return 1 if the two bodies are connected together by
#  a joint, otherwise return 0.
#  @ingroup joints
# 
proc dAreConnected*(body: PBody; a3: PBody): cint {.importc.}
#*
#  @brief Utility function
#  @return 1 if the two bodies are connected together by
#  a joint that does not have type @arg{joint_type}, otherwise return 0.
#  @param body1 A body to check.
#  @param body2 A body to check.
#  @param joint_type is a TJointTypeXXX constant.
#  This is useful for deciding whether to add contact joints between two bodies:
#  if they are already connected by non-contact joints then it may not be
#  appropriate to add contacts, however it is okay to add more contact between-
#  bodies that already have contacts.
#  @ingroup joints
# 
proc dAreConnectedExcluding*(body1: PBody; body2: PBody; joint_type: cint): cint {.importc.}

importcizzle "dMass":
  #*
  #  Check if a mass structure has valid value.
  #  The function check if the mass and innertia matrix are positive definits
  # 
  #  @param m A mass structure to check
  # 
  #  @return 1 if both codition are met
  # 
  proc Check*(m: PMass): bool#cint
  proc SetZero*(a2: PMass)
  proc SetParameters*(a2: PMass; themass, cgx, cgy, cgz: dReal;
    I11, I22, I33, I12, I13, I23: dReal)
  proc SetSphere*(a2: PMass; density, radius: dReal)
  proc SetSphereTotal*(a2: PMass; total_mass, radius: dReal)
  proc SetCapsule*(a2: PMass; density: dReal; direction: cint; 
    radius, length: dReal)
  proc SetCapsuleTotal*(a2: PMass; total_mass: dReal; direction: cint; 
                             radius, length: dReal)
  proc SetCylinder*(a2: PMass; density: dReal; direction: cint; 
                         radius, length: dReal)
  proc SetCylinderTotal*(a2: PMass; total_mass: dReal; direction: cint; 
                    radius, length: dReal)
  proc SetBox*(a2: PMass; density, lx, ly, lz: dReal)
  proc SetBoxTotal*(a2: PMass; total_mass, lx, ly, lz: dReal)
  proc SetTrimesh*(a2: PMass; density: dReal; g: PGeom)
  proc SetTrimeshTotal*(m: PMass; total_mass: dReal; g: PGeom)
  proc Adjust*(a2: PMass; newmass: dReal)
  proc Translate*(a2: PMass; x, y, z: dReal)
  proc Rotate*(a2: PMass; R: TMatrix3)
  proc Add*(a, b: PMass)
  # Backwards compatible API
  #ODE_API ODE_API_DEPRECATED void TMassSetCappedCylinder(TMass *a, dReal b, int c, dReal d, dReal e);
  #ODE_API ODE_API_DEPRECATED void TMassSetCappedCylinderTotal(TMass *a, dReal b, int c, dReal d, dReal e);


# Library initialization 
#*
#  @defgroup init Library Initialization
# 
#  Library initialization functions prepare ODE internal data structures for use
#  and release allocated resources after ODE is not needed any more.
# 
#*
#  @brief Library initialization flags.
# 
#  These flags define ODE library initialization options.
# 
#  @c dInitFlagManualThreadCleanup indicates that resources allocated in TLS for threads
#  using ODE are to be cleared by library client with explicit call to @c dCleanupODEAllDataForThread.
#  If this flag is not specified the automatic resource tracking algorithm is used.
# 
#  With automatic resource tracking, On Windows, memory allocated for a thread may 
#  remain not freed for some time after the thread exits. The resources may be 
#  released when one of other threads calls @c dAllocateODEDataForThread. Ultimately,
#  the resources are released when library is closed with @c dCloseODE. On other 
#  operating systems resources are always released by the thread itself on its exit
#  or on library closure with @c dCloseODE.
# 
#  With manual thread data cleanup mode every collision space object must be 
#  explicitly switched to manual cleanup mode with @c dSpaceSetManualCleanup
#  after creation. See description of the function for more details.
# 
#  If @c dInitFlagManualThreadCleanup was not specified during initialization,
#  calls to @c dCleanupODEAllDataForThread are not allowed.
# 
#  @see dInitODE2
#  @see dAllocateODEDataForThread
#  @see dSpaceSetManualCleanup
#  @see dCloseODE
#  @ingroup init
# 
type 
  dInitODEFlags* = enum 
    dInitFlagManualThreadCleanup = 0x00000001 #@< Thread local data is to be cleared explicitly on @c dCleanupODEAllDataForThread function call

#*
#  @brief Initializes ODE library.
#  @param uiInitFlags Initialization options bitmask
#  @return A nonzero if initialization succeeded and zero otherwise.
# 
#  This function must be called to initialize ODE library before first use. If 
#  initialization succeeds the function may not be called again until library is 
#  closed with a call to @c dCloseODE.
# 
#  The @a uiInitFlags parameter specifies initialization options to be used. These
#  can be combination of zero or more @c dInitODEFlags flags.
# 
#  @note
#  If @c dInitFlagManualThreadCleanup flag is used for initialization, 
#  @c dSpaceSetManualCleanup must be called to set manual cleanup mode for every
#  space object right after creation. Failure to do so may lead to resource leaks.
# 
#  @see dInitODEFlags
#  @see dCloseODE
#  @see dSpaceSetManualCleanup
#  @ingroup init
# 
proc InitODE*(uiInitFlags: cuint = 0): cint {.importc: "dInitODE2".}

#*
#  @brief ODE data allocation flags.
# 
#  These flags are used to indicate which data is to be pre-allocated in call to
#  @c dAllocateODEDataForThread.
# 
#  @c dAllocateFlagBasicData tells to allocate the basic data set required for
#  normal library operation. This flag is equal to zero and is always implicitly 
#  included.
# 
#  @c dAllocateFlagCollisionData tells that collision detection data is to be allocated.
#  Collision detection functions may not be called if the data has not be allocated 
#  in advance. If collision detection is not going to be used, it is not necessary
#  to specify this flag.
# 
#  @c dAllocateMaskAll is a mask that can be used for for allocating all possible 
#  data in cases when it is not known what exactly features of ODE will be used.
#  The mask may not be used in combination with other flags. It is guaranteed to
#  include all the current and future legal allocation flags. However, mature 
#  applications should use explicit flags they need rather than allocating everything.
# 
#  @see dAllocateODEDataForThread
#  @ingroup init
# 
type 
  dAllocateODEDataFlags* {.size: sizeof(cint).} = enum 
    dAllocateMaskAll = -1, #@< Allocate all the possible data that is currently defined or will be defined in the future.
    dAllocateFlagBasicData = 0, #@< Allocate basic data required for library to operate
    dAllocateFlagCollisionData = 0x00000001, #@< Allocate data for collision detection

proc AllocateODEDataForThread*(uiAllocateFlags: cint): cint {.importc: "dAllocateODEDataForThread".}
  ## Allocate thread local data to allow the thread calling ODE.
proc CleanupODEAllDataForThread*() {.importc: "dCleanupODEAllDataForThread".}
  ## Free thread local data that was allocated for current thread.
proc CloseODE*() {.importc: "dCloseODE".}
  ## Close ODE after it is not needed any more.


proc CreateTriMeshData*(): TTriMeshDataID {.importc: "dGeomTriMeshDataCreate".}
proc Destroy*(g: TTriMeshDataID) {.importc: "dGeomTriMeshDataDestroy".}
proc TriMeshDataDestroy*(g: TTriMeshDataID) {.inline.} = Destroy(g)

const 
  TRIMESH_FACE_NORMALS* = 0

proc CreateTriMesh*(space: PSpace; Data: TTriMeshDataID; 
                     Callback: dTriCallback; 
                     ArrayCallback: dTriArrayCallback; 
                     RayCallback: dTriRayCallback): PGeom {.importc: "dCreateTriMesh".}
                     
importcizzle "dGeom":
  proc TriMeshDataSet*(g: TTriMeshDataID; data_id: cint; in_data: pointer)
  proc TriMeshDataGet*(g: TTriMeshDataID; data_id: cint): pointer 
  #*
  #  We need to set the last transform after each time step for 
  #  accurate collision response. These functions get and set that transform.
  #  It is stored per geom instance, rather than per dTriMeshDataID.
  # 
  proc TriMeshSetLastTransform*(g: PGeom; last_trans: TMatrix4)
  proc TriMeshGetLastTransform*(g: PGeom): ptr TMatrix4 ## was ptr dReal, verify this 

  #
  #  Build a TriMesh data object with single precision vertex data.
  # 
  proc TriMeshDataBuildSingle*(g: TTriMeshDataID; Vertices: pointer; 
    VertexStride: cint; VertexCount: cint; Indices: pointer; IndexCount: cint; 
    TriStride: cint)
  # same again with a normals array (used as trimesh-trimesh optimization) 
  proc TriMeshDataBuildSingle1*(g: TTriMeshDataID; Vertices: pointer; 
    VertexStride: cint; VertexCount: cint; Indices: pointer; IndexCount: cint; 
    TriStride: cint; Normals: pointer)

  #
  # Build a TriMesh data object with double precision vertex data.
  #
  proc TriMeshDataBuildDouble*(g: TTriMeshDataID; Vertices: pointer; 
    VertexStride: cint; VertexCount: cint; Indices: pointer; IndexCount: cint; 
    TriStride: cint)
  # same again with a normals array (used as trimesh-trimesh optimization) 
  proc TriMeshDataBuildDouble1*(g: TTriMeshDataID; Vertices: pointer; 
    VertexStride: cint; VertexCount: cint; Indices: pointer; IndexCount: cint; 
    TriStride: cint; Normals: pointer)
  #
  #  Simple build. Single/double precision based on dSINGLE/dDOUBLE!
  # 
  proc TriMeshDataBuildSimple*(g: TTriMeshDataID; Vertices: ptr dReal; 
    VertexCount: cint; Indices: ptr dTriIndex; IndexCount: cint)
  # same again with a normals array (used as trimesh-trimesh optimization) 
  proc TriMeshDataBuildSimple1*(g: TTriMeshDataID; Vertices: ptr dReal; 
                                     VertexCount: cint; Indices: ptr dTriIndex; 
                                     IndexCount: cint; Normals: ptr cint)
  # Preprocess the trimesh data to remove mark unnecessary edges and vertices 
  proc TriMeshDataPreprocess*(g: TTriMeshDataID)
  # Get and set the internal preprocessed trimesh data buffer, for loading and saving 
  proc TriMeshDataGetBuffer*(g: TTriMeshDataID; buf: ptr ptr cuchar; 
                                  bufLen: ptr cint)
  proc TriMeshDataSetBuffer*(g: TTriMeshDataID; buf: ptr cuchar)


  proc TriMeshSetCallback*(g: PGeom; Callback: dTriCallback)
  proc TriMeshGetCallback*(g: PGeom): dTriCallback
  
  proc TriMeshSetArrayCallback*(g: PGeom; ArrayCallback: dTriArrayCallback)
  proc TriMeshGetArrayCallback*(g: PGeom): dTriArrayCallback
  
  proc TriMeshSetRayCallback*(g: PGeom; Callback: dTriRayCallback)
  proc TriMeshGetRayCallback*(g: PGeom): dTriRayCallback

  proc TriMeshSetTriMergeCallback*(g: PGeom; Callback: dTriTriMergeCallback)
  proc TriMeshGetTriMergeCallback*(g: PGeom): dTriTriMergeCallback
  
  proc TriMeshSetData*(g: PGeom; Data: TTriMeshDataID)
  proc TriMeshGetData*(g: PGeom): TTriMeshDataID
  proc TriMeshEnableTC*(g: PGeom; geomClass: cint; enable: cint)
  proc TriMeshIsTCEnabled*(g: PGeom; geomClass: cint): cint
  proc TriMeshClearTCCache*(g: PGeom)
  
  proc TriMeshGetTriMeshDataID*(g: PGeom): TTriMeshDataID
  
  proc TriMeshGetTriangle*(g: PGeom; Index: cint; v0, v1, v2: var TVector3d)

  proc TriMeshGetPoint*(g: PGeom; Index: cint; u: dReal; v: dReal; 
                           result: var TVector3d)
  proc TriMeshGetTriangleCount*(g: PGeom): cint
  proc TriMeshDataUpdate*(g: TTriMeshDataID)


{.pop.}

  