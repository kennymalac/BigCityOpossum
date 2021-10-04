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
let opossumPlayDeadImg = "opossum-playdead.png"

type
  Player* = ref object of Entity
    standTexture: Texture
    playDeadTexture: Texture

    stability*: int
    strength*: int
    walking*: bool
    attacking*: bool
    eating*: bool
    eatTarget*: Option[Trash]
    attackTarget*: Option[Entity]

    triggeredAction*: bool
    # mouthHitbox: FloatRect

    attackSpeed: Duration
    eatSpeed: Duration

    playDeadTimer: Duration

    attackTimer: Duration
    eatTimer: Duration
    stabilityTimer: Duration
    stabilityLossSpeed: Duration

    trajectory*: Vector2f

proc newPlayer*(loader: AssetLoader): Player =
  let standAsset = loader.newImageAsset(opossumImg)
  let playDeadAsset = loader.newImageAsset(opossumPlayDeadImg)
  let sprite = loader.newSprite(standAsset)

  result = Player(standTexture: standAsset.texture, playDeadTexture: playDeadAsset.texture, health: 100, stability: 100, strength: 5, speed: 3, triggeredAction: false, walking: false, playingDead: false, attackSpeed: initDuration(milliseconds=750), eatSpeed: initDuration(seconds=2), attackTimer: initDuration(seconds=0), eatTimer: initDuration(seconds=0), stabilityTimer: initDuration(seconds=0), stabilityLossSpeed: initDuration(seconds=1), playDeadTimer: initDuration(milliseconds=0))
  initEntity(result, sprite, 3)


proc addStability(self: Player, stability: int) =
  self.stability = min(self.stability + stability, 100)
  
proc addHealth(self: Player, health: int) =
  self.health = min(self.health + health, 100)

proc minusHealth(self: Player, health: int) =
  self.health = max(self.health - health, 0)

proc eatTrash*(self: Player, trash: Trash, dt: Duration) =
  # TODO use eating animation
  #if trash.isEmpty:
  #  self.eating = false
  #  return

  trash.health -= self.strength

  if trash.health <= 0:
    trash.isDead = true
    self.addStability(10)
    #trash.isEmpty = true

  # Reset timer
  self.eatTimer = initDuration(seconds=0)
  if not self.triggeredAction:
    self.eating = false

proc playDead*(self: Player, dt: Duration) =
  if self.playDeadTimer == initDuration(seconds=0):
    self.attacking = false
    self.walking = false
    self.sprite.setTexture(self.playDeadTexture, true)
    
  self.playDeadTimer += dt

  if self.playDeadTimer >= initDuration(milliseconds=500):
    self.stability -= 1
    self.playDeadTimer = initDuration(seconds=0)

proc attack*(self: Player, trashBin: TrashBin, dt: Duration) =
  if trashBin.isEmpty:
    self.attacking = false
    return

  # TODO use attack animation
  trashBin.health -= self.strength
  echo(fmt"Attacked trashBin for {self.strength} damage")
  echo(fmt"TrashBin health: {trashBin.health}")

  if trashBin.health <= 0:
    echo(fmt"emptied TrashBin")
    trashBin.isEmpty = true
    trashBin.spawningTrash = true

  # Reset timer
  self.attackTimer = initDuration(seconds=0)
  if not self.triggeredAction:
    self.attacking = false
  
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
    if enemy of Tick:
      self.addStability(1)
    enemy.isDead = true

  # Reset timer
  self.attackTimer = initDuration(seconds=0)
  if not self.triggeredAction:
    self.attacking = false

proc triggerAction*(self: Player, entities: seq[Entity], dt: Duration) =
  var attacking: seq[Entity] = @[]
  var attackingBins: seq[Entity] = @[]
  var eating: seq[Entity] = @[]

  for entity in entities:
    if entity of Enemy:
      if self.intersects(entity):
        attacking.add(entity)

    elif entity of TrashBin:
      if self.intersects(entity) and not TrashBin(entity).isEmpty:
        attackingBins.add(entity)
    
    elif entity of Trash:
      if self.intersects(entity):
        echo("trash intersects")
        eating.add(entity)

  # NOTE: Attacking has precedence over eating
  if len(attackingBins) > 0:
    self.attackTarget = some(Entity(getNearest[TrashBin](self.Entity, attackingBins).get()))
    
    self.attacking = true
    self.eating = false
        
  elif len(attacking) > 0:
    self.attackTarget = some(Entity(getNearest[Enemy](self.Entity, attacking).get()))
    
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

  if self.playingDead:
    self.playDead(dt)

  ############
  # Stability
  ############
  self.stabilityTimer += dt
  if self.stabilityTimer >= self.stabilityLossSpeed:
    if self.stability >= 50:
      self.addHealth(1)

    if self.stability > 0:
      self.stability -= 1
    else:
      # 0 stability means player slowly loses health
      self.minusHealth(2)
    self.stabilityTimer = initDuration(seconds=0)

  ############
  # Attacking
  ############
  if self.attacking:
    self.attackTimer += dt
    if self.attackTimer >= self.attackSpeed:
      let target = self.attackTarget.get()

      if target of TrashBin:
        self.attack(TrashBin(target), dt)
      elif target of Enemy:
        self.attack(Enemy(target), dt)

  if self.eating:
    self.eatTimer += dt
    if self.eatTimer >= self.eatSpeed:
      self.eatTrash(self.eatTarget.get(), dt)

  if self.walking:
    if self.trajectory.x == 1:
      self.flip()
    elif self.trajectory.x == -1:
      self.unflip()
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
    of KeyCode.X:
      self.playingDead = true
    else: discard
  of EventType.KeyReleased:
    case event.key.code:
    of KeyCode.X:
      self.playingDead = false
      self.sprite.setTexture(self.standTexture, true)
      self.playDeadTimer = initDuration(seconds=0)
    of KeyCode.Space:
      self.triggeredAction = false
    else: discard
  else: discard
