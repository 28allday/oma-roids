local World = require("game.world")
local Palette = require("rendering.palette")
local Bullets = require("game.bullets")

local Saucers = {}

local saucer = nil
local spawnTimer = 0
local SPAWN_INTERVAL = 15

local DEFS = {
    large = { speed = 150, fireRate = 1.5, radius = 20, points = 200 },
    small = { speed = 200, fireRate = 1.0, radius = 12, points = 1000 },
}

-- Saucer shape: classic flying saucer profile
local SHAPE_LARGE = {
    {-20, 0}, {-10, -8}, {10, -8}, {20, 0},
    {10, 6}, {-10, 6}, {-20, 0},
}
local SHAPE_LARGE_TOP = {
    {-10, -8}, {-6, -14}, {6, -14}, {10, -8},
}
local SHAPE_SMALL = {
    {-12, 0}, {-6, -5}, {6, -5}, {12, 0},
    {6, 4}, {-6, 4}, {-12, 0},
}
local SHAPE_SMALL_TOP = {
    {-6, -5}, {-3, -9}, {3, -9}, {6, -5},
}

function Saucers.update(dt, shipX, shipY)
    if not saucer then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= SPAWN_INTERVAL then
            spawnTimer = 0
            -- Determine size based on score
            local size
            if World.score >= 40000 then
                size = "small"
            elseif World.score >= 10000 then
                size = math.random() < 0.6 and "small" or "large"
            else
                size = "large"
            end

            local fromLeft = math.random() < 0.5
            local def = DEFS[size]
            saucer = {
                x = fromLeft and -20 or (World.GAME_W + 20),
                y = math.random(80, World.GAME_H - 80),
                vx = (fromLeft and 1 or -1) * def.speed,
                vy = 0,
                size = size,
                radius = def.radius,
                points = def.points,
                fireTimer = def.fireRate * 0.5,
                fireRate = def.fireRate,
                altTimer = 1 + math.random() * 2,
                alive = true,
            }
        end
        return
    end

    local s = saucer

    -- Move
    s.x = s.x + s.vx * dt
    s.y = s.y + s.vy * dt
    s.y = World.wrapY(s.y)

    -- Altitude changes
    s.altTimer = s.altTimer - dt
    if s.altTimer <= 0 then
        s.altTimer = 1 + math.random() * 2
        s.vy = (math.random() - 0.5) * 200
    end

    -- Remove if off screen
    if (s.vx > 0 and s.x > World.GAME_W + 30) or (s.vx < 0 and s.x < -30) then
        saucer = nil
        return
    end

    -- Firing
    s.fireTimer = s.fireTimer - dt
    if s.fireTimer <= 0 then
        s.fireTimer = s.fireRate

        local angle
        if s.size == "large" then
            angle = math.random() * math.pi * 2
        else
            -- Aim at player with some error
            local dx, dy = World.wrappedDist(s.x, s.y, shipX, shipY)
            angle = math.atan2(dy, dx) + (math.random() - 0.5) * 0.35
        end

        Bullets.fire(s.x, s.y, angle, 0, 0, "saucer")
    end
end

function Saucers.get()
    return saucer
end

function Saucers.destroy()
    local points = saucer and saucer.points or 0
    local x, y = saucer.x, saucer.y
    saucer = nil
    return points, x, y
end

function Saucers.clear()
    saucer = nil
    spawnTimer = 0
end

function Saucers.isActive()
    return saucer ~= nil
end

local function drawShape(shape, ox, oy)
    local pts = {}
    for _, v in ipairs(shape) do
        table.insert(pts, v[1] + ox)
        table.insert(pts, v[2] + oy)
    end
    love.graphics.line(pts)
end

function Saucers.draw()
    if not saucer then return end
    local p = Palette.get()
    local lw = 1 / World.scale
    local t = love.timer.getTime()
    local pulse = 0.7 + math.sin(t * 10) * 0.3

    love.graphics.setColor(p.saucer[1], p.saucer[2], p.saucer[3], pulse)
    love.graphics.setLineWidth(lw * 1.5)

    if saucer.size == "large" then
        drawShape(SHAPE_LARGE, saucer.x, saucer.y)
        drawShape(SHAPE_LARGE_TOP, saucer.x, saucer.y)
        -- Centre line
        love.graphics.line(saucer.x - 10, saucer.y - 8, saucer.x + 10, saucer.y - 8)
    else
        drawShape(SHAPE_SMALL, saucer.x, saucer.y)
        drawShape(SHAPE_SMALL_TOP, saucer.x, saucer.y)
        love.graphics.line(saucer.x - 6, saucer.y - 5, saucer.x + 6, saucer.y - 5)
    end
end

return Saucers
