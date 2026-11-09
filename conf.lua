function love.conf(t)
  t.identity = 'spacexplorer'
  t.version = '11.5'

  t.window.title = 'SpaceXplorer'
  t.window.width = 380
  t.window.height = 640
  t.window.resizable = true
  t.window.minwidth = 320
  t.window.minheight = 540
  t.window.vsync = 1
  t.window.msaa = 0
  t.window.highdpi = true
  t.window.fullscreentype = 'desktop'

  t.modules.physics = false
end
