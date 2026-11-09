-- bgspace
-- vertically tiling nebula backdrop

local screen = require('screen')

local bgspace = {}
local bgspaceImg = love.graphics.newImage('background.jpg')

local scrollSpeed = 26
local imageWidth = bgspaceImg:getWidth()
local imageHeight = bgspaceImg:getHeight()

bgspace.x = math.floor((screen.width - imageWidth) * 0.5)
bgspace.y1 = -imageHeight + screen.height
bgspace.y2 = bgspace.y1 - imageHeight

function bgspace.reset()
  bgspace.y1 = -imageHeight + screen.height
  bgspace.y2 = bgspace.y1 - imageHeight
end

function bgspace.update(dt)
  local step = scrollSpeed * dt
  bgspace.y1 = bgspace.y1 + step
  bgspace.y2 = bgspace.y2 + step

  if bgspace.y1 >= screen.height then
    bgspace.y1 = bgspace.y2 - imageHeight
  end
  if bgspace.y2 >= screen.height then
    bgspace.y2 = bgspace.y1 - imageHeight
  end
end

function bgspace.draw()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(bgspaceImg, bgspace.x, bgspace.y1)
  love.graphics.draw(bgspaceImg, bgspace.x, bgspace.y2)
end

return bgspace
