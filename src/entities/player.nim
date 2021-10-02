import options
import times

import csfml
import entity
import ../assetLoader

import things

# let opossumWalkImages = @["walk-1.png", "walk-2.png"]
let opossumImg = "opossum1.png"

type
  Player* = ref object of Entity
    health*: int
    strength*: int
    walking*: bool
    attacking*: bool
    eating*: bool
    eatTarget*: Option[Trash]

    triggeredAction*: bool
    # mouthHitbox: FloatRect

    attackSpeed: Duration
    eatSpeed: Duration

    attackTimer: Duration
    eatTimer: Duration
    
    trajectory*: Vector2f

proc newPlayer*(loader: AssetLoader): Player =
  let sprite = loader.newSprite(loader.newImageAsset(opossumImg))
  result = Player(health: 100, strength: 5, speed: 3, triggeredAction: false, walking: false, attackSpeed: initDuration(seconds=1), eatSpeed: initDuration(seconds=2))
  initEntity(result, sprite)

proc addHealth(self: Player, health: int) =
  self.health = min(self.health + 5, 100)
  
proc eatTrash*(self: Player, trash: Trash, dt: Duration) =
  # TODO use eating animation
  if trash.isEmpty:
    return

  trash.health -= self.strength

  if trash.health <= 0:
    trash.isEmpty = true
    # For now make the trash disapper before we have empty trash sprites
    trash.isDead = true
    self.addHealth(5)

  # Reset timer
  self.eatTimer = initDuration(seconds=0)

# proc attack*(self: Player, entity: Enemy, dt: Duration) =
#   # TODO use attack animation
#   self.walking = false
#   entity.health -= self.strength
  
    
proc triggerAction*(self: Player, entities: seq[Entity], dt: Duration) =
  var attacking: seq[Entity] = @[]
  var eating: seq[Entity] = @[]

  for entity in entities:
    if entity of Trash:
      if self.intersects(entity):
        eating.add(entity)
    #elif entity of Enemy

  # NOTE: Attacking has precedence over eating
  if len(attacking) > 0:
    #var enemy = self.getNearest[Enemy](attacking).get()
    self.attacking = true

  elif len(eating) > 0:
    self.eatTarget = getNearest[Trash](self.Entity, eating)
    self.eating = true

method update*(self: Player, dt: times.Duration) =
  if self.triggeredAction:
    # Can't walk while eating or attacking
    self.walking = false
    # Scene needs to call triggerPlayerAction!!

  if self.attacking:
    self.attackTimer += dt
    #if self.eatTimer >= self.eatSpeed:
      #self.attack(enemy, dt)

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
  
