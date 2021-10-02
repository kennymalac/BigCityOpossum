import strformat
import times
import sequtils
import options
import os
import random

import csfml, csfml/audio

import ../scene
import ../assetLoader
import ../soundRegistry
#import ../menus/gameHud
import ../entities/entity
#import ../entities/enemy
import ../entities/player

import stage

# Pull into game state struct separate from stage?
#    score: int

type
  Stage1* = ref object of Scene
    font: Font
    scoreText: Text
    # gameMusic: Sound
    player: Player
    isGameOver: bool
    background: Sprite
    boundary: Boundary
    soundRegistry: SoundRegistry

    # Side scrolling - if the game is following the charcter or not
    sideScrolling: bool    # gameHud: GameHud

proc newStage1*(window: RenderWindow): Stage1 =
  let boundary: Boundary = (cint(300), cint(0), cint(0), cint(0))
  result = Stage1(boundary: boundary, isGameOver: false, sideScrolling: true)

  initScene(
    result,
    window = window,
    title = "Stage 1 - Central Park",
    origin = getOrigin(window.size),
  )

  result.soundRegistry = newSoundRegistry(result.assetLoader)
  # result.gameMusic = result.soundRegistry.getSound(StageGameMusic)
  
  # result.enemySpawnTimer = initDuration(seconds = 0)
  # result.score = 0
  result.font = newFont(joinPath("assets", "fonts", "PressStart2P.ttf"))
  # result.scoreText = newText("Score: ", result.font)
  # result.scoreText.font = result.font
  # result.scoreText.characterSize = 14

proc load*(self: Stage1) =
  # self.gameMusic.loop = true
  # self.gameMusic.play()
  self.background = self.assetLoader.newSprite(
    self.assetLoader.newImageAsset("background_1-1.png")
  )

  self.background.scale = vec2(1, 1)
  self.background.position = vec2(0, 0)

  # TODO: maybe do something like Scene.spawn(entityKind) ?? 
  self.player = newPlayer(self.assetLoader)

  self.player.sprite.position = vec2(200, 200)
  
  self.entities.add(Entity(self.player))

method handleEvent*(self: Stage1, window: RenderWindow, event: Event) =
  case event.kind
  of EventType.KeyPressed:
    case event.key.code
    of KeyCode.Escape:
      window.close()
    else: discard
  else: discard

  self.player.handleMovementEvents(event)

proc update*(self: Stage1, window: RenderWindow) =
  var lastPlayerCoords = self.player.sprite.position
  discard self.Scene.update(window)
  
  # if not self.isGameOver:
  #   self.isGameOver = not self.entities.anyIt(it of Player)

  if self.sidescrolling:
    self.view.move(vec2(self.player.sprite.position.x - lastPlayerCoords.x, float32(0)))

  if self.isGameOver:
    return

  # Purge all dead entities
  self.entities.keepItIf(not it.isDead)

  window.view = self.view

proc draw*(self: Stage1, window: RenderWindow) =
  # var mouseRect = newRectangleShape(vec2(self.currentCursor.rect.width, self.currentCursor.rect.height))
  # mouseRect.position = vec2(self.currentCursor.rect.left, self.currentCursor.rect.top)
  window.draw(self.background)

  self.Scene.draw(window)

  #self.scoreText = newText(fmt"Score: {self.score}", self.font)
  #self.scoreText.characterSize = 18
  #self.scoreText.position = vec2(window.size.x/2 - cfloat(self.scoreText.globalBounds.width/2), 20)

  #window.draw(self.scoreText)

  # window.draw(self.currentCursor.sprite)

  if self.isGameOver:
    let gameOverText = newText("GAME OVER", self.font)
    gameOverText.characterSize = 72
    gameOverText.position = vec2(window.size.x/2 - cfloat(gameOverText.globalBounds.width/2), window.size.y/2 - cfloat(gameOverText.globalBounds.height/2))
    window.draw(gameOverText)

