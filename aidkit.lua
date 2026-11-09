-- aidkit

local screen = require('screen')

local aidkit = {}

local image = love.graphics.newImage('aidkit.png')

local function randomX()
  return 40 + math.random() * (screen.width - 80)
end

aidkit.x = randomX()
aidkit.y = -250
aidkit.r = 0
aidkit.t = 0
aidkit.active = false

function aidkit.reset()
  aidkit.x = randomX()
  aidkit.y = -250
  aidkit.r = 0
  aidkit.active = false
end

function aidkit.update(dt)
  aidkit.t = aidkit.t + dt
  if aidkit.active then
    aidkit.y = aidkit.y + 90 * dt
    aidkit.r = aidkit.r + 0.7 * dt

    if aidkit.y > screen.height + 16 then
      aidkit.reset()
    end
  end
end

function aidkit.draw()
  if not aidkit.active then
    return
  end

  local pulse = 0.5 + 0.5 * math.sin(aidkit.t * 4)
  love.graphics.setBlendMode('add', 'alphamultiply')
  love.graphics.setColor(1, 0.42, 0.52, 0.10 + 0.07 * pulse)
  love.graphics.circle('fill', aidkit.x, aidkit.y, 14)
  love.graphics.setBlendMode('alpha')

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(image, aidkit.x, aidkit.y, aidkit.r, 1, 1, image:getWidth() / 2, image:getHeight() / 2)
end

function aidkit.heal(ship)
  if ship.shield < ship.maxShield then
    if not aidkit.active then
      aidkit.active = true
      return false
    end

    local dx = aidkit.x - ship.x
    local dy = aidkit.y - ship.y
    if math.sqrt(dx * dx + dy * dy) <= 30 then
      ship.shield = ship.maxShield
      aidkit.reset()
      return true
    end
  end

  return false
end

return aidkit
