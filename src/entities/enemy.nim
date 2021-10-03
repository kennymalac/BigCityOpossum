import strformat
import times

import csfml
import entity
import ../assetLoader
import ../vector_utils

let ratImg = "opossum1.png"

type
  Enemy* = ref object of Entity
    strength*: int
    # fuck optimization, reference the player for now
    player*: Entity

    aggression*: bool
    attacking*: bool
    attackTimer*: Duration
    attackSpeed: Duration

  Rat* = ref object of Enemy
    direction*: Vector2f
    directionLag*: Duration
    directionTimer*: Duration
    walking*: bool

proc getRatAssets*(loader: AssetLoader): ImageAsset =
  return loader.newImageAsset(ratImg)

proc newRat*(sprite: Sprite, player: Entity): Rat =
  result = Rat(player: player, health: 10, strength: 1, speed: 4, direction: vec2(0.0, 0.0), directionLag: initDuration(seconds = 1), directionTimer: initDuration(seconds = 0), walking: false, aggression: false, attacking: false, attackTimer: initDuration(seconds = 0), attackSpeed: initDuration(seconds=1))
  initEntity(result, sprite)

proc attack*(self: Enemy) =
  if self.player.isDead:
    self.attacking = false
    self.attackTimer = initDuration(seconds=0)
    return
    
  # TODO use attack animation
  self.player.health -= self.strength
  echo(fmt"Enemy attacked player for {self.strength} damage")
  echo(fmt"Player health: {self.player.health}")

  # Reset timer
  self.attackTimer = initDuration(seconds=0)
  self.attacking = false
  
method update*(self: Rat, dt: times.Duration) =
  if not self.attacking and self.aggression:
    self.walking = true

  if self.intersects(self.player):
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
      self.directionTimer = initDuration(seconds = 0)

    if bool(self.direction.x) or bool(self.direction.y):
      self.move(self.direction)
