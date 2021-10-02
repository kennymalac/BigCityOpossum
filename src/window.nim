import csfml

type WindowConfig* = tuple[title: string, width: cint, height: cint, fps: cint]

proc setupWindow*(windowConfig: WindowConfig): RenderWindow =
  let (title, width, height, fps) = windowConfig

  result = new_RenderWindow(video_mode(width, height), title)
  result.vertical_sync_enabled = true
  result.framerate_limit = fps
