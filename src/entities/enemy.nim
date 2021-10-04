import options
import strformat
import times

import csfml
import entity
import ../assetLoader
import ../vector_utils
import things

let tickImg = "tick.png"
let ratImg = "rat1.png"
let racoonImg = "racoon.png"


type
  Enemy* = ref object of Entity
    strength*: int
    # fuck optimization, reference the player for now
    player*: Entity

    aggression*: bool
    attacking*: bool
    attackTimer*: Duration
    attackSpeed: Duration

  Tick* = ref object of Enemy
    direction*: Vector2f
    directionLag*: Duration
    directionTimer*: Duration
    walking*: bool
    
  Rat* = ref object of Enemy
    direction*: Vector2f
    directionLag*: Duration
    directionTimer*: Duration
    walking*: bool

  Racoon* = ref object of Enemy
    direction*: Vector2f
    directionLag*: Duration
    directionTimer*: Duration
    walking*: bool

proc getTickAssets*(loader: AssetLoader): ImageAsset =
  return loader.newImageAsset(tickImg)

proc getRatAssets*(loader: AssetLoader): ImageAsset =
  return loader.newImageAsset(ratImg)

proc getRacoonAssets*(loader: AssetLoader): ImageAsset =
  return loader.newImageAsset(racoonImg)
  
proc newTick*(sprite: Sprite, player: Entity): Tick =
  result = Tick(player: player, health: 5, strength: 1, speed: 5, direction: vec2(0.0, 0.0), directionLag: initDuration(seconds = 1), directionTimer: initDuration(seconds = 0), walking: false, aggression: false, attacking: false, attackTimer: initDuration(seconds = 0), attackSpeed: initDuration(milliseconds=750))
  initEntity(result, sprite, -5)

proc newRat*(sprite: Sprite, player: Entity): Rat =
  result = Rat(player: player, health: 15, strength: 3, speed: 4, direction: vec2(0.0, 0.0), directionLag: initDuration(seconds = 1), directionTimer: initDuration(seconds = 0), walking: false, aggression: false, attacking: false, attackTimer: initDuration(seconds = 0), attackSpeed: initDuration(seconds=1))
  initEntity(result, sprite)

proc newRacoon*(sprite: Sprite, player: Entity): Racoon =
  result = Racoon(player: player, health: 35, strength: 5, speed: 2, direction: vec2(0.0, 0.0), directionLag: initDuration(seconds = 1), directionTimer: initDuration(seconds = 0), walking: false, aggression: false, attacking: false, attackTimer: initDuration(seconds = 0), attackSpeed: initDuration(milliseconds=1500))
  initEntity(result, sprite)
  
proc attack*(self: Enemy) =
  if self.player.isDead:
    self.attacking = false
    self.attackTimer = initDuration(seconds=0)
    return

  if self.player.playingDead:
    self.attacking = false
    self.attackTimer = initDuration(seconds=0)
    return
  
  # TODO use attack animation
  self.player.health -= self.strength
  #echo(fmt"Enemy attacked player for {self.strength} damage")
  #echo(fmt"Player health: {self.player.health}")

  # Reset timer
  self.attackTimer = initDuration(seconds=0)
  self.attacking = false
  
method update*(self: Tick, dt: times.Duration) =
  if not self.attacking and self.aggression:
    self.walking = true

  if self.intersects(self.player) and not self.player.playingDead:
    self.attacking = true
    self.walking = false

  if self.attacking and self.aggression:
    self.attackTimer += dt
    if self.attackTimer >= self.attackSpeed:
      self.attack()
    
  if self.walking:
    self.directionTimer += dt
    if self.directionTimer >= self.directionLag:
      self.direction = normalize(self.player.sprite.position - self.sprite.position)
      if self.direction.x > 0:
        self.flip()
      elif self.direction.x < 0:
        self.unflip()

      self.directionTimer = initDuration(seconds = 0)

    if bool(self.direction.x) or bool(self.direction.y):
      self.move(self.direction)


method update*(self: Rat, dt: times.Duration) =
  if not self.attacking and self.aggression:
    self.walking = true

  if self.sprite.position.y > 800:
    self.isDead = true
    
  if self.intersects(self.player) and not self.player.playingDead:
    self.attacking = true
    self.walking = false

  if self.attacking and self.aggression:
    self.attackTimer += dt
    if self.attackTimer >= self.attackSpeed:
      self.attack()
    
  if self.walking:
    self.directionTimer += dt
    if self.directionTimer >= self.directionLag:
      if self.player.playingDead:
        self.direction = vec2(1, 1)
      else:
        self.direction = normalize(self.player.sprite.position - self.sprite.position)
      if self.direction.x > 0:
        self.flip()
      elif self.direction.x < 0:
        self.unflip()

      self.directionTimer = initDuration(seconds = 0)

    if bool(self.direction.x) or bool(self.direction.y):
      self.move(self.direction)

method update*(self: Racoon, dt: times.Duration, entities: seq[Entity]) =
  if not self.attacking and self.aggression:
    self.walking = true

  if self.sprite.position.y > 810:
    self.isDead = true
    
  if self.intersects(self.player) and not self.player.playingDead:
    self.attacking = true
    self.walking = false

  if self.attacking and self.aggression:
    self.attackTimer += dt
    if self.attackTimer >= self.attackSpeed:
      self.attack()
    
  if self.walking:
    self.directionTimer += dt
    if self.directionTimer >= self.directionLag:
      if self.player.playingDead:
        let trash = getNearest[Trash](self.Entity, entities)
        if trash.isSome():
          self.direction = normalize(trash.get().sprite.position - self.sprite.position)
        else:
          self.direction = normalize(vec2(self.player.sprite.position.x - 80, self.player.sprite.position.y - 80) - self.sprite.position)
      else:
        self.direction = normalize(self.player.sprite.position - self.sprite.position)
      if self.direction.x > 0:
        self.flip()
      elif self.direction.x < 0:
        self.unflip()

      self.directionTimer = initDuration(seconds = 0)

    if bool(self.direction.x) or bool(self.direction.y):
      self.move(self.direction)

