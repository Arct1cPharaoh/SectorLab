local track = require('track')

local MAX_WHEELS_OUTSIDE = 3 -- 4 wheels off = cut

local Timer = {}
Timer.__index = Timer

function Timer.new(startM, finishM)
    return setmetatable({
        startM = startM,
        finishM = finishM,
        state = 'waiting',
        runTime = 0,
        last = nil,
        best = nil,
        invalid = false,
    }, Timer)
end

function Timer:reset()
    self.state = 'waiting'
    self.runTime = 0
    self.invalid = false
end

-- Follow the rules
local function brokeRules()
    return track.wheelsOutside() > MAX_WHEELS_OUTSIDE
        or track.isColliding()
end

function Timer:startRun(cur)
    self.state = 'running'
    self.invalid = false
    self.runTime = track.overshoot(cur, self.startM)
end

function Timer:finishRun(cur)
    local t = self.runTime - track.overshoot(cur, self.finishM)
    self.state = 'waiting'

    if self.invalid then
        return t, true -- time, and this run was invalid
    end

    self.last = t
    if not self.best or t < self.best then
        self.best = t
    end

    return t, false
end

-- call every frame
function Timer:update(dt, prev, cur)
    if self.state == 'waiting' then
        if track.crossed(prev, cur, self.startM) then
            self:startRun()
        end
        return
    end

    self.runTime = self.runTime + dt
    if brokeRules() then
        self.invalid = true
    end

    if track.crossed(prev, cur, self.finishM) then
        return self:finishRun(cur)
    end
end

return Timer
