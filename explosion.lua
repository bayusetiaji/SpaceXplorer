-- explosion
-- particle burst plus a short expanding shockwave

local explosion = {}

local sound = love.audio.newSource('explosion.wav', 'static')
local texture = love.graphics.newImage('explosion.png')

local psystem = love.graphics.newParticleSystem(texture, 200)
psystem:setParticleLifetime(0.5, 2)
psystem:setLinearAcceleration(-50, 50, 50, 100)
psystem:setSizeVariation(1)
psystem:setColors(1, 1, 0, 1, 1, 1, 1, 0)

local rings = {}

function explosion.emit(x, y, count)
  sound:stop()
  sound:setPitch(0.86 + math.random() * 0.28)
  sound:play()

  psystem:setPosition(x, y)
  psystem:emit(count or 100)

  table.insert(rings, { x = x, y = y, t = 0 })
end

function explosion.update(dt)
  psystem:update(dt)

  for i = #rings, 1, -1 do
    rings[i].t = rings[i].t + dt
    if rings[i].t >= 0.36 then
      table.remove(rings, i)
    end
  end
end

function explosion.draw()
  love.graphics.setBlendMode('add', 'alphamultiply')
  for _, ring in ipairs(rings) do
    local t = ring.t / 0.36
    love.graphics.setColor(1, 0.82, 0.45, (1 - t) * 0.55)
    love.graphics.setLineWidth(2)
    love.graphics.circle('line', ring.x, ring.y, 8 + t * 30)
  end
  love.graphics.setLineWidth(1)
  love.graphics.setBlendMode('alpha')

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(psystem)
end

return explosion
