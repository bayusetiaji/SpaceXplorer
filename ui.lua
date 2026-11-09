-- ui.lua
-- Shared theme, typography and widgets for the menus / HUD.

local ui = {}

ui.colors = {
  ink = { 0.96, 0.95, 1.00 },
  inkDark = { 0.10, 0.05, 0.02 },
  dim = { 0.63, 0.58, 0.76 },
  faint = { 0.40, 0.36, 0.53 },
  accent = { 1.00, 0.83, 0.38 },
  accentDim = { 0.72, 0.54, 0.22 },
  shield = { 0.48, 0.88, 1.00 },
  good = { 0.40, 0.96, 0.65 },
  warn = { 1.00, 0.76, 0.29 },
  danger = { 1.00, 0.35, 0.44 },
}

local fonts = {}

function ui.load()
  for _, size in ipairs({ 8, 9, 10, 11, 12, 13, 14, 16, 18, 20, 24, 28, 32, 40 }) do
    fonts[size] = love.graphics.newFont('whitrabt.ttf', size)
  end
end

function ui.font(size)
  size = math.floor(size)
  local font = fonts[size]
  if not font then
    font = love.graphics.newFont('whitrabt.ttf', size)
    fonts[size] = font
  end
  return font
end

function ui.height(size)
  return ui.font(size):getHeight()
end

function ui.setColor(color, alpha)
  love.graphics.setColor(color[1], color[2], color[3], (color[4] or 1) * (alpha or 1))
end

-- opts: size, color, align (left|center|right), alpha, shadow, shadowAlpha
function ui.text(text, x, y, opts)
  opts = opts or {}
  local font = ui.font(opts.size or 12)
  local color = opts.color or ui.colors.ink
  local alpha = opts.alpha or 1
  local width = font:getWidth(text)

  if opts.align == 'center' then
    x = x - width * 0.5
  elseif opts.align == 'right' then
    x = x - width
  end
  x, y = math.floor(x), math.floor(y)

  love.graphics.setFont(font)
  if opts.shadow ~= false then
    love.graphics.setColor(0, 0, 0, alpha * (opts.shadowAlpha or 0.55))
    love.graphics.print(text, x + 1, y + 1)
  end
  love.graphics.setColor(color[1], color[2], color[3], alpha * (color[4] or 1))
  love.graphics.print(text, x, y)
  return width
end

-- Draws text with extra letter spacing; great for small caps labels.
function ui.tracked(text, x, y, spacing, opts)
  opts = opts or {}
  local font = ui.font(opts.size or 12)
  local color = opts.color or ui.colors.ink
  local alpha = opts.alpha or 1

  local widths, total = {}, 0
  for i = 1, #text do
    local w = font:getWidth(text:sub(i, i))
    widths[i] = w
    total = total + w + spacing
  end
  if #text > 0 then
    total = total - spacing
  end

  if opts.align == 'center' then
    x = x - total * 0.5
  elseif opts.align == 'right' then
    x = x - total
  end

  love.graphics.setFont(font)
  local cx = x
  for i = 1, #text do
    local ch = text:sub(i, i)
    if opts.shadow ~= false then
      love.graphics.setColor(0, 0, 0, alpha * 0.5)
      love.graphics.print(ch, math.floor(cx + 1), math.floor(y + 1))
    end
    love.graphics.setColor(color[1], color[2], color[3], alpha * (color[4] or 1))
    love.graphics.print(ch, math.floor(cx), math.floor(y))
    cx = cx + widths[i] + spacing
  end
  return total
end

function ui.panel(x, y, w, h, opts)
  opts = opts or {}
  local radius = opts.radius or 12
  local alpha = opts.alpha or 0.92

  love.graphics.setColor(0, 0, 0, 0.38 * alpha)
  love.graphics.rectangle('fill', x + 2, y + 4, w, h, radius, radius)

  love.graphics.setColor(0.035, 0.02, 0.075, alpha)
  love.graphics.rectangle('fill', x, y, w, h, radius, radius)

  love.graphics.setColor(1, 0.88, 0.62, 0.035 * alpha)
  love.graphics.rectangle('fill', x + 1, y + 1, w - 2, math.min(h * 0.45, 70), radius, radius)

  love.graphics.setColor(1, 0.83, 0.38, 0.32 * alpha)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle('line', x + 0.5, y + 0.5, w - 1, h - 1, radius, radius)

  if opts.ticks ~= false then
    local len = 12
    local inset = radius + 2
    love.graphics.setColor(1, 0.83, 0.38, 0.85 * alpha)
    love.graphics.setLineWidth(2)
    -- top left
    love.graphics.line(x + inset, y + 1, x + inset + len, y + 1)
    love.graphics.line(x + 1, y + inset, x + 1, y + inset + len)
    -- top right
    love.graphics.line(x + w - inset, y + 1, x + w - inset - len, y + 1)
    love.graphics.line(x + w - 1, y + inset, x + w - 1, y + inset + len)
    -- bottom left
    love.graphics.line(x + inset, y + h - 1, x + inset + len, y + h - 1)
    love.graphics.line(x + 1, y + h - inset, x + 1, y + h - inset - len)
    -- bottom right
    love.graphics.line(x + w - inset, y + h - 1, x + w - inset - len, y + h - 1)
    love.graphics.line(x + w - 1, y + h - inset, x + w - 1, y + h - inset - len)
  end

  love.graphics.setLineWidth(1)
end

function ui.divider(cx, y, width, alpha)
  alpha = alpha or 0.35
  local half = width * 0.5
  love.graphics.setColor(1, 0.83, 0.38, alpha)
  love.graphics.rectangle('fill', cx - half, y, half - 7, 1)
  love.graphics.rectangle('fill', cx + 7, y, half - 7, 1)

  love.graphics.push()
  love.graphics.translate(cx, y + 0.5)
  love.graphics.rotate(math.pi * 0.25)
  love.graphics.rectangle('fill', -2, -2, 4, 4)
  love.graphics.pop()
end

function ui.hline(x1, x2, y, alpha)
  love.graphics.setColor(1, 1, 1, alpha or 0.1)
  love.graphics.rectangle('fill', x1, y, x2 - x1, 1)
end

-- Button widget -------------------------------------------------------------

function ui.button(opts)
  local button = {
    x = opts.x,
    y = opts.y,
    w = opts.w,
    h = opts.h,
    label = opts.label or '',
    fontSize = opts.fontSize or 13,
    style = opts.style or 'primary',
    action = opts.action or function() end,
    enabled = opts.enabled ~= false,
    hover = 0,
    pressed = false,
  }

  function button:contains(mx, my)
    return mx >= self.x and mx <= self.x + self.w
      and my >= self.y and my <= self.y + self.h
  end

  function button:update(dt, mx, my)
    local target = (self.enabled and self:contains(mx, my)) and 1 or 0
    self.hover = self.hover + (target - self.hover) * math.min(1, dt * 16)
    if self.hover < 0.005 then self.hover = 0 end
    if self.hover > 0.995 then self.hover = 1 end
  end

  function button:mousepressed(mx, my, mouseButton)
    if mouseButton == 1 and self.enabled and self:contains(mx, my) then
      self.pressed = true
      return true
    end
    return false
  end

  function button:mousereleased(mx, my, mouseButton)
    if mouseButton ~= 1 or not self.pressed then
      return false
    end
    self.pressed = false
    if self.enabled and self:contains(mx, my) then
      self.action()
      return true
    end
    return false
  end

  function button:draw()
    local hover = self.hover
    local x = self.x
    local y = self.y + (self.pressed and 1 or 0)
    local w, h = self.w, self.h
    local radius = h * 0.5

    if self.style == 'primary' then
      love.graphics.setColor(1, 0.83, 0.38, 0.05 + hover * 0.10)
      love.graphics.rectangle('fill', x - 5, y - 5, w + 10, h + 10, radius + 5, radius + 5)

      love.graphics.setColor(1, 0.83, 0.38, 0.95)
      love.graphics.rectangle('fill', x, y, w, h, radius, radius)

      love.graphics.setColor(1, 0.94, 0.72, 0.55 + hover * 0.25)
      love.graphics.rectangle('fill', x + 2, y + 2, w - 4, h * 0.44, radius, radius)

      love.graphics.setColor(1, 1, 1, hover * 0.20)
      love.graphics.rectangle('fill', x, y, w, h, radius, radius)

      ui.text(self.label, x + w * 0.5, y + (h - ui.height(self.fontSize)) * 0.5 - 1, {
        size = self.fontSize,
        color = ui.colors.inkDark,
        align = 'center',
        shadow = false,
      })
    else
      love.graphics.setColor(1, 0.83, 0.38, 0.05 + hover * 0.11)
      love.graphics.rectangle('fill', x, y, w, h, radius, radius)

      love.graphics.setColor(1, 0.83, 0.38, 0.36 + hover * 0.5)
      love.graphics.setLineWidth(1)
      love.graphics.rectangle('line', x + 0.5, y + 0.5, w - 1, h - 1, radius, radius)
      love.graphics.setLineWidth(1)

      ui.text(self.label, x + w * 0.5, y + (h - ui.height(self.fontSize)) * 0.5 - 1, {
        size = self.fontSize,
        color = ui.colors.accent,
        align = 'center',
        shadow = false,
        alpha = 0.84 + hover * 0.16,
      })
    end
  end

  return button
end

return ui
