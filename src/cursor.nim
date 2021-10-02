import csfml

import assetLoader

type
  GameCursor* = ref GameCursorObj
  GameCursorObj = object
    variant*: string
    cursor*: Cursor
    sprite*: Sprite
    rect*: FloatRect
    padding*: cfloat
    interRect*: FloatRect

proc newGameCursor*(assetLoader: AssetLoader, variant: string, location: string, padding: cfloat = 10): GameCursor =
  result = GameCursor(variant: variant)

  let image = assetLoader.newImage(location)
  result.cursor = newCursor(image.pixelsPtr, image.size, vec2(cint(image.size.x/2), cint(image.size.y/2)))
  result.sprite = assetLoader.newSprite(assetLoader.newImageAsset(location))
  result.sprite.origin = vec2(cfloat(result.sprite.scaledSize.x)/2, cfloat(result.sprite.scaledSize.y) / 2)
  result.rect = rect(result.sprite.position.x + padding/2, result.sprite.position.y + padding/2, cfloat(result.sprite.texture.size.x) + padding, cfloat(result.sprite.texture.size.y) + padding)
  result.padding = padding

  result.interRect = rect(0, 0, 0, 0)

proc updateRectPosition*(self: GameCursor) =
  self.rect = rect(self.sprite.position.x-self.padding, self.sprite.position.y-self.padding, self.sprite.scaledSize.x+self.padding, self.sprite.scaledSize.y+self.padding)
