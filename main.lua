local World = require("game.world")
local Ship = require("game.ship")
local AsteroidsMod = require("game.asteroids")
local Bullets = require("game.bullets")
local Saucers = require("game.saucers")
local Particles = require("game.particles")
local HUD = require("game.hud")
local HighScores = require("game.highscores")
local Palette = require("rendering.palette")
local Fonts = require("rendering.fonts")
local Waves = require("data.waves")
local Sounds = require("audio.sounds")

-- Beat system
local beat = {
    timer = 0,
    which = 1,  -- alternates 1 and 2
    waveStartCount = 4,
}

-- Thrust sound state
local thrustPlaying = false
local thrustTimer = 0

-- Wave transition
local waveDelay = 0
local WAVE_DELAY_TIME = 2.0

-- Respawn
local respawnDelay = 0
local RESPAWN_DELAY_TIME = 2.0

-- Title screen asteroids (decorative)
local titleAsteroidsInited = false

local function startGame()
    World.state = "playing"
    World.wave = 1
    World.score = 0
    World.lives = 3
    World.nextExtraLife = 10000
    World.gameOverTimer = 0

    Ship.init()
    AsteroidsMod.clear()
    Bullets.clear()
    Saucers.clear()
    Particles.clear()

    AsteroidsMod.spawnWave(1)
    beat.waveStartCount = AsteroidsMod.count()
    beat.timer = 0
    beat.which = 1
    waveDelay = 0
    respawnDelay = 0

    Sounds.play("beat1")
end

local function getBeatInterval()
    local total = math.max(beat.waveStartCount, 1)
    local remaining = math.max(AsteroidsMod.count(), 0)
    local ratio = remaining / total
    return 0.1 + 0.7 * ratio
end

local function drawGameWorld()
    love.graphics.push()
    love.graphics.translate(World.offsetX, World.offsetY)
    love.graphics.scale(World.scale)

    local p = Palette.get()
    local top = World.visibleTop()

    -- Background
    love.graphics.setColor(p.bg)
    love.graphics.rectangle("fill", 0, top, World.GAME_W, World.visibleH)

    AsteroidsMod.draw()
    Saucers.draw()
    Bullets.draw()
    Ship.draw()
    Particles.draw()

    HUD.draw()

    love.graphics.pop()
end

local function drawTitleScreen()
    local p = Palette.get()
    local sw, sh = World.screenW, World.screenH
    local t = love.timer.getTime()

    -- Background with drifting asteroids
    love.graphics.push()
    love.graphics.translate(World.offsetX, World.offsetY)
    love.graphics.scale(World.scale)

    local top = World.visibleTop()
    love.graphics.setColor(p.bg)
    love.graphics.rectangle("fill", 0, top, World.GAME_W, World.visibleH)
    AsteroidsMod.draw()

    love.graphics.pop()

    -- Title text
    local centerY = sh * 0.18

    love.graphics.setFont(Fonts.large)
    love.graphics.setColor(p.bright)
    love.graphics.printf("ASTEROIDS", 0, centerY, sw, "center")

    -- Decorative wireframe lines
    love.graphics.setColor(p.asteroid[1], p.asteroid[2], p.asteroid[3], 0.2)
    love.graphics.setLineWidth(1)
    local bx = sw * 0.2
    local by1 = centerY - 10
    local by2 = centerY + Fonts.large:getHeight() + 10
    love.graphics.line(bx, by1, sw - bx, by1)
    love.graphics.line(bx, by2, sw - bx, by2)

    -- Controls
    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(p.fg[1], p.fg[2], p.fg[3], 0.4)
    local ctrlY = sh * 0.42
    love.graphics.printf("ARROWS / WASD: MOVE    SPACE: FIRE    SHIFT: HYPERSPACE", 0, ctrlY, sw, "center")

    -- Press Enter
    local pulse = 0.3 + math.sin(t * 3) * 0.3
    love.graphics.setFont(Fonts.medium)
    love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], pulse + 0.2)
    love.graphics.printf("PRESS ENTER TO START", 0, sh * 0.54, sw, "center")

    -- High score table
    local allScores = HighScores.getScores()
    if #allScores > 0 then
        HighScores.drawTable(sw, sh, p, Fonts)
    end
end

-- Collision helpers
local function circleCollision(x1, y1, r1, x2, y2, r2)
    local _, _, dist = World.wrappedDist(x1, y1, x2, y2)
    return dist < r1 + r2
end

function love.load()
    love.mouse.setVisible(false)
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setLineStyle("smooth")
    Palette.loadFromSystem()
    World.resize(love.graphics.getDimensions())
    Fonts.init(World.scale)
    HighScores.init()
    Sounds.init()
    AsteroidsMod.init()
    World.highScore = HighScores.getHighest()
    World.state = "title"

    -- Spawn some decorative asteroids for title screen
    AsteroidsMod.spawnWave(1)
end

function love.resize(w, h)
    World.resize(w, h)
    Fonts.init(World.scale)
end

function love.update(dt)
    World.ensureScale()

    if World.state == "title" then
        AsteroidsMod.update(dt)
        return
    end

    if World.state == "playing" then
        local s = Ship.get()

        -- Ship update
        if s.alive then
            Ship.update(dt)

            -- Thrust sound
            if s.thrustOn then
                thrustTimer = thrustTimer + dt
                if thrustTimer > 0.25 then
                    thrustTimer = 0
                    Sounds.play("thrust")
                end
            else
                thrustTimer = 0.2  -- play immediately on next thrust
            end
        end

        AsteroidsMod.update(dt)
        Bullets.update(dt)
        Saucers.update(dt, s.x, s.y)
        Particles.update(dt)

        -- Beat timer
        beat.timer = beat.timer + dt
        local interval = getBeatInterval()
        if beat.timer >= interval then
            beat.timer = 0
            if beat.which == 1 then
                Sounds.play("beat1")
                beat.which = 2
            else
                Sounds.play("beat2")
                beat.which = 1
            end
        end

        -- === COLLISION DETECTION ===
        local asteroids = AsteroidsMod.getAll()
        local bullets = Bullets.getAll()

        -- Bullets vs asteroids
        for bi = #bullets, 1, -1 do
            local b = bullets[bi]
            for ai = #asteroids, 1, -1 do
                local a = asteroids[ai]
                if circleCollision(b.x, b.y, 2, a.x, a.y, a.radius) then
                    local result = AsteroidsMod.destroy(ai)
                    if result then
                        World.addScore(result.points)
                        local expSize = result.size == "large" and 12 or (result.size == "medium" and 8 or 5)
                        Particles.spawnExplosion(result.x, result.y, expSize, 80)
                        Sounds.play("explode_" .. result.size)
                    end
                    Bullets.remove(bi)
                    asteroids = AsteroidsMod.getAll()  -- refresh after destroy
                    break
                end
            end
        end

        -- Bullets vs saucer
        local saucer = Saucers.get()
        if saucer then
            for bi = #bullets, 1, -1 do
                local b = bullets[bi]
                if b.owner == "player" and circleCollision(b.x, b.y, 2, saucer.x, saucer.y, saucer.radius) then
                    local points, sx, sy = Saucers.destroy()
                    World.addScore(points)
                    Particles.spawnExplosion(sx, sy, 15, 120)
                    Sounds.play("explode_large")
                    Bullets.remove(bi)
                    break
                end
            end
        end

        -- Ship vs asteroids
        if s.alive and not s.invulnerable then
            local sx, sy, sr = Ship.getCollider()
            for ai = #asteroids, 1, -1 do
                local a = asteroids[ai]
                if circleCollision(sx, sy, sr, a.x, a.y, a.radius) then
                    Ship.die()
                    Particles.spawnShipDeath(s.x, s.y, s.angle, s.vx, s.vy)
                    Sounds.play("ship_explode")
                    World.lives = World.lives - 1
                    respawnDelay = RESPAWN_DELAY_TIME
                    break
                end
            end
        end

        -- Ship vs saucer
        saucer = Saucers.get()
        if s.alive and not s.invulnerable and saucer then
            local sx, sy, sr = Ship.getCollider()
            if circleCollision(sx, sy, sr, saucer.x, saucer.y, saucer.radius) then
                Ship.die()
                Particles.spawnShipDeath(s.x, s.y, s.angle, s.vx, s.vy)
                Sounds.play("ship_explode")
                World.lives = World.lives - 1
                local points, sx2, sy2 = Saucers.destroy()
                World.addScore(points)
                Particles.spawnExplosion(sx2, sy2, 15, 120)
                respawnDelay = RESPAWN_DELAY_TIME
            end
        end

        -- Saucer bullets vs ship
        if s.alive and not s.invulnerable then
            local sx, sy, sr = Ship.getCollider()
            for bi = #bullets, 1, -1 do
                local b = bullets[bi]
                if b.owner == "saucer" and circleCollision(b.x, b.y, 2, sx, sy, sr) then
                    Ship.die()
                    Particles.spawnShipDeath(s.x, s.y, s.angle, s.vx, s.vy)
                    Sounds.play("ship_explode")
                    World.lives = World.lives - 1
                    Bullets.remove(bi)
                    respawnDelay = RESPAWN_DELAY_TIME
                    break
                end
            end
        end

        -- Respawn logic
        if not s.alive then
            respawnDelay = respawnDelay - dt
            if respawnDelay <= 0 then
                if World.lives > 0 then
                    -- Check centre is safe
                    local safe = true
                    for _, a in ipairs(AsteroidsMod.getAll()) do
                        local _, _, dist = World.wrappedDist(World.GAME_W/2, World.GAME_H/2, a.x, a.y)
                        if dist < a.radius + 80 then safe = false; break end
                    end
                    if safe then
                        Ship.respawn()
                    end
                else
                    -- Game over
                    World.state = "game_over"
                    World.gameOverTimer = 0
                    Sounds.play("ship_explode")
                end
            end
        end

        -- Wave clear check
        if AsteroidsMod.count() == 0 and not Saucers.isActive() then
            waveDelay = waveDelay + dt
            if waveDelay >= WAVE_DELAY_TIME then
                waveDelay = 0
                World.wave = World.wave + 1
                AsteroidsMod.spawnWave(World.wave)
                beat.waveStartCount = AsteroidsMod.count()
            end
        else
            waveDelay = 0
        end

    elseif World.state == "game_over" then
        World.gameOverTimer = World.gameOverTimer + dt
        Particles.update(dt)
        AsteroidsMod.update(dt)

    elseif World.state == "high_score_entry" then
        HighScores.updateEntry(dt)
        AsteroidsMod.update(dt)
    end
end

function love.draw()
    love.graphics.clear(0, 0, 0)
    local p = Palette.get()
    local sw, sh = World.screenW, World.screenH

    if World.state == "title" then
        drawTitleScreen()
        return
    end

    if World.state == "high_score_entry" then
        love.graphics.push()
        love.graphics.translate(World.offsetX, World.offsetY)
        love.graphics.scale(World.scale)
        local top = World.visibleTop()
        love.graphics.setColor(p.bg)
        love.graphics.rectangle("fill", 0, top, World.GAME_W, World.visibleH)
        AsteroidsMod.draw()
        love.graphics.pop()

        HighScores.drawEntry(sw, sh, p, Fonts)
        return
    end

    drawGameWorld()

    if World.state == "game_over" then
        local t = love.timer.getTime()
        local midY = sh * 0.35

        if World.gameOverTimer > 0.5 then
            love.graphics.setFont(Fonts.large)
            local textPulse = 0.7 + math.sin(t * 3) * 0.3
            love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], textPulse)
            love.graphics.printf("GAME OVER", 0, midY, sw, "center")
        end

        if World.gameOverTimer > 1.5 then
            love.graphics.setFont(Fonts.medium)
            love.graphics.setColor(p.fg[1], p.fg[2], p.fg[3], 0.7)
            love.graphics.printf("SCORE: " .. string.format("%06d", World.score), 0, midY + Fonts.large:getHeight() + 8, sw, "center")
        end

        if World.gameOverTimer > 2.5 then
            local pulse = 0.3 + math.sin(t * 3) * 0.3
            love.graphics.setFont(Fonts.small)
            love.graphics.setColor(p.bright[1], p.bright[2], p.bright[3], pulse + 0.2)
            love.graphics.printf("PRESS ENTER", 0, midY + Fonts.large:getHeight() + Fonts.medium:getHeight() + 24, sw, "center")
        end
    end
end

function love.keypressed(key)
    if World.state == "title" then
        if key == "return" then startGame() end
        if key == "escape" then love.event.quit() end
        return
    end

    if World.state == "high_score_entry" then
        local result = HighScores.keypressedEntry(key)
        if result == "done" then
            World.highScore = HighScores.getHighest()
            World.state = "title"
            AsteroidsMod.clear()
            AsteroidsMod.spawnWave(1)  -- decorative title asteroids
        end
        return
    end

    if World.state == "playing" then
        local s = Ship.get()
        if key == "space" and s.alive then
            if Bullets.fire(
                s.x + math.cos(s.angle) * 16,
                s.y + math.sin(s.angle) * 16,
                s.angle, s.vx, s.vy, "player"
            ) then
                Sounds.play("fire")
            end
        end

        if (key == "lshift" or key == "rshift") and s.alive then
            local died = Ship.hyperspace()
            if died then
                Ship.die()
                Particles.spawnShipDeath(s.x, s.y, s.angle, s.vx, s.vy)
                Sounds.play("ship_explode")
                World.lives = World.lives - 1
                respawnDelay = RESPAWN_DELAY_TIME
            end
        end
    end

    if World.state == "game_over" then
        if key == "return" and World.gameOverTimer > 2.0 then
            if HighScores.isHighScore(World.score) then
                World.state = "high_score_entry"
                HighScores.startEntry(World.score)
            else
                World.state = "title"
                AsteroidsMod.clear()
                AsteroidsMod.spawnWave(1)
            end
            return
        end
        if key == "escape" then
            World.state = "title"
            AsteroidsMod.clear()
            AsteroidsMod.spawnWave(1)
            return
        end
    end

    if key == "escape" then
        love.event.quit()
    end
end
