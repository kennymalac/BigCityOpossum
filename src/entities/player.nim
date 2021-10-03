import options
import times
import strformat

import csfml

import entity
import ../assetLoader
import ../animation
import things
import enemy

# let opossumWalkImages = @["walk-1.png", "walk-2.png"]
let opossumImg = "opossum3.png"

type
  Player* = ref object of Entity
    stability*: int
    strength*: int
    walking*: bool
    attacking*: bool
    eating*: bool
    eatTarget*: Option[Trash]
    attackTarget*: Option[Enemy]

    triggeredAction*: bool
    # mouthHitbox: FloatRect

    attackSpeed: Duration
    eatSpeed: Duration

    attackTimer: Duration
    eatTimer: Duration
    stabilityTimer: Duration
    stabilityLossSpeed: Duration
    
    trajectory*: Vector2f

proc newPlayer*(loader: AssetLoader): Player =
  let sprite = loader.newSprite(loader.newImageAsset(opossumImg))
  result = Player(health: 100, stability: 50, strength: 5, speed: 3, triggeredAction: false, walking: false, attackSpeed: initDuration(seconds=1), eatSpeed: initDuration(seconds=2), attackTimer: initDuration(seconds=0), eatTimer: initDuration(seconds=0), stabilityTimer: initDuration(seconds=0), stabilityLossSpeed: initDuration(seconds=1))
  initEntity(result, sprite)

proc addHealth(self: Player, health: int) =
  self.health = min(self.health + health, 100)

proc minusHealth(self: Player, health: int) =
  self.health = max(self.health - health, 0)

proc eatTrash*(self: Player, trash: Trash, dt: Duration) =
  # TODO use eating animation
  if trash.isEmpty:
    self.eating = false
    return

  trash.health -= self.strength

  if trash.health <= 0:
    trash.isEmpty = true
    # For now make the trash disapper before we have empty trash sprites
    trash.isDead = true
    self.addHealth(5)

  # Reset timer
  self.eatTimer = initDuration(seconds=0)
  if not self.triggeredAction:
    self.eating = false

proc attack*(self: Player, enemy: Enemy, dt: Duration) =
  if enemy.isDead:
    self.attacking = false
    return
    
  # TODO use attack animation
  enemy.health -= self.strength
  echo(fmt"Attacked enemy for {self.strength} damage")
  echo(fmt"Enemy health: {enemy.health}")
  
  if enemy.health <= 0:
    echo(fmt"Killed Enemy")
    enemy.isDead = true

  # Reset timer
  self.attackTimer = initDuration(seconds=0)
  if not self.triggeredAction:
    self.attacking = false
    
proc triggerAction*(self: Player, entities: seq[Entity], dt: Duration) =
  var attacking: seq[Entity] = @[]
  var eating: seq[Entity] = @[]

  for entity in entities:
    if entity of Enemy:
      if self.intersects(entity):
        attacking.add(entity)
    elif entity of Trash:
      if self.intersects(entity):
        eating.add(entity)

  # NOTE: Attacking has precedence over eating
  if len(attacking) > 0:
    self.attackTarget = getNearest[Enemy](self.Entity, attacking)
    self.attacking = true
    self.eating = false

  elif len(eating) > 0:
    self.attacking = false
    self.eatTarget = getNearest[Trash](self.Entity, eating)
    self.eating = true

method update*(self: Player, dt: times.Duration) =
  if self.triggeredAction:
    # Can't walk while eating or attacking
    self.walking = false
    # Scene needs to call triggerPlayerAction!!

  self.stabilityTimer += dt
  if self.stabilityTimer >= self.stabilityLossSpeed:
    if self.stability > 0:
      self.stability -= 1
    else:
      # 0 stability means player slowly loses health
      self.minusHealth(1)
    self.stabilityTimer = initDuration(seconds=0)

  if self.attacking:
    self.attackTimer += dt
    if self.attackTimer >= self.attackSpeed:
      self.attack(self.attackTarget.get(), dt)

  if self.eating:
    self.eatTimer += dt
    if self.eatTimer >= self.eatSpeed:
      self.eatTrash(self.eatTarget.get(), dt)
    
  if self.walking:
    self.Entity.move(self.trajectory)

proc handleMovementEvents*(self: Player, event: Event) =
  case event.kind
  of EventType.KeyPressed:
    case event.key.code
    of KeyCode.Left:
      self.trajectory.x = -1
    of KeyCode.Right:
      self.trajectory.x = 1
    of KeyCode.Up:
      self.trajectory.y = -1
    of KeyCode.Down:
      self.trajectory.y = 1
    else: discard
  of EventType.KeyReleased:
    case event.key.code:
    of KeyCode.Left:
      if self.trajectory.x == -1:
        self.trajectory.x = 0
    of KeyCode.Right:
      if self.trajectory.x == 1:
        self.trajectory.x = 0
    of KeyCode.Up:
      if self.trajectory.y == -1:
        self.trajectory.y = 0
    of KeyCode.Down:
      if self.trajectory.y == 1:
        self.trajectory.y = 0
    else: discard
  else: discard

  if bool(self.trajectory.x) or bool(self.trajectory.y):
    self.walking = true
  else:
    self.walking = false

proc handleActionEvents*(self: Player, event: Event) =
  case event.kind
  of EventType.KeyPressed:
    case event.key.code
    of KeyCode.Space:
      self.triggeredAction = true
    else: discard
  of EventType.KeyReleased:
    case event.key.code:
    of KeyCode.Space:
      self.triggeredAction = false
    else: discard
  else: discard
  
