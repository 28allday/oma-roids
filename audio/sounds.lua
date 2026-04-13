local Sounds = {}

local sources = {}
local SAMPLE_RATE = 44100

local function makeSoundData(duration, generator)
    local samples = math.floor(SAMPLE_RATE * duration)
    local sd = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)
    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        local p = i / samples
        local val = generator(t, p)
        sd:setSample(i, math.max(-1, math.min(1, val)))
    end
    return sd
end

local function makeSource(sd)
    return love.audio.newSource(sd, "static")
end

-- Sound generators

local function genBeat1(t, p)
    local env = (1 - p) ^ 4
    return math.sin(2 * math.pi * 80 * t) * env * 0.5
end

local function genBeat2(t, p)
    local env = (1 - p) ^ 4
    return math.sin(2 * math.pi * 100 * t) * env * 0.5
end

local function genThrust(t, p)
    local noise = (math.random() * 2 - 1) * 0.3
    local low = math.sin(2 * math.pi * 40 * t) * 0.2
    return (noise + low) * 0.4
end

local function genFire(t, p)
    local freq = 1500 - p * 1100
    local env = (1 - p) ^ 2
    return math.sin(2 * math.pi * freq * t) * env * 0.35
end

local function genExplodeLarge(t, p)
    local env = (1 - p) ^ 1.5
    local sine = math.sin(2 * math.pi * (50 + 30 * (1-p)) * t) * 0.5
    local noise = (math.random() * 2 - 1) * 0.5
    return (sine + noise) * env * 0.5
end

local function genExplodeMedium(t, p)
    local env = (1 - p) ^ 2
    local sine = math.sin(2 * math.pi * (80 + 40 * (1-p)) * t) * 0.4
    local noise = (math.random() * 2 - 1) * 0.4
    return (sine + noise) * env * 0.45
end

local function genExplodeSmall(t, p)
    local env = (1 - p) ^ 3
    local sine = math.sin(2 * math.pi * 150 * t) * 0.3
    local noise = (math.random() * 2 - 1) * 0.5
    return (sine + noise) * env * 0.4
end

local function genSaucerLarge(t, p)
    local freq = 200 + math.sin(2 * math.pi * 5 * t) * 50
    return math.sin(2 * math.pi * freq * t) * 0.25
end

local function genSaucerSmall(t, p)
    local freq = 350 + math.sin(2 * math.pi * 8 * t) * 80
    return math.sin(2 * math.pi * freq * t) * 0.25
end

local function genExtraLife(t, p)
    local freq
    if p < 0.33 then freq = 400
    elseif p < 0.66 then freq = 600
    else freq = 800 end
    local env = 0.7
    if p < 0.05 then env = p / 0.05 * 0.7 end
    if p > 0.9 then env = (1-p) / 0.1 * 0.7 end
    return math.sin(2 * math.pi * freq * t) * env * 0.35
end

local function genShipExplode(t, p)
    local freq = 500 * (1 - p * 0.7)
    local env = (1 - p) ^ 0.8
    local sine = math.sin(2 * math.pi * freq * t) * 0.4
    local noise = (math.random() * 2 - 1) * 0.3 * p
    local pulse = 0.7 + math.sin(2 * math.pi * 4 * t) * 0.3
    return (sine + noise) * env * pulse * 0.5
end

function Sounds.init()
    sources = {}
    local defs = {
        beat1          = {0.08, genBeat1},
        beat2          = {0.08, genBeat2},
        thrust         = {0.3,  genThrust},
        fire           = {0.05, genFire},
        explode_large  = {0.5,  genExplodeLarge},
        explode_medium = {0.3,  genExplodeMedium},
        explode_small  = {0.15, genExplodeSmall},
        saucer_large   = {0.4,  genSaucerLarge},
        saucer_small   = {0.4,  genSaucerSmall},
        extra_life     = {0.3,  genExtraLife},
        ship_explode   = {1.0,  genShipExplode},
    }
    for name, def in pairs(defs) do
        sources[name] = makeSource(makeSoundData(def[1], def[2]))
    end
end

function Sounds.play(name)
    local src = sources[name]
    if not src then return end
    src:clone():play()
end

return Sounds
