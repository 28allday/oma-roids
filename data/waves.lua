local Waves = {}

function Waves.get(wave)
    local counts = {4, 6, 8, 10, 11}
    local count = counts[math.min(wave, #counts)]
    local speedMult = 1.0 + (math.min(wave, 11) - 1) * 0.08
    return {
        asteroidCount = count,
        speedMultiplier = speedMult,
    }
end

return Waves
