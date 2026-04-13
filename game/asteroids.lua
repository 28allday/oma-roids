local World = require("game.world")
local Palette = require("rendering.palette")

local Asteroids = {}

local active = {}
local shapes = { large = {}, medium = {}, small = {} }

local SIZES = {
    large  = { radius = 45, minSpeed = 40, maxSpeed = 80, points = 20 },
    medium = { radius = 22, minSpeed = 60, maxSpeed = 120, points = 50 },
    small  = { radius = 11, minSpeed = 80, maxSpeed = 160, points = 100 },
}

local NUM_VARIANTS = 5
local NUM_VERTICES = 12

local function generateShape(baseRadius)
    local verts = {}
    for i = 1, NUM_VERTICES do
        local angle = (i - 1) / NUM_VERTICES * math.pi * 2
        angle = angle + (math.random() - 0.5) * 0.3
        local r = baseRadius * (0.7 + math.random() * 0.6)
        table.insert(verts, {math.cos(angle) * r, math.sin(angle) * r})
    end
    return verts
end

function Asteroids.init()
    for size, info in pairs(SIZES) do
        shapes[size] = {}
        for i = 1, NUM_VARIANTS do
            shapes[size][i] = generateShape(info.radius)
        end
    end
    active = {}
end

function Asteroids.spawnWave(wave)
    local Waves = require("data.waves")
    local config = Waves.get(wave)
    local count = config.asteroidCount
    local speedMult = config.speedMultiplier

    for i = 1, count do
        -- Spawn at edges, not near centre
        local x, y
        repeat
            x = math.random(0, World.GAME_W)
            y = math.random(0, World.GAME_H)
        until math.abs(x - World.GAME_W/2) > 150 or math.abs(y - World.GAME_H/2) > 150

        local angle = math.random() * math.pi * 2
        local speed = (SIZES.large.minSpeed + math.random() * (SIZES.large.maxSpeed - SIZES.large.minSpeed)) * speedMult

        table.insert(active, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            rot = 0,
            rotSpeed = (math.random() - 0.5) * 3,
            size = "large",
            shapeIdx = math.random(1, NUM_VARIANTS),
            radius = SIZES.large.radius,
        })
    end
end

function Asteroids.update(dt)
    for _, a in ipairs(active) do
        a.x = World.wrapX(a.x + a.vx * dt)
        a.y = World.wrapY(a.y + a.vy * dt)
        a.rot = a.rot + a.rotSpeed * dt
    end
end

function Asteroids.destroy(idx)
    local a = active[idx]
    if not a then return nil end

    local result = {
        x = a.x, y = a.y,
        size = a.size,
        points = SIZES[a.size].points,
    }

    -- Spawn children
    local childSize = nil
    if a.size == "large" then childSize = "medium"
    elseif a.size == "medium" then childSize = "small"
    end

    if childSize then
        local info = SIZES[childSize]
        for c = 1, 2 do
            local angle = math.random() * math.pi * 2
            local speed = info.minSpeed + math.random() * (info.maxSpeed - info.minSpeed)
            table.insert(active, {
                x = a.x, y = a.y,
                vx = math.cos(angle) * speed,
                vy = math.sin(angle) * speed,
                rot = 0,
                rotSpeed = (math.random() - 0.5) * 3,
                size = childSize,
                shapeIdx = math.random(1, NUM_VARIANTS),
                radius = info.radius,
            })
        end
    end

    table.remove(active, idx)
    return result
end

function Asteroids.count()
    return #active
end

function Asteroids.getAll()
    return active
end

function Asteroids.clear()
    active = {}
end

local function drawAsteroidAt(a, ox, oy)
    local shape = shapes[a.size][a.shapeIdx]
    if not shape then return end

    local pts = {}
    local cos_r = math.cos(a.rot)
    local sin_r = math.sin(a.rot)

    for _, v in ipairs(shape) do
        local rx = v[1] * cos_r - v[2] * sin_r + ox
        local ry = v[1] * sin_r + v[2] * cos_r + oy
        table.insert(pts, rx)
        table.insert(pts, ry)
    end
    -- Close the loop
    table.insert(pts, pts[1])
    table.insert(pts, pts[2])
    love.graphics.line(pts)
end

function Asteroids.draw()
    local p = Palette.get()
    local lw = 1 / World.scale

    love.graphics.setColor(p.asteroid)
    love.graphics.setLineWidth(lw * 1.5)

    local W, H = World.GAME_W, World.GAME_H

    for _, a in ipairs(active) do
        drawAsteroidAt(a, a.x, a.y)
        -- Wrap ghosts
        if a.x < a.radius then drawAsteroidAt(a, a.x + W, a.y) end
        if a.x > W - a.radius then drawAsteroidAt(a, a.x - W, a.y) end
        if a.y < a.radius then drawAsteroidAt(a, a.x, a.y + H) end
        if a.y > H - a.radius then drawAsteroidAt(a, a.x, a.y - H) end
    end
end

return Asteroids
