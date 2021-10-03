import times

import csfml

type
  AnimationFrame* = object
    rect*: IntRect
    duration*: Duration
  
  Animation* = ref object
    frames*: seq[AnimationFrame]
    totalLength*: Duration
    totalProgress*: Duration
    target*: Sprite

proc newAnimation*(target: Sprite): Animation =
  result = Animation(target: target)

proc addFrame*(self: Animation, frame: AnimationFrame) =
  self.frames.add(frame)
  self.totalLength += frame.duration

proc update*(self: Animation, dt: Duration) =
  self.totalProgress += dt
  var progress = self.totalProgress
  let noTime = initDuration(seconds=0)
  for frame in self.frames:
    progress = progress - frame.duration

    if progress <= noTime or frame == self.frames[self.frames.high]:
      self.target.textureRect = frame.rect
      break
