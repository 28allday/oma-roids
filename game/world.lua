local World = {
    GAME_W = 1024,
    GAME_H = 768,
    visibleH = 768,
    scale = 1,
    offsetX = 0,
    offsetY = 0,
    state = "title",
    wave = 1,
    score = 0,
    highScore = 0,
    lives = 3,
    nextExtraLife = 10000,
    gameOverTimer = 0,
    screenW = 0,
    screenH = 0,
    respawnTimer = 0,
    waveTimer = 0,
}

function World.resize(w, h)
    if not w or not h then w, h = love.graphics.getDimensions() end
    World.screenW = w
    World.screenH = h
    World.scale = w / World.GAME_W
    World.visibleH = h / World.scale
    World.offsetX = 0
    World.offsetY = h - (World.GAME_H * World.scale)
end

function World.ensureScale()
    local w, h = love.graphics.getDimensions()
    if w ~= World.screenW or h ~= World.screenH then
        World.resize(w, h)
        local Fonts = require("rendering.fonts")
        Fonts.init(World.scale)
    end
end

function World.toGame(sx, sy)
    local gx = (sx - World.offsetX) / World.scale
    local gy = (sy - World.offsetY) / World.scale
    return gx, gy
end

function World.toScreen(gx, gy)
    return gx * World.scale + World.offsetX, gy * World.scale + World.offsetY
end

function World.visibleTop()
    return World.GAME_H - World.visibleH
end

function World.wrapX(x)
    return (x % World.GAME_W + World.GAME_W) % World.GAME_W
end

function World.wrapY(y)
    return (y % World.GAME_H + World.GAME_H) % World.GAME_H
end

function World.wrappedDist(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    if math.abs(dx) > World.GAME_W / 2 then
        dx = dx - World.GAME_W * (dx > 0 and 1 or -1)
    end
    if math.abs(dy) > World.GAME_H / 2 then
        dy = dy - World.GAME_H * (dy > 0 and 1 or -1)
    end
    return dx, dy, math.sqrt(dx*dx + dy*dy)
end

function World.addScore(points)
    World.score = World.score + points
    while World.score >= World.nextExtraLife do
        World.lives = World.lives + 1
        World.nextExtraLife = World.nextExtraLife + 10000
    end
    if World.score > World.highScore then
        World.highScore = World.score
    end
end

return World
