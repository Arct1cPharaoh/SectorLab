local sim = ac.getSim()
local car = ac.getCar(0)

local GATE_M = 500
local prevM = nil
local passes = 0

local function trackM()
    return car.splinePosition * sim.trackLengthM
end

-- Gate passed check
local function crossed(prev, cur, gate)
    local len = sim.trackLengthM
    local step = (cur - prev) % len

    if step > 100 then
        return false end

    local toGate = (gate - prev) % len

    return toGate > 0 and toGate <= step
end

-- Runs every frame
function script.update(dt)
    local cur = trackM()

    if prevM and crossed(prevM, cur, GATE_M) then
        passes = passes + 1
        ac.setSystemMessage('SectorLab', 'Gate passes!')
        ac.log('gate crossed at', cur)
    end

    prevM = cur
end

-- Draws the window
function script.windowMain(dt)
    local cur = trackM()
    local ahead = (GATE_M - cur) % sim.trackLengthM

    ui.text(string.format('Distance: %.0f m', cur))
    ui.text(string.format('Gate at %d m, %.0f m ahead', GATE_M, ahead))
    ui.text('Passes: ' .. passes)
end
