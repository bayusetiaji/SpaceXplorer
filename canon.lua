-- canon

local canon = {}

local sprite = love.graphics.newImage('missile.png')
local sound = love.audio.newSource('laser.wav', 'static')

local speed = 640

canon.missile = {}

function canon.reset()
  canon.missile = {}
end

function canon.fire(x, y)
  local m = {}
  m.x = x
  m.y = y
  m.life = true
  table.insert(canon.missile, m)

  sound:stop()
  sound:setPitch(0.94 + math.random() * 0.12)
  sound:play()
end

function canon.update(dt)
  local step = speed * dt
  -- reverse loop so removal is safe
  for i = #canon.missile, 1, -1 do
    canon.missile[i].y = canon.missile[i].y - step

    if canon.missile[i].y <= -10 or not canon.missile[i].life then
      table.remove(canon.missile, i)
    end
  end
end

function canon.draw()
  for i = 1, #canon.missile do
    local m = canon.missile[i]

    love.graphics.setBlendMode('add', 'alphamultiply')
    love.graphics.setColor(1, 0.82, 0.35, 0.35)
    love.graphics.draw(sprite, m.x, m.y, 0, 2.4, 2.4, 1, 0)
    love.graphics.setBlendMode('alpha')

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(sprite, m.x, m.y, 0, 1, 1, 1, 0)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

return canon
