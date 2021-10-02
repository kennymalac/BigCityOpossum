import strformat
import os

import csfml, csfml/audio

type
  ImageAsset* = ref object
    texture*: Texture
    size*: Vector2i

  SoundAsset* = ref SoundAssetObj
  SoundAssetObj = object
    buffer*: SoundBuffer
    kind*: string

    # type RoundRobinAsset =

type
  AssetLoader* = ref object
    location*: string
    # Grlobal scale of all Sprites
    scale*: Vector2f

proc newAssetLoader*(location: string, scale: Vector2f = vec2(1.0, 1.0)): AssetLoader =
  result = AssetLoader(location: location, scale: scale)

proc newImage*(self: AssetLoader, location: string): Image =
  result = newImage(joinPath(self.location, "graphics", location))

proc newImageAsset*(self: AssetLoader, location: string): ImageAsset =
  result = ImageAsset(texture: new_Texture(joinPath(self.location, "graphics", location)))
  # result.size = result.texture.size

proc newImageAsset*(self: AssetLoader, location: string, size: Vector2i): ImageAsset =
  result = ImageAsset(texture: new_Texture(joinPath(self.location, "graphics", location)))
  result.size = size

proc newSprite*(self: AssetLoader, image: ImageAsset): Sprite =
  result = new_Sprite(image.texture)
  # result.origin = vec2(image.size.x/2, image.size.y/2)
  result.scale = self.scale

proc scaledSize*(self: Sprite): Vector2f =
  result = vec2(cfloat(self.texture.size.x) * self.scale.x, cfloat(self.texture.size.y) * self.scale.y)

# PLEASE don't use newSoundAsset - This is used internally by SoundRegistry!
# Initialize a Sound registry and use getSound from that so that each sound instance has a single SoundBuffer
proc newSoundAsset*(self: AssetLoader, kind: string, location: string): SoundAsset =
  result = SoundAsset(kind: kind, buffer: newSoundBuffer(joinPath(self.location, "sound", location)))

proc newSound*(self: SoundAsset): Sound =
  result = newSound()
  result.buffer = self.buffer
