local M = {}
local sim = ac.getSim()
local car = ac.getCar(0)

-- metres from the start line
function M.trackM()
    return car.splinePosition * sim.trackLengthM
end

-- Gate passed check
function M.crossed(prev, cur, gate)
    local len = sim.trackLengthM
    local step = (cur - prev) % len

    if step > 100 then
        return false
    end

    local toGate = (gate - prev) % len

    return toGate > 0 and toGate <= step
end

-- seconds since the car passes the gate
function M.overshoot(cur, gate)
    return ((cur - gate) % sim.trackLengthM) / math.max(car.speedMs, 1)
end

return M
