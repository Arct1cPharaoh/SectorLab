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

-- Wold position of racing line at a certain distance
function M.worldPositionAt(distance)
    local progress = (distance % sim.trackLengthM) / sim.trackLengthM
    return ac.trackProgressToWorldCoordinate(progress)
end

-- Move car to a position on the track facing forward
function M.teleportCarTo(distance)
    local position = M.worldPositionAt(distance)
    local slightlyAhead = M.worldPositionAt(distance + 2)
    -- Wants the reversed direction for some reason.
    local direction = (position - slightlyAhead):normalize()
    -- Justice rains from above!
    local liftedPosition = position + vec3(0, 0.5, 0)

    physics.setCarPosition(0, liftedPosition, direction)
end

return M
