import times

import csfml
import entity
import ../assetLoader

let trashBinImg = "trashcan-black.png"
let trashBagImg = "succ-aloe-5-v2.png"

type
  TrashKind* = enum
    TrashBin,
    TrashBag

  Trash* = ref object of Entity
    isEmpty*: bool
    kind: TrashKind

proc getTrashAsset*(loader: AssetLoader, kind: TrashKind): ImageAsset =
  case kind:
  of TrashBin:
    return loader.newImageAsset(trashBinImg)
  of TrashBag:
    return loader.newImageAsset(trashBagImg)

proc newTrash*(sprite: Sprite, kind: TrashKind): Trash =
  result = Trash(health: 10, speed: 0)
  initEntity(result, sprite)

method update*(self: Trash, dt: times.Duration) =
  discard
