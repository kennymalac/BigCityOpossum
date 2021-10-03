import strformat
import times
import sequtils
import options
import os
import random
import math

import csfml, csfml/audio

import ../scene
import ../assetLoader
import ../soundRegistry
#import ../menus/gameHud
import ../entities/entity
import ../entities/enemy
import ../entities/things
import ../entities/player
import ../arena

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

    # Sorted sequence of arenas in stage left to right
    arenas: seq[Arena]
    currentArenaIdx: int
    currentArena: Arena

    # Side scrolling - if the game is following the charcter or not
    sideScrolling: bool    # gameHud: GameHud

proc newStage1*(window: RenderWindow): Stage1 =
  let boundary: Boundary = (cint(10), cint(3000), cint(300), cint(0))
  result = Stage1(boundary: boundary, isGameOver: false, sideScrolling: false, currentArena: Arena(active: false), currentArenaIdx: 0)

  initScene(
    result,
    window = window,
    title = "Stage 1 - The City",
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

  let arB: Boundary = (left: cint(600), right: cint(1880), top: cint(-1), bottom: cint(-1))
  let arena1 = newArena(arB, self.font)
  self.arenas.add(arena1)

  # TODO: maybe do something like Scene.spawn(entityKind) ??
  self.player = newPlayer(self.assetLoader)

  self.player.sprite.position = vec2(200, 200)

  self.entities.add(Entity(self.player))

  let binAsset = self.assetLoader.getTrashAsset(TrashBin)
  let trashBins = @[
    newTrash(self.assetLoader.newSprite(binAsset), TrashBin),
    newTrash(self.assetLoader.newSprite(binAsset), TrashBin),
    newTrash(self.assetLoader.newSprite(binAsset), TrashBin)
  ]

  let ratAsset = self.assetLoader.getRatAssets()
  let rats: seq[Rat] = @[
    newRat(self.assetLoader.newSprite(ratAsset), self.player.Entity),
    newRat(self.assetLoader.newSprite(ratAsset), self.player.Entity),
    newRat(self.assetLoader.newSprite(ratAsset), self.player.Entity)
  ]
  var ratPos = 1200
  for rat in rats:
    rat.sprite.position = vec2(ratPos, 600)
    self.entities.add(Entity(rat))
    ratPos += 150

  var trashPos = 200
  for trash in trashBins:
    trash.sprite.position = vec2(trashPos, 300)
    self.entities.add(Entity(trash))
    trashPos += 200


method handleEvent*(self: Stage1, window: RenderWindow, event: Event) =
  case event.kind
  of EventType.KeyPressed:
    case event.key.code
    of KeyCode.Escape:
      window.close()
    else: discard
  else: discard

  self.player.handleMovementEvents(event)
  self.player.handleActionEvents(event)

proc update*(self: Stage1, window: RenderWindow) =
  var lastPlayerCoords = self.player.sprite.position
  let dt = self.Scene.update(window)

  # figure out which action was triggered
  if self.player.triggeredAction:
    self.player.triggerAction(self.entities, dt)

  # if not self.isGameOver:
  #   self.isGameOver = not self.entities.anyIt(it of Player)

  let viewRightSide = self.view.center.x + ceil(self.view.size.x/2)
  # Once the camera hits the right boundary of the current arena, activate the arena
  if self.currentArena.active and not self.currentArena.started and viewRightSide >= float(self.currentArena.boundary.right):
    self.sidescrolling = false

    # TODO fix issue where enemies wont attack you if bounds aren't reached.
    # maybe the enemies should walk out from the right side
    self.currentArena.activate()
    for entity in self.entities:
      # Activate aggression
      if entity of Enemy and self.currentArena.withinBounds(entity.sprite.position):
        Enemy(entity).aggression = true

  elif not self.currentArena.active and self.player.sprite.position.x > self.view.center.x-300:
    self.sidescrolling = true

  if self.currentArena.active:
    self.currentArena.update(dt)
  # If player is in left bounds of the next arena, make that arena the current arena
  elif self.player.sprite.position.x >= float(self.arenas[self.currentArenaIdx].boundary.left):
    self.currentArena = self.arenas[self.currentArenaIdx]
    self.currentArena.active = true
    self.currentArena.update(dt)

  # Player boundaries

  # TODO add arena boundaries if arena active

  # left boundary
  if self.player.sprite.position.x < (cfloat(self.boundary.left) + cfloat(self.player.sprite.scaledSize.x/2)):
    self.player.sprite.position = vec2(cfloat(self.boundary.left) + cfloat(self.player.sprite.scaledSize.x/2), self.player.sprite.position.y)
    self.player.updateRectPosition()
  # right boundary
  if self.player.sprite.position.x > (cfloat(self.boundary.right) - cfloat(self.player.sprite.scaledSize.x/2)):
    self.player.sprite.position = vec2(cfloat(self.boundary.right) - cfloat(self.player.sprite.scaledSize.x/2), self.player.sprite.position.y)
    self.player.updateRectPosition()

  if self.sidescrolling:
    # How the coordinates of player has changed
    var xDifference = self.player.sprite.position.x - lastPlayerCoords.x
    # If player is navigating left
    if xDifference < 0:
      #echo("diff", xDifference)
      let viewLeftSide = self.view.center.x - floor(self.view.size.x/2)
      echo(viewLeftSide)
      if viewLeftSide - xDifference <= float(self.boundary.left):
        xDifference += float(self.boundary.left) - (float(viewLeftSide) - xDifference)
        #echo("diff 2 ", xDifference)

    elif xDifference > 0:
      if viewRightSide + xDifference >= float(self.boundary.right):
        xDifference += float(self.boundary.right) - (float(viewRightSide) - xDifference)

    self.view.move(vec2(float32(xDifference), float32(0)))

  if self.player.health <= 0:
    echo(fmt"Killed Player")
    self.player.isDead = true
    self.isGameOver = true

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

  let healthText = newText(fmt"Health: {self.player.health}", self.font)
  healthText.characterSize = 18
  healthText.position = vec2(self.view.center.x - cfloat(healthText.globalBounds.width/2), 20)
  window.draw(healthText)

  #window.draw(self.scoreText)

  # window.draw(self.currentCursor.sprite)

  if self.currentArena.active:
    self.currentArena.draw(window, self.view)

  if self.isGameOver:
    let gameOverText = newText("GAME OVER", self.font)
    gameOverText.characterSize = 72
    gameOverText.position = vec2(window.size.x/2 - cfloat(gameOverText.globalBounds.width/2), window.size.y/2 - cfloat(gameOverText.globalBounds.height/2))
    window.draw(gameOverText)
