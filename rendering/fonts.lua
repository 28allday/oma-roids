local Fonts = {}

Fonts.small = nil
Fonts.medium = nil
Fonts.large = nil
Fonts.currentH = 0
Fonts.fontPath = nil
Fonts.fontData = nil

function Fonts.detectSystemFont()
    local home = os.getenv("HOME")
    local f = io.open(home .. "/.config/waybar/style.css", "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    local fontName = content:match("font%-family:%s*[\"']?([^;\"']+)")
    if not fontName then return nil end
    fontName = fontName:match("^%s*(.-)%s*$")
    local handle = io.popen('fc-match "' .. fontName .. '" --format="%{file}"')
    if not handle then return nil end
    local path = handle:read("*a")
    handle:close()
    if path and path ~= "" then
        local test = io.open(path, "r")
        if test then test:close(); return path end
    end
    return nil
end

function Fonts.init(scale)
    local h = love.graphics.getHeight()
    if h == Fonts.currentH then return end
    Fonts.currentH = h

    if not Fonts.fontPath then
        Fonts.fontPath = Fonts.detectSystemFont() or false
    end
    if Fonts.fontPath and not Fonts.fontData then
        local f = io.open(Fonts.fontPath, "rb")
        if f then
            local data = f:read("*a")
            f:close()
            Fonts.fontData = love.filesystem.newFileData(data, "systemfont.ttf")
        else
            Fonts.fontPath = false
        end
    end

    local sS = math.max(10, math.floor(h * 0.018))
    local sM = math.max(12, math.floor(h * 0.025))
    local sL = math.max(16, math.floor(h * 0.045))

    if Fonts.fontData then
        Fonts.small = love.graphics.newFont(Fonts.fontData, sS)
        Fonts.medium = love.graphics.newFont(Fonts.fontData, sM)
        Fonts.large = love.graphics.newFont(Fonts.fontData, sL)
    else
        Fonts.small = love.graphics.newFont(sS)
        Fonts.medium = love.graphics.newFont(sM)
        Fonts.large = love.graphics.newFont(sL)
    end
end

return Fonts
