import 
  opengl, glfw,
  baseapp, gl_helpers, camera, nodes, textnode
var
  game: PApp

game = newApp(640, 480)

game.setUpdate proc(dt: float) =
  if keystate[key('W')]: 
    game.getCamera.moveForward(-2.0)
  elif keyState[key('S')]:
    game.getCamera.moveForward(2.0)
  if keystate[key('A')]: 
    game.getCamera.strafeRight(2.0)
  elif keystate[key('D')]:
    game.getCamera.strafeRight(-2.0)


game.setRender proc() =
  game.renderScene()
  discard """glColor3f 0.0, 1.0, 0.0
  drawWireCube(20.0)"""

var scn = newScene()
game.setScene scn

block:
  let colors = [
    colorf(0.0, 0.0, 1.0), colorf(0.0, 1.0, 0.0), colorf(1.0, 0.0, 0.0)]
  let variance = 10
  for i in 0..2:
    let v = (variance * i) - variance
    var cube = newWireCube(3.0, colors[i])
    cube.setPosition vec3f(v, 0, 0)
    scn.add cube
  var s = newWireSphere(3.0, colors[0])
  s.setPosition vec3f(0, -10, 0)
  scn.add s

block:
  var cam = game.getCamera()
  cam.setPosition vec3f(0, 0, 120)
  cam.setTarget vec3f(0, 0, 0)
  
  var to = newTextNode("helloooo", "LiberationMono-Regular.ttf", 24)
  to.setPosition vec3f(100, 0, 0)
  scn.add(to)
  
  to = newTextNode(":>")
  to.setPosition vec3f(-100, 0, 0)
  scn.add to
  

game.run()
