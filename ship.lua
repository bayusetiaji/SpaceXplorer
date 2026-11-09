-- ship

local screen = require('screen')

local ship = {}

local sprite = love.graphics.newImage('spaceship.png')
local followSpeed = 14

ship.x = screen.width / 2
ship.y = screen.height
ship.dx = ship.x
ship.dy = ship.y
ship.r = 0
ship.tilt = 0
ship.shield = 3
ship.fuel = 42
ship.missile = 4200
ship.life = true
ship.invuln = 0
ship.fireCooldown = 0

ship.maxShield = 3
ship.maxFuel = 42
ship.maxMissile = 4200

local exhtexture = love.graphics.newImage('exhaust.png')
local exhaust = love.graphics.newParticleSystem(exhtexture, 500)
exhaust:setParticleLifetime(0.5, 2)
exhaust:setEmissionRate(250)
exhaust:setSizeVariation(1)
exhaust:setLinearAcceleration(-5, 30, 5, 35)
exhaust:setColors(1, 1, 0, 1, 1, 0, 0, 0) -- Fade to transparency.
exhaust:start()

local shake = love.graphics.newParticleSystem(sprite, 5)
shake:setParticleLifetime(0.5, 2)
shake:setLinearAcceleration(-50, -50, 50, 50)
shake:setSizeVariation(1)
shake:setColors(1, 1, 1, 0.6, 1, 1, 0, 0)

function ship.reset()
  ship.r = 0
  ship.tilt = 0
  ship.life = true
  ship.shield = ship.maxShield
  ship.fuel = ship.maxFuel
  ship.missile = ship.maxMissile
  ship.invuln = 0
  ship.fireCooldown = 0
end

function ship.animate(dt)
  exhaust:update(dt)
  shake:update(dt)
end

function ship.update(dt)
  if ship.fireCooldown > 0 then
    ship.fireCooldown = math.max(0, ship.fireCooldown - dt)
  end

  if ship.life then
    ship.fuel = math.max(0, ship.fuel - dt * 0.6)
    if ship.invuln > 0 then
      ship.invuln = math.max(0, ship.invuln - dt)
    end
  end

  local targetTilt = 0
  local keyboard = 0
  if love.keyboard.isDown('a', 'left') then keyboard = keyboard - 1 end
  if love.keyboard.isDown('d', 'right') then keyboard = keyboard + 1 end

  local stick = 0
  if joystick and joystick:isGamepad() then
    stick = joystick:getGamepadAxis('leftx')
    if math.abs(stick) < 0.16 then stick = 0 end
  end

  if keyboard ~= 0 or stick ~= 0 then
    local axis = keyboard ~= 0 and keyboard or stick
    ship.x = ship.x + axis * 340 * dt
    ship.dx = ship.x
    targetTilt = axis * 0.14
  else
    local follow = 1 - math.exp(-followSpeed * dt)
    local previousX = ship.x
    ship.x = ship.x + (ship.dx - ship.x) * follow
    ship.y = ship.y + (ship.dy - ship.y) * follow

    local velocity = (ship.x - previousX) / math.max(dt, 0.0001)
    targetTilt = math.max(-1, math.min(1, velocity / 420)) * 0.16
  end

  ship.x = math.max(26, math.min(screen.width - 26, ship.x))
  ship.y = math.max(26, math.min(screen.height - 26, ship.y))

  ship.tilt = ship.tilt + (targetTilt - ship.tilt) * math.min(1, dt * 10)
  ship.r = ship.tilt

  ship.animate(dt)
end

function ship.draw()
  if ship.life then
    local alpha = 1
    if ship.invuln > 0 then
      alpha = 0.35 + 0.65 * math.abs(math.sin(ship.invuln * 24))
    end

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(exhaust, ship.x - 17, ship.y + 25)
    love.graphics.draw(exhaust, ship.x + 17, ship.y + 25)
    love.graphics.draw(sprite, ship.x, ship.y, ship.r, 1, 1, sprite:getWidth() / 2, sprite:getHeight() / 2)
    love.graphics.setColor(1, 1, 1, 1)
  end

  love.graphics.draw(shake)
end

function ship.moveTo(dx, dy)
  ship.dx = dx
  ship.dy = dy
end

function ship.shake()
  shake:setPosition(ship.x, ship.y)
  shake:emit(5)
end

function ship.hit()
  if not ship.life or ship.invuln > 0 then
    return false
  end

  ship.shield = math.max(0, ship.shield - 1)
  ship.invuln = 1.3
  ship.shake()

  if ship.shield <= 0 then
    ship.kill()
  end

  return true
end

function ship.kill()
  ship.life = false
  ship.invuln = 0
end

function ship.tryFire()
  if not ship.life or ship.fireCooldown > 0 or ship.missile <= 0 then
    return false
  end

  ship.fireCooldown = 0.11
  ship.missile = math.max(0, ship.missile - 1)
  return true
end

function ship.incMissile()
  ship.missile = math.min(ship.maxMissile, ship.missile + 60)
end

function ship.decMissile()
  ship.missile = math.max(0, ship.missile - 1)
end

return ship
