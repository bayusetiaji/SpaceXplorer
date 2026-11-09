-- canister

local screen = require('screen')

local canister = {}

local image = love.graphics.newImage('canister.png')

local function randomX()
  return 40 + math.random() * (screen.width - 80)
end

canister.x = randomX()
canister.y = -250
canister.r = 0
canister.t = 0
canister.active = false

function canister.reset()
  canister.x = randomX()
  canister.y = -250
  canister.r = 0
  canister.active = false
end

function canister.update(dt)
  canister.t = canister.t + dt
  if canister.active then
    canister.y = canister.y + 90 * dt
    canister.r = canister.r + 0.7 * dt

    if canister.y > screen.height + 20 then
      canister.reset()
    end
  end
end

function canister.draw()
  if not canister.active then
    return
  end

  local pulse = 0.5 + 0.5 * math.sin(canister.t * 4 + 1)
  love.graphics.setBlendMode('add', 'alphamultiply')
  love.graphics.setColor(0.4, 1, 0.35, 0.10 + 0.07 * pulse)
  love.graphics.circle('fill', canister.x, canister.y, 15)
  love.graphics.setBlendMode('alpha')

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(image, canister.x, canister.y, canister.r, 1, 1, image:getWidth() / 2, image:getHeight() / 2)
end

function canister.fill(ship)
  if ship.fuel < ship.maxFuel * 0.5 then
    if not canister.active then
      canister.active = true
      return false
    end

    local dx = canister.x - ship.x
    local dy = canister.y - ship.y
    if math.sqrt(dx * dx + dy * dy) <= 30 then
      ship.fuel = ship.maxFuel
      canister.reset()
      return true
    end
  end

  return false
end

return canister
