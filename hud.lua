-- hud.lua
-- In-game heads-up display, kill popups, damage flash and transient toasts.

local ui = require('ui')
local screen = require('screen')

local hud = {}

local scrim
local fuelSmooth = 1
local ammoSmooth = 1
local pulse = 0
local lastScore = 0
local flash = 0
local popups = {}
local toastText = nil
local toastTime = 0
local toastTotal = 0
local elapsed = 0

local function ease(dt, speed)
  return math.min(1, dt * speed)
end

function hud.load()
  scrim = love.graphics.newCanvas(screen.width, screen.height)
  local previous = love.graphics.getCanvas()
  love.graphics.setCanvas(scrim)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setBlendMode('alpha')

  -- top gradient
  local steps = 19
  for i = 0, steps - 1 do
    local t = i / steps
    love.graphics.setColor(0.015, 0.006, 0.04, (1 - t) ^ 2 * 0.66)
    love.graphics.rectangle('fill', 0, i * 4, screen.width, 4)
  end
  -- bottom gradient
  for i = 0, steps - 1 do
    local t = i / (steps - 1)
    love.graphics.setColor(0.015, 0.006, 0.04, t ^ 1.5 * 0.88)
    love.graphics.rectangle('fill', 0, 560 + i * 4, screen.width, 4)
  end

  love.graphics.setCanvas(previous)
  love.graphics.setColor(1, 1, 1, 1)
end

function hud.reset(ship)
  fuelSmooth = ship and (ship.fuel / ship.maxFuel) or 1
  ammoSmooth = ship and (ship.missile / ship.maxMissile) or 1
  pulse = 0
  lastScore = 0
  flash = 0
  popups = {}
  toastText = nil
  toastTime = 0
end

function hud.update(dt, ship, score)
  elapsed = elapsed + dt
  flash = math.max(0, flash - dt * 3.4)
  pulse = math.max(0, pulse - dt * 4.5)

  if score and score > lastScore then
    pulse = 1
  end
  lastScore = score or lastScore

  if ship then
    fuelSmooth = fuelSmooth + ((ship.fuel / ship.maxFuel) - fuelSmooth) * ease(dt, 11)
    ammoSmooth = ammoSmooth + ((ship.missile / ship.maxMissile) - ammoSmooth) * ease(dt, 11)
  end

  for i = #popups, 1, -1 do
    popups[i].t = popups[i].t + dt
    if popups[i].t >= popups[i].life then
      table.remove(popups, i)
    end
  end

  if toastTime > 0 then
    toastTime = math.max(0, toastTime - dt)
  end
end

function hud.popup(x, y, text, color)
  table.insert(popups, {
    x = x,
    y = y,
    text = text,
    color = color or ui.colors.accent,
    t = 0,
    life = 0.85,
  })
end

function hud.toast(text)
  toastText = text
  toastTime = 1.5
  toastTotal = 1.5
end

function hud.damage()
  flash = 1
end

local function bar(x, y, w, h, fraction, color)
  love.graphics.setColor(1, 1, 1, 0.055)
  love.graphics.rectangle('fill', x, y, w, h, h * 0.5, h * 0.5)

  fraction = math.max(0, math.min(1, fraction))
  local fillWidth = w * fraction
  if fillWidth > 1 then
    fillWidth = math.max(fillWidth, h)
    love.graphics.setColor(color[1], color[2], color[3], 0.95)
    love.graphics.rectangle('fill', x, y, fillWidth, h, h * 0.5, h * 0.5)
    love.graphics.setColor(1, 1, 1, 0.22)
    love.graphics.rectangle('fill', x + 1, y + 1, math.max(1, fillWidth - 2), 1)
  end

  love.graphics.setColor(1, 1, 1, 0.13)
  love.graphics.rectangle('line', x + 0.5, y + 0.5, w - 1, h - 1, h * 0.5, h * 0.5)
end

local function levelColor(fraction)
  if fraction > 0.5 then
    return ui.colors.good
  elseif fraction > 0.22 then
    return ui.colors.warn
  end
  return ui.colors.danger
end

local function blink()
  return 0.58 + 0.42 * math.abs(math.sin(elapsed * 6.5))
end

local function drawTop(ship, score, best)
  local isRecord = score > 0 and score >= best

  ui.tracked('SCORE', 16, 13, 1.5, { size = 9, color = ui.colors.dim })
  ui.tracked('BEST', 364, 13, 1.5, { size = 9, color = ui.colors.dim, align = 'right' })

  local scale = 1 + pulse * 0.16
  love.graphics.push()
  love.graphics.translate(15, 23)
  love.graphics.scale(scale, scale)
  love.graphics.setFont(ui.font(16))
  love.graphics.setColor(0, 0, 0, 0.55)
  love.graphics.print(string.format('%05d', score), 1, 1)
  love.graphics.setColor(1, 0.95, 1, 1)
  love.graphics.print(string.format('%05d', score), 0, 0)
  love.graphics.pop()

  ui.text(string.format('%05d', best), 364, 23, {
    size = 16,
    color = isRecord and ui.colors.accent or ui.colors.ink,
    align = 'right',
  })
end

local function drawBottom(ship)
  local groups = {
    { x = 16, label = 'SHIELD' },
    { x = 136, label = 'FUEL' },
    { x = 256, label = 'AMMO' },
  }
  local width = 108
  local labelY = 588
  local barY = 605
  local barH = 8

  local fuelLevel = math.max(0, math.min(1, ship.fuel / ship.maxFuel))
  local ammoLevel = math.max(0, math.min(1, ship.missile / ship.maxMissile))
  local shieldLevel = ship.shield / ship.maxShield

  local shieldColor = shieldLevel > 0.66 and ui.colors.shield
    or (shieldLevel > 0.33 and ui.colors.warn or ui.colors.danger)
  local fuelColor = levelColor(fuelLevel)
  local ammoColor = ammoLevel > 0 and ui.colors.accent or ui.colors.danger

  -- labels + numeric readouts
  ui.tracked(groups[1].label, groups[1].x, labelY, 1, { size = 9, color = ui.colors.dim })
  ui.text(string.format('%d/%d', ship.shield, ship.maxShield), groups[1].x + width, labelY - 1, {
    size = 10, color = shieldColor, align = 'right', alpha = ship.shield <= 1 and blink() or 1,
  })

  ui.tracked(groups[2].label, groups[2].x, labelY, 1, {
    size = 9, color = fuelLevel <= 0.25 and ui.colors.warn or ui.colors.dim,
    alpha = fuelLevel <= 0.25 and blink() or 1,
  })
  ui.text(string.format('%d%%', math.floor(fuelLevel * 100 + 0.5)), groups[2].x + width, labelY - 1, {
    size = 10, color = fuelColor, align = 'right',
  })

  ui.tracked(groups[3].label, groups[3].x, labelY, 1, { size = 9, color = ui.colors.dim })
  ui.text(string.format('%d', ship.missile), groups[3].x + width, labelY - 1, {
    size = 10, color = ammoColor, align = 'right',
  })

  -- shield pips
  local gap = 4
  local segment = (width - gap * 2) / 3
  for i = 1, 3 do
    local x = groups[1].x + (i - 1) * (segment + gap)
    if i <= ship.shield then
      local alpha = ship.shield <= 1 and blink() or 1
      love.graphics.setColor(shieldColor[1], shieldColor[2], shieldColor[3], 0.95 * alpha)
      love.graphics.rectangle('fill', x, barY, segment, barH, 3, 3)
      love.graphics.setColor(1, 1, 1, 0.22 * alpha)
      love.graphics.rectangle('fill', x + 1, barY + 1, segment - 2, 1)
    else
      love.graphics.setColor(1, 1, 1, 0.06)
      love.graphics.rectangle('fill', x, barY, segment, barH, 3, 3)
      love.graphics.setColor(1, 1, 1, 0.12)
      love.graphics.rectangle('line', x + 0.5, barY + 0.5, segment - 1, barH - 1, 3, 3)
    end
  end

  bar(groups[2].x, barY, width, barH, fuelSmooth, fuelColor)
  bar(groups[3].x, barY, width, barH, ammoSmooth, ammoColor)
end

function hud.drawStatus(ship, score, best)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(scrim)
  drawTop(ship, score, best)
  drawBottom(ship)
end

function hud.drawFlash()
  if flash <= 0 then
    return
  end
  love.graphics.setColor(1, 0.12, 0.2, flash * 0.22)
  love.graphics.rectangle('fill', 0, 0, screen.width, screen.height)
end

function hud.drawPopups()
  for _, popup in ipairs(popups) do
    local t = popup.t / popup.life
    local alpha = 1 - t
    local y = popup.y - 8 - t * 26
    ui.text(popup.text, popup.x, y, {
      size = 10,
      color = popup.color,
      align = 'center',
      alpha = alpha,
    })
  end
end

function hud.drawToast()
  if not toastText or toastTime <= 0 then
    return
  end
  local fade = math.min(1, (toastTotal - toastTime) / 0.12, toastTime / 0.35)
  local font = ui.font(10)
  local width = font:getWidth(toastText) + 28
  local height = 24
  local x = math.floor((screen.width - width) * 0.5)
  local y = 544

  love.graphics.setColor(0.03, 0.02, 0.07, 0.88 * fade)
  love.graphics.rectangle('fill', x, y, width, height, height * 0.5, height * 0.5)
  love.graphics.setColor(1, 0.83, 0.38, 0.45 * fade)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle('line', x + 0.5, y + 0.5, width - 1, height - 1, height * 0.5, height * 0.5)
  love.graphics.setLineWidth(1)
  ui.text(toastText, screen.width * 0.5, y + (height - ui.height(10)) * 0.5 - 1, {
    size = 10,
    color = ui.colors.accent,
    align = 'center',
    alpha = fade,
    shadow = false,
  })
end

return hud
