-- Palette auto-detected from current Omarchy system theme
local Palette = {}

local theme = {}

local function hexToRGB(hex)
    hex = hex:gsub("#", "")
    return {
        tonumber(hex:sub(1,2), 16) / 255,
        tonumber(hex:sub(3,4), 16) / 255,
        tonumber(hex:sub(5,6), 16) / 255,
    }
end

function Palette.loadFromSystem()
    local path = os.getenv("HOME") .. "/.config/omarchy/current/theme/ghostty.conf"
    local f = io.open(path, "r")
    if not f then
        theme.bg = {0, 0, 0}
        theme.fg = {1, 1, 1}
        theme.accent = {1, 1, 1}
        for i = 0, 15 do theme["color" .. i] = {i/15, i/15, i/15} end
        theme.dim = theme.color8
        return
    end

    for line in f:lines() do
        local key, val = line:match("^(%S+)%s*=%s*(#%x+)")
        if key and val then
            if key == "background" then theme.bg = hexToRGB(val)
            elseif key == "foreground" then theme.fg = hexToRGB(val)
            elseif key == "cursor-color" then theme.accent = hexToRGB(val)
            end
        end
        local idx, hex = line:match("^palette%s*=%s*(%d+)=(#%x+)")
        if idx and hex then theme["color" .. idx] = hexToRGB(hex) end
    end
    f:close()

    theme.dim = theme.color8 or theme.color0 or {0.2, 0.2, 0.2}
    for i = 0, 15 do
        if not theme["color" .. i] then theme["color" .. i] = theme.fg or {1, 1, 1} end
    end
    if not theme.bg then theme.bg = {0, 0, 0} end
    if not theme.fg then theme.fg = {1, 1, 1} end
    if not theme.accent then theme.accent = theme.color12 or theme.fg end
end

function Palette.get()
    return {
        bg        = theme.bg,
        fg        = theme.fg,
        ship      = theme.fg,
        asteroid  = theme.color4,
        bullet    = theme.fg,
        saucer    = theme.color2 or theme.color3,
        thrust    = theme.accent,
        explosion = theme.accent,
        dim       = theme.dim,
        bright    = theme.accent,
        hud       = theme.fg,
        grid      = theme.color0,
    }
end

function Palette.raw()
    return theme
end

return Palette
