-- asteroids

local screen = require('screen')

local asteroids = {}
local img = love.graphics.newImage('asteroid.png')
local baseRadius = img:getWidth() * 0.5

local et = 0
local nextSpawn = 1.4

asteroids.rocks = {}

function asteroids.reset()
  asteroids.rocks = {}
  et = 0
  nextSpawn = 1.4
end

function asteroids.spawn(x, y)
  local scale = 0.82 + math.random() * 0.42
  local rock = {
    x = x or (20 + math.random() * (screen.width - 40)),
    y = y or (-40 + math.random() * 20),
    a = math.random() * math.pi * 2,
    spin = (math.random() * 2 - 1) * 0.9,
    scale = scale,
    speed = 105 + math.random() * 55,
    life = true,
  }
  rock.rad = baseRadius * scale
  table.insert(asteroids.rocks, rock)
  return rock
end

function asteroids.create(dt)
  et = et + dt
  if et >= nextSpawn and #asteroids.rocks < 16 then
    asteroids.spawn()
    et = 0
    nextSpawn = 1.55 + math.random() * 0.9
  end
end

function asteroids.update(dt)
  for i = #asteroids.rocks, 1, -1 do
    local rock = asteroids.rocks[i]
    rock.y = rock.y + rock.speed * dt
    rock.a = rock.a + rock.spin * dt

    if rock.y - rock.rad > screen.height + 40 or not rock.life then
      table.remove(asteroids.rocks, i)
    end
  end
end

function asteroids.draw()
  for i = #asteroids.rocks, 1, -1 do
    local rock = asteroids.rocks[i]
    local ox, oy = img:getWidth() / 2, img:getHeight() / 2

    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.draw(img, rock.x + 3, rock.y + 4, rock.a, rock.scale, rock.scale, ox, oy)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img, rock.x, rock.y, rock.a, rock.scale, rock.scale, ox, oy)
  end
end

return asteroids
