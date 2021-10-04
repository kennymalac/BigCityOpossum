import tables

import csfml/audio

import assetLoader

type SoundRegistry* = ref object
  registry: TableRef[string, SoundAsset]
  assetLoader: AssetLoader

proc newSoundRegistry*(assetLoader: AssetLoader): SoundRegistry =
  result = SoundRegistry(registry: newTable[string, SoundAsset](), assetLoader: assetLoader)

proc registerSound*(self: SoundRegistry, kind: string, location: string) =
  self.registry[kind] = self.assetLoader.newSoundAsset(kind, location)

proc getSound*(self: SoundRegistry, kind: string): Sound =
  # WARNING - Do not create more than 256 Sound Instances!
  # SFML has an upper limit of 256 instances
  return self.registry[kind].newSound()
