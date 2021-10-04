import times

import csfml
import entity
import ../assetLoader

let trashBinImg = "trashcan-black.png"
let trashBinImgBlue = "trashcan-blue.png"
let trashBinImgGreen = "trashcan-green.png"

let trashImg1 = "trash1.png"
let trashImg2 = "trash2.png"
let trashImg3 = "trash3.png"
let trashImg4 = "trash4.png"
let trashImg5 = "trash5.png"

type
  TrashBin* = ref object of Entity
    isEmpty*: bool
    spawningTrash*: bool

  Trash* = ref object of Entity
    discard

proc getTrashBinAssets*(loader: AssetLoader): seq[ImageAsset] =
  return @[loader.newImageAsset(trashBinImg), loader.newImageAsset(trashBinImgBlue), loader.newImageAsset(trashBinImgGreen)]

proc getTrashAssets*(loader: AssetLoader): seq[ImageAsset] =
  return @[loader.newImageAsset(trashImg1), loader.newImageAsset(trashImg2), loader.newImageAsset(trashImg3), loader.newImageAsset(trashImg4), loader.newImageAsset(trashImg5)]
  
proc newTrashBin*(sprite: Sprite): TrashBin =
  result = TrashBin(health: 5, speed: 0)
  initEntity(result, sprite, 5)

proc newTrash*(sprite: Sprite): Trash =
  result = Trash(health: 1, speed: 0)
  initEntity(result, sprite, 0)

method update*(self: Trash, dt: times.Duration) =
  discard
