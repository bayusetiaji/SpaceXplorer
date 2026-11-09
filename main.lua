---------------------------------------------------------------------------
-- SpaceXplorer
-- main.lua
-- Main program
-- credit:
--   BG Music: Cavern and Blade (Open Game Art)
---------------------------------------------------------------------------

local screen = require('screen')
local ui = require('ui')
local hud = require('hud')

-- joystick (game modules read the global `joystick`)
joystick = nil

-- coordinate / layout
local width, height
local centerX, centerY
local shipAnchorY

-- music, sprites
local bgmusic
local gameoverImg

-- game objects
local ship, bgspace, canon, stars, asteroids, aidkit, canister, explosion, powerup

-- run state
local state = 'title' -- title | playing | paused | dying | gameover
local stateTime = 0
local score, hiscore, bestAtStart
local newRecord = false
local gameoverTimer = 0
local muted = false
local firing = false
local shakeAmount = 0
local pointerX, pointerY = 0, -100

-- menus
local titleButton, resumeButton, pauseRestartButton, pauseMenuButton, againButton, menuButton
local titleButtons, pauseButtons, gameoverButtons

local clamp = function(value, low, high)
  return math.max(low, math.min(high, value))
end

local function addShake(amount)
  shakeAmount = math.min(16, shakeAmount + amount)
end

-- persistence ---------------------------------------------------------------

local function loadHighScore()
  local data = love.filesystem.read('highscore.txt')
  if data then
    local value = tonumber(data)
    if value and value > 0 then
      hiscore = math.floor(value)
    end
  end
end

local function saveHighScore()
  love.filesystem.write('highscore.txt', string.format('%d', math.floor(hiscore or 0)))
end

-- state changes -------------------------------------------------------------

local function showCursor()
  love.mouse.setVisible(true)
end

local function hideCursor()
  love.mouse.setVisible(false)
end

local function goMenu()
  state = 'title'
  stateTime = 0
  firing = false
  newRecord = false
  shakeAmount = 0
  screen.setShake(0)
  if hiscore > 0 then
    saveHighScore()
  end

  ship.reset()
  ship.x = centerX
  ship.y = shipAnchorY
  ship.moveTo(centerX, shipAnchorY)
  asteroids.reset()
  canon.reset()
  aidkit.reset()
  canister.reset()
  hud.reset(ship)

  bgmusic:setVolume(0.45)
  if not bgmusic:isPlaying() then
    bgmusic:play()
  end
  showCursor()
  pointerX, pointerY = centerX, -100
end

local function startGame()
  state = 'playing'
  stateTime = 0
  score = 0
  bestAtStart = hiscore
  newRecord = false
  firing = false
  shakeAmount = 0
  screen.setShake(0)

  ship.reset()
  ship.x = centerX
  ship.y = shipAnchorY
  ship.moveTo(centerX, shipAnchorY)
  asteroids.reset()
  canon.reset()
  aidkit.reset()
  canister.reset()
  hud.reset(ship)

  bgmusic:setVolume(0.45)
  if not bgmusic:isPlaying() then
    bgmusic:play()
  end
  hideCursor()
  pointerX, pointerY = centerX, shipAnchorY
end

local function endRound()
  if state ~= 'playing' then
    return
  end

  state = 'dying'
  stateTime = 0
  gameoverTimer = 1.0
  firing = false

  if ship.life then
    ship.kill()
  end
  explosion.emit(ship.x, ship.y, 200)
  hud.damage()
  addShake(11)
  showCursor()

  if score > hiscore then
    hiscore = score
  end
  if score > bestAtStart then
    newRecord = true
  end
  saveHighScore()

  bgmusic:setVolume(0.4)
end

local function togglePause()
  if state == 'playing' then
    state = 'paused'
    stateTime = 0
    firing = false
    shakeAmount = 0
    screen.setShake(0)
    bgmusic:setVolume(0.16)
    showCursor()
  elseif state == 'paused' then
    state = 'playing'
    stateTime = 0
    bgmusic:setVolume(0.45)
    hideCursor()
  end
end

local function toggleMute()
  muted = not muted
  love.audio.setVolume(muted and 0 or 1)
  hud.toast(muted and 'SOUND OFF' or 'SOUND ON')
end

-- combat --------------------------------------------------------------------

local function tryFire()
  if state ~= 'playing' then
    return
  end
  if ship.tryFire() then
    canon.fire(ship.x, ship.y - 28)
  end
end

local function checkCollision()
  for i = #asteroids.rocks, 1, -1 do
    local rock = asteroids.rocks[i]

    for j = #canon.missile, 1, -1 do
      local missile = canon.missile[j]
      if missile.life then
        local dx = missile.x - rock.x
        local dy = missile.y - rock.y
        local reach = rock.rad + 6

        if dx * dx + dy * dy <= reach * reach then
          missile.life = false
          rock.life = false
          score = score + 10
          ship.incMissile()

          if score > hiscore then
            hiscore = score
          end
          if score > bestAtStart then
            newRecord = true
          end

          explosion.emit(rock.x, rock.y, 80)
          hud.popup(rock.x, rock.y - rock.rad, '+10', ui.colors.accent)
          addShake(1.4)
          break
        end
      end
    end

    if rock.life and ship.life then
      local dx = rock.x - ship.x
      local dy = rock.y - ship.y
      local reach = rock.rad + 24

      if dx * dx + dy * dy <= reach * reach then
        if ship.hit() then
          rock.life = false
          explosion.emit(rock.x, rock.y, 70)
          hud.damage()
          addShake(8)

          if ship.shield <= 0 then
            endRound()
          end
        end
      end
    end
  end
end

-- menu helpers --------------------------------------------------------------

local function activeButtons()
  if state == 'title' then
    return titleButtons
  elseif state == 'paused' then
    return pauseButtons
  elseif state == 'gameover' then
    return gameoverButtons
  end
  return {}
end

local function containsButton(buttons, x, y)
  for _, button in ipairs(buttons) do
    if button:contains(x, y) then
      return button
    end
  end
  return nil
end

-- draw screens --------------------------------------------------------------

local function drawTitle()
  love.graphics.setColor(0.02, 0.01, 0.05, 0.24)
  love.graphics.rectangle('fill', 0, 0, width, height)

  ui.tracked('DEEP SPACE ARCADE', centerX, 48, 3, {
    size = 9, color = ui.colors.dim, align = 'center',
  })

  ui.tracked('SPACE', centerX, 68, 2, {
    size = 40, color = ui.colors.accent, align = 'center',
  })
  ui.tracked('XPLORER', centerX, 100, 2, {
    size = 40, color = ui.colors.accent, align = 'center',
  })

  ui.divider(centerX, 146, 210, 0.5)
  ui.tracked('SURVIVE THE ASTEROID BELT', centerX, 158, 1.4, {
    size = 10, color = ui.colors.dim, align = 'center',
  })

  -- best score chip
  ui.panel(centerX - 75, 182, 150, 28, { radius = 9, ticks = false })
  ui.text('BEST', centerX - 63, 193, { size = 9, color = ui.colors.dim })
  ui.text(string.format('%05d', hiscore), centerX + 63, 190, {
    size = 12, color = ui.colors.accent, align = 'right',
  })

  -- short flight manual
  ui.tracked('FLIGHT MANUAL', centerX, 230, 2, {
    size = 8, color = ui.colors.accentDim, align = 'center', alpha = 0.9,
  })
  local rows = {
    { 'MOVE', 'MOUSE / A D' },
    { 'FIRE', 'HOLD CLICK / SPACE' },
    { 'PAUSE', 'P / ESC' },
  }
  local labelX, valueX = 148, 162
  for i = 1, #rows do
    local y = 250 + (i - 1) * 22
    ui.text(rows[i][1], labelX, y, {
      size = 10, color = ui.colors.dim, align = 'right',
    })
    ui.text(rows[i][2], valueX, y, {
      size = 10, color = ui.colors.ink, alpha = 0.92,
    })
  end
  ui.hline(96, 284, 312, 0.08)

  titleButton:draw()
  ui.tracked('PRESS SPACE OR ENTER', centerX, 524, 1.2, {
    size = 9, color = ui.colors.dim, align = 'center', alpha = 0.9,
  })
  ui.tracked('M MUTE      F11 FULLSCREEN', centerX, 603, 1.2, {
    size = 9, color = ui.colors.dim, align = 'center', alpha = 0.85,
  })
end

local function drawPause()
  love.graphics.setColor(0.02, 0.01, 0.05, 0.62)
  love.graphics.rectangle('fill', 0, 0, width, height)

  ui.panel(70, 220, 240, 200, { radius = 16 })
  ui.tracked('PAUSED', centerX, 238, 4, {
    size = 24, color = ui.colors.accent, align = 'center',
  })
  ui.tracked('FLIGHT SUSPENDED', centerX, 268, 1.4, {
    size = 8, color = ui.colors.dim, align = 'center',
  })
  ui.divider(centerX, 282, 150, 0.35)

  resumeButton:draw()
  pauseRestartButton:draw()
  pauseMenuButton:draw()

  ui.tracked('P / ESC  RESUMES', centerX, 386, 1.2, {
    size = 8, color = ui.colors.faint, align = 'center',
  })
end

local function drawGameOver()
  love.graphics.setColor(0.02, 0.01, 0.05, 0.68)
  love.graphics.rectangle('fill', 0, 0, width, height)

  ui.panel(40, 170, 300, 300, { radius = 16 })

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(gameoverImg, centerX - gameoverImg:getWidth() * 0.5, 192)

  ui.divider(centerX, 252, 200, 0.4)
  ui.tracked('FINAL SCORE', centerX, 266, 1.4, {
    size = 9, color = ui.colors.dim, align = 'center',
  })
  ui.text(string.format('%d', score), centerX, 280, {
    size = 32, color = ui.colors.accent, align = 'center',
  })

  if newRecord then
    ui.panel(centerX - 65, 316, 130, 22, { radius = 8, ticks = false })
    ui.tracked('NEW RECORD', centerX, 323, 1.2, {
      size = 9, color = ui.colors.accent, align = 'center',
    })
  else
    ui.text('BEST ' .. string.format('%05d', hiscore), centerX, 320, {
      size = 11, color = ui.colors.dim, align = 'center',
    })
  end

  againButton:draw()
  menuButton:draw()
end

---------------------------------------------------------------------------

function love.load()
  math.randomseed(os.time())

  screen.load()
  ui.load()

  width, height = screen.width, screen.height
  centerX, centerY = width * 0.5, height * 0.5
  shipAnchorY = centerY + 75

  local joysticks = love.joystick.getJoysticks()
  joystick = joysticks[1]

  bgmusic = love.audio.newSource('cavern.ogg', 'stream')
  bgmusic:setLooping(true)
  bgmusic:setVolume(0.45)
  bgmusic:play()

  bgspace = require('bgspace')
  ship = require('ship')
  canon = require('canon')
  stars = require('stars')
  asteroids = require('asteroids')
  aidkit = require('aidkit')
  canister = require('canister')
  explosion = require('explosion')
  powerup = require('powerup')
  hud.load()

  gameoverImg = love.graphics.newImage('gameover.png')

  score = 0
  hiscore = 0
  bestAtStart = 0
  loadHighScore()

  ship.x = centerX
  ship.y = shipAnchorY
  ship.moveTo(centerX, shipAnchorY)

  titleButton = ui.button({
    x = 100, y = 470, w = 180, h = 44,
    label = 'LAUNCH', fontSize = 14, action = startGame,
  })
  resumeButton = ui.button({
    x = 90, y = 292, w = 200, h = 40,
    label = 'RESUME', fontSize = 13, action = togglePause,
  })
  pauseRestartButton = ui.button({
    x = 90, y = 342, w = 96, h = 34,
    label = 'RESTART', fontSize = 12, style = 'ghost', action = startGame,
  })
  pauseMenuButton = ui.button({
    x = 194, y = 342, w = 96, h = 34,
    label = 'MENU', fontSize = 12, style = 'ghost', action = goMenu,
  })
  againButton = ui.button({
    x = 90, y = 366, w = 200, h = 40,
    label = 'PLAY AGAIN', fontSize = 13, action = startGame,
  })
  menuButton = ui.button({
    x = 100, y = 414, w = 180, h = 38,
    label = 'MAIN MENU', fontSize = 11, style = 'ghost', action = goMenu,
  })

  titleButtons = { titleButton }
  pauseButtons = { resumeButton, pauseRestartButton, pauseMenuButton }
  gameoverButtons = { againButton, menuButton }

  showCursor()
  hud.reset(ship)
end

function love.update(dt)
  dt = math.min(dt, 0.05)
  stateTime = stateTime + dt

  shakeAmount = math.max(0, shakeAmount - dt * 26)
  screen.setShake(shakeAmount)

  for _, button in ipairs(activeButtons()) do
    button:update(dt, pointerX, pointerY)
  end

  if state ~= 'paused' then
    bgspace.update(dt)
    stars.update(dt)
  end
  hud.update(dt, ship, score)

  if state == 'title' then
    asteroids.create(dt * 0.55)
    asteroids.update(dt)
    ship.animate(dt)
    return
  end

  if state == 'playing' then
    ship.update(dt)
    canon.update(dt)
    asteroids.create(dt)
    asteroids.update(dt)
    aidkit.update(dt)
    canister.update(dt)
    explosion.update(dt)
    powerup.update(dt)

    local held = firing
      or love.keyboard.isDown('space', 'up')
      or (joystick and joystick:isDown(1))
    if held then
      tryFire()
    end

    checkCollision()

    if state == 'playing' and ship.fuel <= 0 and ship.life then
      endRound()
    end

    if state == 'playing' then
      if ship.life and aidkit.heal(ship) then
        powerup.emit(ship.x, ship.y)
        hud.popup(ship.x, ship.y - 34, 'SHIELD +', ui.colors.shield)
      end
      if ship.life and canister.fill(ship) then
        powerup.emit(ship.x, ship.y)
        hud.popup(ship.x, ship.y - 34, 'FUEL +', ui.colors.good)
      end
    end
    return
  end

  if state == 'dying' then
    canon.update(dt)
    asteroids.update(dt)
    aidkit.update(dt)
    canister.update(dt)
    explosion.update(dt)
    powerup.update(dt)

    gameoverTimer = gameoverTimer - dt
    if gameoverTimer <= 0 then
      state = 'gameover'
      stateTime = 0
    end
    return
  end

  if state == 'gameover' then
    canon.update(dt)
    asteroids.update(dt)
    aidkit.update(dt)
    canister.update(dt)
    explosion.update(dt)
    powerup.update(dt)
  end
end

function love.draw()
  screen.begin()

  bgspace.draw()
  stars.draw()
  asteroids.draw()
  canon.draw()

  if state ~= 'gameover' and state ~= 'dying' then
    ship.draw()
  end

  aidkit.draw()
  canister.draw()
  explosion.draw()
  powerup.draw()

  screen.drawVignette()
  hud.drawFlash()

  if state == 'playing' or state == 'paused' then
    hud.drawStatus(ship, score, hiscore)
  end
  hud.drawPopups()

  if state == 'title' then
    drawTitle()
  elseif state == 'paused' then
    drawPause()
  elseif state == 'gameover' then
    drawGameOver()
  end

  hud.drawToast()
  screen.finish()
end

-- input ---------------------------------------------------------------------

function love.mousepressed(x, y, button)
  local sx, sy = screen.toScene(x, y)
  pointerX, pointerY = sx, sy

  if button ~= 1 then
    return
  end

  for _, menuButton_ in ipairs(activeButtons()) do
    if menuButton_:mousepressed(sx, sy, button) then
      return
    end
  end

  if state == 'playing' then
    firing = true
    ship.moveTo(clamp(sx, 26, width - 26), shipAnchorY)
    tryFire()
  elseif state == 'title' then
    startGame()
  end
end

function love.mousereleased(x, y, button)
  local sx, sy = screen.toScene(x, y)
  pointerX, pointerY = sx, sy

  if button == 1 then
    for _, menuButton_ in ipairs(activeButtons()) do
      if menuButton_:mousereleased(sx, sy, button) then
        return
      end
    end
    firing = false
  end
end

function love.mousemoved(x, y)
  local sx, sy = screen.toScene(x, y)
  pointerX, pointerY = sx, sy

  if state == 'playing' and ship.life then
    ship.moveTo(clamp(sx, 26, width - 26), shipAnchorY)
  end
end

-- touch (mobile): tap menus, drag + hold to fly and fire
local isTouchDevice = love.system.getOS() == 'Android' or love.system.getOS() == 'iOS'

function love.touchpressed(id, x, y)
  if not isTouchDevice then
    return
  end
  local sx, sy = screen.toScene(x, y)
  pointerX, pointerY = sx, sy

  if state == 'playing' then
    firing = true
    ship.moveTo(clamp(sx, 26, width - 26), shipAnchorY)
    tryFire()
  else
    local button = containsButton(activeButtons(), sx, sy)
    if button then
      button:mousepressed(sx, sy, 1)
      button:mousereleased(sx, sy, 1)
    elseif state == 'title' then
      startGame()
    end
  end
end

function love.touchmoved(id, x, y)
  if not isTouchDevice or state ~= 'playing' then
    return
  end
  local sx, sy = screen.toScene(x, y)
  pointerX, pointerY = sx, sy
  ship.moveTo(clamp(sx, 26, width - 26), shipAnchorY)
end

function love.touchreleased()
  if isTouchDevice then
    firing = false
  end
end

function love.keypressed(key)
  if key == 'f11' or (key == 'return' and love.keyboard.isDown('lalt', 'ralt')) then
    screen.toggleFullscreen()
    return
  end

  if key == 'm' then
    toggleMute()
    return
  end

  local confirm = key == 'space' or key == 'return' or key == 'kpenter'

  if state == 'title' then
    if confirm then
      startGame()
    elseif key == 'escape' then
      love.event.quit()
    end
  elseif state == 'playing' then
    if key == 'p' or key == 'escape' then
      togglePause()
    end
  elseif state == 'paused' then
    if key == 'p' or key == 'escape' then
      togglePause()
    elseif confirm then
      togglePause()
    end
  elseif state == 'gameover' then
    if confirm then
      startGame()
    elseif key == 'escape' then
      goMenu()
    end
  end
end

function love.joystickpressed(_, button)
  local isStart = button == 'start' or button == 7 or button == 8 or button == 10
  local isBack = button == 'back' or button == 6

  if isStart then
    if state == 'playing' or state == 'paused' then
      togglePause()
    end
  elseif isBack then
    if state == 'gameover' or state == 'paused' then
      goMenu()
    end
  elseif button == 2 or button == 'b' then
    if state == 'gameover' then
      startGame()
    end
  end
end

function love.joystickadded(added)
  joystick = added
end

function love.joystickremoved(removed)
  if joystick == removed then
    local joysticks = love.joystick.getJoysticks()
    joystick = joysticks[1]
  end
end

function love.focus(focused)
  if not focused and state == 'playing' then
    togglePause()
  end
end

function love.resize()
  screen.resize()
end

function love.quit()
  saveHighScore()
end
