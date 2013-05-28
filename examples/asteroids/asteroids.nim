import ast_comps, fowltek/entitty, fowltek/sdl2/engine
import_all_sdl2_modules
import os, fowltek/idgen, fowltek/vector_math, strutils
import math, tables, fowltek/tmaybe, fowltek/bbtree
randomize()

setImageRoot getAppDir()/"gfx"

var NG =  newSdlEngine()

import ast_serv
var activeServer: TCServ

include ast_boilerplate

var localPlayerID = -1
template localPlayer:expr = activeServer.get_ent(localPlayerID)

const Asteroids = [
  "Rock24b_24x24.png",  
  "Rock48b_48x48.png",
  "Rock64b_64x64.png",
  "Meteor_32x32.png",
  "Rock32a_32x32.png",
  "Rock48c_48x48.png",
  "Rock64c_64x64.png",
  "Rock24a_24x24.png",
  "Rock48a_48x48.png",
  "Rock64a_64x64.png"]

proc init_random_asteroid (X: PEntity)= 
  X.loadSimpleAnim NG, Asteroids[random(Asteroids.len)]

proc add_asteroids (S: PCServ, num = 10) =
  S.add_ents(
    num,
    Pos, Vel, SpriteInst, SimpleAnim, ToroidalBounds
  ).each_ent_cb(
    S,
    init_random_asteroid
  )

proc initialize_local_game (ast_count = (if paramCount() == 1: paramStr(1).parseInt.int else: 10)) =
  activeServer = newServ()

  activeServer.add_asteroids ast_count

  localPlayerID = activeServer.add_ent(activeServer.domain.newEntity(Pos, Vel, SpriteInst, ToroidalBounds, 
    HID_Controller, InputState, Acceleration, Orientation, RollSprite
  ))

  if(var (error, msg) = HID_Dispatcher.requestDevice("Keyboard", LocalPlayer); error):
    echo "Could not register keyboard: ", msg
  LocalPlayer[SpriteInst].loadSprite NG, "hornet_54x54.png"

initialize_local_game()


var running = true
var paused = false
var debugDrawEnabled = false
template stopRunning = running = false

while running:
  while NG.pollHandle:
    case NG.evt.kind
    of QuitEvent: stopRunning
    of KeyDown:
      if paused or not HID_Dispatcher.handleEvent("Keyboard", NG.evt):
        let k = NG.evt.evKeyboard.keysym.sym
        case k
        of K_ESCAPE: stopRunning
        of K_P: paused = not paused
        of K_D: debugDrawEnabled = not debugDrawEnabled
        else:nil
    of keyUp:
      if not paused:
        discard HID_Dispatcher.handleEvent("Keyboard", NG.evt)
    else:nil
  
  let dt = NG.frameDeltaFLT
  
  activeServer.poll
  
  if not paused:
    activeServer.update dt
    
    NG.setDrawColor 0,0,0,255
    NG.clear
    
    eachEntity(activeServer):
      entity.draw NG
    
    LocalPlayer.drawDebugStrings NG
    
    if debugDrawEnabled:
      eachEntity(activeServer):
        entity.debugDraw NG
      activeServer.bbtree.debugDraw NG
  
  NG.present

destroy NG



