local World = require("game.world")
local Palette = require("rendering.palette")
local Fonts = require("rendering.fonts")
local Ship = require("game.ship")

local HUD = {}

function HUD.draw()
    local p = Palette.get()

    -- Pop out of game transform for crisp screen-space text
    love.graphics.pop()

    local font = Fonts.medium or love.graphics.getFont()
    love.graphics.setFont(font)
    local pad = 8

    -- Score (top left)
    love.graphics.setColor(p.hud)
    love.graphics.print(string.format("%06d", World.score), pad, pad)

    -- High score (top centre)
    if World.highScore > 0 then
        love.graphics.setFont(Fonts.small)
        love.graphics.setColor(p.dim)
        local hsText = string.format("%06d", World.highScore)
        local tw = Fonts.small:getWidth(hsText)
        love.graphics.print(hsText, (World.screenW - tw) / 2, pad)
    end

    -- Lives (small ship icons below score)
    local iconY = pad + font:getHeight() + 6
    local iconScale = 0.5
    local iconSpacing = 20
    for i = 1, math.min(World.lives, 10) do
        Ship.drawIcon(pad + 10 + (i-1) * iconSpacing, iconY + 8, iconScale)
    end

    -- Restore game transform
    love.graphics.push()
    love.graphics.translate(World.offsetX, World.offsetY)
    love.graphics.scale(World.scale)
end

return HUD
