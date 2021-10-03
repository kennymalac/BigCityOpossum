import times
import stages/stage

import csfml

type Arena* = ref object
  boundary*: Boundary
  fightText: Text
  continueText: Text
  showArenaModeText: bool
  arenaModeTextDuration: Duration
  arenaModeTextTimer: Duration
  showFightText: bool
  showContinueText: bool

  # If player is in an arena
  active*: bool
  # Whether or not enemies will attack you
  started*: bool
  # If the arena is finished
  done*: bool

proc newArena*(boundary: Boundary, font: Font): Arena =
  let fightText = newText("FIGHT!!!", font)
  fightText.characterSize = 64
  fightText.fillColor = Red

  let continueText = newText("CONTINUE >>>", font)
  continueText.characterSize = 64
  continueText.fillColor = Green

  result = Arena(
    boundary: boundary,
    fightText: fightText,
    continueText: continueText,
    showArenaModeText: false,
    arenaModeTextDuration: initDuration(seconds=3),
    arenaModeTextTimer: initDuration(seconds=0),
    showContinueText: false,
    active: false,
    started: false,
    done: false
  )

proc update*(self: Arena, dt: Duration) =
  if self.showFightText:
    self.arenaModeTextTimer += dt
    if self.arenaModeTextTimer >= self.arenaModeTextDuration:
      # timer is done
      self.showFightText = false
      self.arenaModeTextTimer = initDuration(seconds=0)

  if self.showContinueText:
    self.arenaModeTextTimer += dt
    if self.arenaModeTextTimer >= self.arenaModeTextDuration:
      # timer is done
      self.showContinueText = false
      self.arenaModeTextTimer = initDuration(seconds=0)

proc draw*(self: Arena, window: RenderWindow, view: View) =
  if self.showFightText:
    self.fightText.position = vec2(view.center.x - cfloat(self.fightText.globalBounds.width/2), view.center.y - cfloat(self.fightText.globalBounds.height/2))
    window.draw(self.fightText)

  if self.showContinueText:
    self.continueText.position = vec2(view.center.x - cfloat(self.continueText.globalBounds.width/2), view.center.y - cfloat(self.continueText.globalBounds.height/2))
    window.draw(self.continueText)

# checkCompleted() = checks if all trashcans eaten(?), monsters defeated
# -> scene sets sidescrolling = true until next region X coordinate detected

proc activate*(self: Arena) =
  self.started = true
  self.showFightText = true
  self.arenaModeTextTimer = initDuration(seconds=0)

proc withinBounds*(self: Arena, coords: Vector2f): bool =
  # if within bounds, sidescrolling stops
  return coords.x >= float(self.boundary.left) and coords.x <= float(self.boundary.right)
# sroll lock
