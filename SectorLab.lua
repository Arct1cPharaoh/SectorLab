local sim = ac.getSim()
local track = require('track')
local Timer = require('timer')

local timer = Timer.new(500, 900)
local prevM = nil

local function fmt(t)
    return t and string.format('%.3f s', t) or '--'
end

-- Runs every frame
function script.update(dt)
    if sim.isPaused then
        return
    end

    local cur = track.trackM()

    if prevM then
        local t = timer:update(dt, prevM, cur)

        if t then
            ac.setSystemMessage('SectorLab', 'Section: ' .. fmt(t))
        end
    end

    prevM = cur
end

-- Draws the in game window
function script.windowMain(dt)
    ui.text(string.format('Distance: %.0f m', track.trackM()))
    ui.text(string.format('Section: %d m to %d m', timer.startM, timer.finishM))

    if timer.state == 'running' then
        ui.text('Running: ' .. fmt(timer.runTime))
    else
        ui.text('Waiting for start gate')
    end

    ui.text('Last: ' .. fmt(timer.last))
    ui.text('Best: ' .. fmt(timer.best))
end
