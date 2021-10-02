import times
import options

import entity, player
import csfml
import ../vector_utils
import ../soundRegistry
import ../assetLoader
import ../window

var win = setupWindow((
  title: "Opossum game",
  width: cint(1280),
  height: cint(720),
  fps: cint(60)
))

let loader = newAssetLoader("../../assets")
let registry = newSoundRegistry(loader)

let playerInstance = newPlayer(loader)
playerInstance.sprite.position = vec2(80, 80)

while win.open:
  win.clear(color(112, 197, 206))

  let dt = getTime()

  win.draw(playerInstance.sprite)
  win.display()

playerInstance.print()
