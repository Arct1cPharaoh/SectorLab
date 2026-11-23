local track = require('track')

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
    }, Timer)
end

function Timer:reset()
    self.state = 'waiting'
    self.runTime = 0
end

-- call every frame; returns the time when a run finishes
function Timer:update(dt, prev, cur)
    if self.state == 'waiting' then
        if track.crossed(prev, cur, self.startM) then
            self.state = 'running'
            self.runTime = track.overshoot(cur, self.startM)
        end
    else
        self.runTime = self.runTime + dt

        if track.crossed(prev, cur, self.finishM) then
            local t = self.runTime - track.overshoot(cur, self.finishM)
            self.last = t

            if not self.best or t < self.best then
                self.best = t
            end

            self.state = 'waiting'
            return t
        end
    end
end

return Timer
