import options
import math

import csfml
import times

import ../assetLoader
import ../vector_utils

type
  Entity* = ref object of RootObj
    sprite*: Sprite
    rect*: FloatRect
    health*: int
    speed*: float
    isDead*: bool
    interRect*: FloatRect
    rectdivisor: cfloat

proc initEntity*(self: Entity, sprite: Sprite, rectpadding: int = 5, rectdivisor: cfloat = 2) =
  self.sprite = sprite
  self.sprite.origin = vec2(cfloat(floor(sprite.scaledSize.x / 2)), cfloat(floor(sprite.scaledSize.y / 2)))
  # TODO no hardcoded rect padding
  self.rectdivisor = rectdivisor
  self.rect = rect(sprite.position.x - cfloat(rectpadding), sprite.position.y - cfloat(rectpadding), cfloat(sprite.scaledSize.x) / rectdivisor, cfloat(sprite.scaledSize.y) / rectdivisor)
  self.interRect = rect(0, 0, 0, 0)

proc initEntity*(self: Entity, sprite: Sprite, rect: FloatRect) =
 self.sprite = sprite
 self.rect = rect
 self.isDead = false

proc newEntity*(sprite: Sprite): Entity =
  new result
  initEntity(result, sprite)

method update*(self: Entity, dt: times.Duration) {.base.} =
  discard

proc draw() =
  discard

proc rotate*(self: Entity, position: Vector2f) =
  self.sprite.rotation = vAngle(self.sprite.position, position)

proc flip*(self: Entity) =
  self.sprite.textureRect = rect(cint(self.sprite.scaledSize.x), 0, -cint(self.sprite.scaledSize.x), cint(self.sprite.scaledSize.y))

proc unflip*(self: Entity) =
  self.sprite.textureRect = rect(0, 0, cint(self.sprite.scaledSize.x), cint(self.sprite.scaledSize.y))

proc updateRectPosition*(self: Entity) =
  self.rect = rect(self.sprite.position.x, self.sprite.position.y, cfloat(self.sprite.scaledSize.x) / self.rectdivisor, cfloat(self.sprite.scaledSize.y) / self.rectdivisor)

proc move*(self: Entity, direction: Vector2f) =
  var moveVector: Vector2f = vec2(direction.x, direction.y)
  moveVector.x *= self.speed
  moveVector.y *= self.speed
  self.sprite.move(moveVector)
  self.updateRectPosition()

proc intersects*(self: Entity, entity: Entity, rect: Option[FloatRect] = none(FloatRect)): bool =
  var selfRect = (if rect.isSome: rect.get() else: self.rect)
  return selfRect.intersects(entity.rect, self.interRect)

proc getNearest*[E](self: Entity, entities: seq[Entity]): Option[E] =
  result = none(E)
  var distance: float = high(float)
  for entity in entities:
    if entity of E:
      var entDistance: float = eDistance(self.sprite.position, entity.sprite.position)
      if entDistance < distance:
        distance = entDistance
        result = some(E(entity))

proc print*(self: Entity) =
  echo "I am an entity\n"
