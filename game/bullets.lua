local World = require("game.world")
local Palette = require("rendering.palette")

local Bullets = {}

local active = {}
local BULLET_SPEED = 600
local BULLET_LIFETIME = 0.667
local MAX_PLAYER_BULLETS = 4

function Bullets.fire(x, y, angle, shipVx, shipVy, owner)
    if owner == "player" then
        local count = 0
        for _, b in ipairs(active) do
            if b.owner == "player" then count = count + 1 end
        end
        if count >= MAX_PLAYER_BULLETS then return false end
    end

    table.insert(active, {
        x = x, y = y,
        vx = shipVx + math.cos(angle) * BULLET_SPEED,
        vy = shipVy + math.sin(angle) * BULLET_SPEED,
        timer = BULLET_LIFETIME,
        owner = owner or "player",
    })
    return true
end

function Bullets.update(dt)
    for i = #active, 1, -1 do
        local b = active[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.timer = b.timer - dt

        -- Bullets don't wrap — remove when out of bounds or expired
        if b.timer <= 0 or b.x < -5 or b.x > World.GAME_W + 5 or
           b.y < -5 or b.y > World.GAME_H + 5 then
            table.remove(active, i)
        end
    end
end

function Bullets.getAll()
    return active
end

function Bullets.remove(idx)
    table.remove(active, idx)
end

function Bullets.clear()
    active = {}
end

function Bullets.draw()
    local p = Palette.get()
    local lw = 1 / World.scale

    for _, b in ipairs(active) do
        if b.owner == "player" then
            love.graphics.setColor(p.bullet)
        else
            love.graphics.setColor(p.saucer)
        end
        love.graphics.setLineWidth(lw * 2)
        love.graphics.circle("fill", b.x, b.y, 1.5)
    end
end

return Bullets
