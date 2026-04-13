local World = require("game.world")
local Palette = require("rendering.palette")

local Ship = {}

local ROTATION_SPEED = 4.712  -- ~270 deg/sec
local THRUST_ACCEL = 300
local MAX_SPEED = 400
local INVULN_TIME = 3.0
local HYPER_COOLDOWN = 0.5
local COLLISION_RADIUS = 14

-- Ship shape vertices (pointing right at angle=0)
local SHAPE = {
    {20, 0},      -- nose
    {-14, -12},   -- left wing
    {-8, 0},      -- rear notch
    {-14, 12},    -- right wing
}

local ship = {}

function Ship.init()
    ship.x = World.GAME_W / 2
    ship.y = World.GAME_H / 2
    ship.vx = 0
    ship.vy = 0
    ship.angle = -math.pi / 2  -- pointing up
    ship.alive = true
    ship.invulnerable = true
    ship.invulnTimer = INVULN_TIME
    ship.thrustOn = false
    ship.hyperCooldown = 0
end

function Ship.get()
    return ship
end

function Ship.update(dt)
    if not ship.alive then return end

    ship.invulnTimer = math.max(0, ship.invulnTimer - dt)
    if ship.invulnTimer <= 0 then ship.invulnerable = false end
    ship.hyperCooldown = math.max(0, ship.hyperCooldown - dt)

    -- Rotation
    if love.keyboard.isDown("left", "a") then
        ship.angle = ship.angle - ROTATION_SPEED * dt
    end
    if love.keyboard.isDown("right", "d") then
        ship.angle = ship.angle + ROTATION_SPEED * dt
    end

    -- Thrust
    ship.thrustOn = love.keyboard.isDown("up", "w")
    if ship.thrustOn then
        ship.vx = ship.vx + math.cos(ship.angle) * THRUST_ACCEL * dt
        ship.vy = ship.vy + math.sin(ship.angle) * THRUST_ACCEL * dt
        -- Cap speed
        local speed = math.sqrt(ship.vx * ship.vx + ship.vy * ship.vy)
        if speed > MAX_SPEED then
            ship.vx = ship.vx / speed * MAX_SPEED
            ship.vy = ship.vy / speed * MAX_SPEED
        end
    end

    -- Move and wrap
    ship.x = World.wrapX(ship.x + ship.vx * dt)
    ship.y = World.wrapY(ship.y + ship.vy * dt)
end

function Ship.die()
    ship.alive = false
end

function Ship.respawn()
    ship.x = World.GAME_W / 2
    ship.y = World.GAME_H / 2
    ship.vx = 0
    ship.vy = 0
    ship.angle = -math.pi / 2
    ship.alive = true
    ship.invulnerable = true
    ship.invulnTimer = INVULN_TIME
end

function Ship.hyperspace()
    if ship.hyperCooldown > 0 or not ship.alive then return false end
    ship.hyperCooldown = HYPER_COOLDOWN

    -- 25% chance of death
    if math.random() < 0.25 then
        return true  -- signal death
    end

    ship.x = math.random(50, World.GAME_W - 50)
    ship.y = math.random(50, World.GAME_H - 50)
    ship.vx = 0
    ship.vy = 0
    return false
end

function Ship.getCollider()
    return ship.x, ship.y, COLLISION_RADIUS
end

local function transformPoint(px, py, angle, cx, cy)
    local cos_a = math.cos(angle)
    local sin_a = math.sin(angle)
    return cx + px * cos_a - py * sin_a,
           cy + px * sin_a + py * cos_a
end

function Ship.getVertices()
    local verts = {}
    for _, v in ipairs(SHAPE) do
        local wx, wy = transformPoint(v[1], v[2], ship.angle, ship.x, ship.y)
        table.insert(verts, {wx, wy})
    end
    return verts
end

function Ship.draw()
    if not ship.alive then return end

    -- Blink when invulnerable
    if ship.invulnerable and math.floor(ship.invulnTimer * 8) % 2 == 0 then
        return
    end

    local p = Palette.get()
    local lw = 1 / World.scale

    local verts = Ship.getVertices()

    -- Draw ship outline
    love.graphics.setColor(p.ship)
    love.graphics.setLineWidth(lw * 2)
    local pts = {}
    for _, v in ipairs(verts) do
        table.insert(pts, v[1])
        table.insert(pts, v[2])
    end
    table.insert(pts, verts[1][1])
    table.insert(pts, verts[1][2])
    love.graphics.line(pts)

    -- Thrust flame
    if ship.thrustOn then
        local flicker = 0.6 + math.random() * 0.4
        love.graphics.setColor(p.thrust[1], p.thrust[2], p.thrust[3], flicker)
        love.graphics.setLineWidth(lw * 1.5)

        local flameLen = 8 + math.random() * 8
        local fx, fy = transformPoint(-8, 0, ship.angle, ship.x, ship.y)
        local fl, fl2 = transformPoint(-8, -4, ship.angle, ship.x, ship.y)
        local fr, fr2 = transformPoint(-8, 4, ship.angle, ship.x, ship.y)
        local ft, ft2 = transformPoint(-8 - flameLen, 0, ship.angle, ship.x, ship.y)

        love.graphics.line(fl, fl2, ft, ft2, fr, fr2)
    end
end

-- Draw a small ship icon for lives display
function Ship.drawIcon(cx, cy, scale)
    local p = Palette.get()
    local lw = 1
    love.graphics.setColor(p.ship)
    love.graphics.setLineWidth(lw)

    local pts = {}
    for _, v in ipairs(SHAPE) do
        local rx = cx + v[1] * scale
        local ry = cy + v[2] * scale
        table.insert(pts, rx)
        table.insert(pts, ry)
    end
    table.insert(pts, pts[1])
    table.insert(pts, pts[2])
    love.graphics.line(pts)
end

return Ship
