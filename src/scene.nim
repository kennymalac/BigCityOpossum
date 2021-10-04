import random
import times

randomize()

import csfml #, csfml/ext

import entities/entity
#import entities/enemy
import entities/things
import assetLoader

type
  Scene* = ref object of RootObj
    title*: string
    size*: Vector2i
    view*: View
    entities*: seq[Entity]
    assetLoader*: AssetLoader
    
    origin: Vector2f

    # initialTimeNotSet: bool
    currentTime*: times.Time
    previousTime: times.Time

    # TODO image registry...
    trashAssets: seq[ImageAsset]

proc initScene*(self: Scene, window: RenderWindow, title: string, origin: Vector2f) =
  self.title = title
  self.origin = origin
  self.size = window.size
  self.view = newView(origin, window.size)
  window.view = self.view
  self.assetLoader = newAssetLoader("assets")
  self.previousTime = getTime()
  self.currentTime = getTime()

  self.trashAssets = self.assetLoader.getTrashAssets()

proc newScene*(window: RenderWindow, title: string, origin: Vector2f): Scene =
  new result
  initScene(result, window, title, origin)

proc load*(self: Scene) =
  # Scenes overload this to initialize all initial entities
  discard

method handleEvent*(self: Scene, window: RenderWindow, event: Event) {.base.} =
  # Scenes overload this to handle events
  discard

proc pollEvent*(self: Scene, window: RenderWindow) =
  var event: Event
  while window.poll_event(event):
    case event.kind
    of EventType.Closed:
      window.close()
    else: discard

    self.handleEvent(window, event)

proc update*(self: Scene, window: RenderWindow): Duration =
  self.previousTime = self.currentTime
  self.currentTime = getTime()
  var dt = self.currentTime - self.previousTime

  var addedEntities: seq[Entity] = @[]
  
  for i, entity in self.entities:
    entity.update(dt)
    entity.updateRectPosition()
    if entity of TrashBin:
      if TrashBin(entity).spawningTrash:
        let trash1 = newTrash(self.assetloader.newSprite(sample(self.trashAssets)))
        trash1.sprite.position = vec2(entity.rect.left, entity.rect.top + entity.rect.height)
        addedEntities.add(Entity(trash1))
        let trash2 = newTrash(self.assetLoader.newSprite(sample(self.trashAssets)))
        trash2.sprite.position = vec2(entity.rect.left + 60, entity.rect.top + entity.rect.height)
        addedEntities.add(Entity(trash2))
        # finished spawning
        TrashBin(entity).spawningTrash = false

  for e in addedEntities:
    self.entities.add(e)
        
  return dt

proc draw*(self: Scene, window: RenderWindow) =
  for i, entity in self.entities:
    # entity.draw()
    window.draw(entity.sprite)
