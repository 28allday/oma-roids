local World = require("game.world")
local Palette = require("rendering.palette")

local Particles = {}

local particles = {}

function Particles.spawnExplosion(x, y, count, speed, maxTime)
    count = count or 8
    speed = speed or 100
    maxTime = maxTime or 1.0

    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = speed * (0.3 + math.random() * 0.7)
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            timer = maxTime * (0.5 + math.random() * 0.5),
            maxTime = maxTime,
            ptype = "dot",
        })
    end
end

function Particles.spawnShipDeath(x, y, angle, vx, vy)
    -- Break ship into 3 line segments that drift apart
    local cos_a = math.cos(angle)
    local sin_a = math.sin(angle)

    local function transform(px, py)
        return px * cos_a - py * sin_a,
               px * sin_a + py * cos_a
    end

    -- Ship vertices
    local nose = {20, 0}
    local lwing = {-14, -12}
    local notch = {-8, 0}
    local rwing = {-14, 12}

    local segments = {
        {nose, lwing},
        {lwing, notch},
        {notch, rwing},
        {rwing, nose},
    }

    for _, seg in ipairs(segments) do
        local x1r, y1r = transform(seg[1][1], seg[1][2])
        local x2r, y2r = transform(seg[2][1], seg[2][2])
        local midX = (x1r + x2r) / 2
        local midY = (y1r + y2r) / 2

        local spread = 40 + math.random() * 40
        local sAngle = math.atan2(midY, midX) + (math.random() - 0.5) * 1.5

        table.insert(particles, {
            x = x + midX, y = y + midY,
            vx = vx * 0.3 + math.cos(sAngle) * spread,
            vy = vy * 0.3 + math.sin(sAngle) * spread,
            -- Line offsets from centre
            lx1 = x1r - midX, ly1 = y1r - midY,
            lx2 = x2r - midX, ly2 = y2r - midY,
            rotSpeed = (math.random() - 0.5) * 4,
            rot = 0,
            timer = 2.0,
            maxTime = 2.0,
            ptype = "line",
        })
    end
end

function Particles.update(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.timer = p.timer - dt
        if p.rot then p.rot = p.rot + (p.rotSpeed or 0) * dt end
        if p.timer <= 0 then
            table.remove(particles, i)
        end
    end
end

function Particles.anyActive()
    return #particles > 0
end

function Particles.clear()
    particles = {}
end

function Particles.draw()
    local pal = Palette.get()
    local lw = 1 / World.scale

    for _, p in ipairs(particles) do
        local alpha = math.max(0, p.timer / p.maxTime)

        if p.ptype == "dot" then
            love.graphics.setColor(pal.explosion[1], pal.explosion[2], pal.explosion[3], alpha)
            love.graphics.setLineWidth(lw)
            love.graphics.circle("fill", p.x, p.y, 1.2)
        elseif p.ptype == "line" then
            love.graphics.setColor(pal.ship[1], pal.ship[2], pal.ship[3], alpha)
            love.graphics.setLineWidth(lw * 2)
            local cos_r = math.cos(p.rot)
            local sin_r = math.sin(p.rot)
            local x1 = p.x + p.lx1 * cos_r - p.ly1 * sin_r
            local y1 = p.y + p.lx1 * sin_r + p.ly1 * cos_r
            local x2 = p.x + p.lx2 * cos_r - p.ly2 * sin_r
            local y2 = p.y + p.lx2 * sin_r + p.ly2 * cos_r
            love.graphics.line(x1, y1, x2, y2)
        end
    end
end

return Particles
