-- stars
-- three parallax layers plus the occasional shooting star

local screen = require('screen')

local stars = {}

local layers = {
  {
    count = 54, speedMin = 8, speedMax = 16,
    sizeMin = 0.6, sizeMax = 1.0, alpha = 0.32,
    color = { 0.72, 0.78, 1.0 },
  },
  {
    count = 28, speedMin = 24, speedMax = 40,
    sizeMin = 1.0, sizeMax = 1.6, alpha = 0.55,
    color = { 0.90, 0.92, 1.0 },
  },
  {
    count = 12, speedMin = 52, speedMax = 82,
    sizeMin = 1.6, sizeMax = 2.2, alpha = 0.80,
    color = { 1.0, 0.92, 0.72 },
  },
}

local elapsed = 0
local comet = nil
local cometTimer = 4

local function spawnStar(layer)
  return {
    x = math.random() * screen.width,
    y = math.random() * screen.height,
    speed = layer.speedMin + math.random() * (layer.speedMax - layer.speedMin),
    size = layer.sizeMin + math.random() * (layer.sizeMax - layer.sizeMin),
    phase = math.random() * math.pi * 2,
  }
end

stars.layers = {}
for _, layer in ipairs(layers) do
  layer.dots = {}
  for i = 1, layer.count do
    layer.dots[i] = spawnStar(layer)
  end
  table.insert(stars.layers, layer)
end

function stars.update(dt)
  elapsed = elapsed + dt

  for _, layer in ipairs(stars.layers) do
    for _, dot in ipairs(layer.dots) do
      dot.y = dot.y + dot.speed * dt
      if dot.y > screen.height + 4 then
        dot.y = -4
        dot.x = math.random() * screen.width
      end
    end
  end

  if comet then
    comet.t = comet.t + dt
    comet.x = comet.x + comet.vx * dt
    comet.y = comet.y + comet.vy * dt
    if comet.t >= comet.life then
      comet = nil
    end
  else
    cometTimer = cometTimer - dt
    if cometTimer <= 0 then
      comet = {
        x = 60 + math.random() * (screen.width - 120),
        y = 30 + math.random() * 140,
        vx = -(70 + math.random() * 70),
        vy = 100 + math.random() * 70,
        t = 0,
        life = 0.85,
      }
      cometTimer = 7 + math.random() * 9
    end
  end
end

function stars.draw()
  for _, layer in ipairs(stars.layers) do
    for _, dot in ipairs(layer.dots) do
      local twinkle = 0.72 + 0.28 * math.sin(elapsed * 2.1 + dot.phase)
      local c = layer.color
      love.graphics.setColor(c[1], c[2], c[3], layer.alpha * twinkle)
      love.graphics.circle('fill', dot.x, dot.y, dot.size)
    end
  end

  if comet then
    local alpha = 1 - comet.t / comet.life
    love.graphics.setColor(0.85, 0.92, 1.0, alpha * 0.75)
    love.graphics.setLineWidth(1)
    love.graphics.line(
      comet.x, comet.y,
      comet.x - comet.vx * 0.07, comet.y - comet.vy * 0.07
    )
    love.graphics.setColor(1, 1, 1, alpha * 0.9)
    love.graphics.circle('fill', comet.x, comet.y, 1.2)
  end

  love.graphics.setColor(1, 1, 1, 1)
end

return stars
