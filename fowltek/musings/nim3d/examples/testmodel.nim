import 
  opengl, glfw,
  baseapp, gl_helpers, camera, nodes, textnode,
  assimp, unsigned, models, vector_math, math
var 
  game = newApp(640, 480)
  var1 = 0.0




game.setRender proc() =
  game.renderScene()


block:
  var cam = game.getCamera()
  cam.setPosition vec3f(0, 0, 300)
  cam.setTarget vec3f(0, 0, 0)
  
  
var m = newModel("ak47.obj")
if not m.isNil:
  m.setPosition vec3f(-70, 0, 0)
  m.scale *= 20.0
  game.getScene.add m

game.setUpdate proc(dt: float) =
  if keystate[key('W')]: 
    game.getCamera.moveForward(-2.0)
  elif keyState[key('S')]:
    game.getCamera.moveForward(2.0)
  if keystate[key('A')]: 
    game.getCamera.strafeRight(2.0)
  elif keystate[key('D')]:
    game.getCamera.strafeRight(-2.0)
  
  if not m.isNil:
    var1 = (var1 + 23.0 * dt) mod 360.0
    m.rot.y = var1


game.run()
