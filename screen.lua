-- screen.lua
-- Fixed 380x640 play-field rendered to a canvas, then scaled to fit the window.
-- Keeps the game's original layout while making the window resizable / fullscreen.

local screen = {}

screen.width = 380
screen.height = 640
screen.scale = 1
screen.ox = 0
screen.oy = 0
screen.shakeX = 0
screen.shakeY = 0

local canvas
local vignette
local lastWidth, lastHeight = 0, 0

function screen.load()
  canvas = love.graphics.newCanvas(screen.width, screen.height)
  canvas:setFilter('nearest', 'nearest')

  -- soft vignette, built at half resolution and stretched
  local vw, vh = screen.width / 2, screen.height / 2
  local data = love.image.newImageData(vw, vh)
  data:mapPixel(function(x, y)
    local nx = ((x + 0.5) / vw) * 2 - 1
    local ny = ((y + 0.5) / vh) * 2 - 1
    local d = math.sqrt(nx * nx * 0.86 + ny * ny * 0.92)
    local a = math.max(0, (d - 0.46) / 0.78)
    a = math.min(0.62, a * a * 0.8)
    return 0.012, 0.004, 0.035, a
  end)
  vignette = love.graphics.newImage(data)
  vignette:setFilter('linear', 'linear')

  screen.resize()
end

function screen.resize()
  local w, h = love.graphics.getDimensions()
  lastWidth, lastHeight = w, h
  local s = math.min(w / screen.width, h / screen.height)
  screen.scale = s
  screen.ox = math.floor((w - screen.width * s) * 0.5 + 0.5)
  screen.oy = math.floor((h - screen.height * s) * 0.5 + 0.5)

  if canvas then
    -- keep the pixel grid crisp when the window is close to an integer multiple
    local nearest = math.abs(s - math.floor(s + 0.5)) < 0.02
    canvas:setFilter(nearest and 'nearest' or 'linear', nearest and 'nearest' or 'linear')
  end
end

function screen.begin()
  local w, h = love.graphics.getDimensions()
  if w ~= lastWidth or h ~= lastHeight then
    screen.resize()
  end

  love.graphics.push('all')
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setBlendMode('alpha')
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setLineWidth(1)
  love.graphics.origin()
  love.graphics.translate(screen.shakeX, screen.shakeY)
end

function screen.finish()
  love.graphics.setCanvas()
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setBlendMode('alpha')
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canvas, screen.ox, screen.oy, 0, screen.scale, screen.scale)
  love.graphics.pop()
end

function screen.drawVignette()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(vignette, 0, 0, 0, 2, 2)
end

function screen.setShake(amount)
  if amount <= 0.05 then
    screen.shakeX, screen.shakeY = 0, 0
    return
  end
  screen.shakeX = (math.random() * 2 - 1) * amount
  screen.shakeY = (math.random() * 2 - 1) * amount
end

function screen.toScene(x, y)
  return (x - screen.ox) / screen.scale, (y - screen.oy) / screen.scale
end

function screen.toggleFullscreen()
  love.window.setFullscreen(not love.window.getFullscreen(), 'desktop')
  screen.resize()
end

return screen
