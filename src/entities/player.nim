import options
import times

import csfml
import entity
import ../assetLoader

# let opossumWalkImages = @["walk-1.png", "walk-2.png"]
let opossumImg = "ant-sprite.png"

type
  Player* = ref object of Entity
    health*: int
    walking*: bool
    trajectory*: Vector2f

proc newPlayer*(loader: AssetLoader): Player =
  let sprite = loader.newSprite(loader.newImageAsset(opossumImg))
  result = Player(health: 100, speed: 3, walking: false)
  initEntity(result, sprite)

method update*(self: Player, dt: times.Duration) =
  if bool(self.trajectory.x) or bool(self.trajectory.y):
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
