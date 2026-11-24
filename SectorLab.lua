local sim = ac.getSim()
local track = require('track')
local Timer = require('timer')

local timer = Timer.new(500, 900)
local prevM = nil
local RUN_UP_METERES = 200
local Controls = require('controls')
local GATE_HEIGHT = vec3(0, 2, 0)

local function fmt(t)
    return t and string.format('%.3f s', t) or '--'
end

local function teleportToSectionStart()
    track.teleportCarTo(timer.startM - RUN_UP_METERES)
    timer:reset()
    prevM = nil
end

-- Two posts and a top bar across the track
local function drawGate(distance, color)
    local leftEnd, rightEnd = track.gateEnds(distance)
    render.debugLine(leftEnd, leftEnd + GATE_HEIGHT, color)
    render.debugLine(rightEnd, rightEnd + GATE_HEIGHT, color)
    render.debugLine(leftEnd + GATE_HEIGHT, rightEnd + GATE_HEIGHT, color)
end

render.on('main.track.transparent', function()
    drawGate(timer.startM, rgbm.colors.lime) -- green start
    drawGate(timer.finishM, rgbm.colors.orange) -- orange finish
end)

-- Runs every frame
function script.update(dt)
    if sim.isPaused then
        return
    end

    if Controls.reset:pressed() then
        teleportToSectionStart()
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

    -- Reset Logic
    if ui.button("Reset") then
        teleportToSectionStart()
    end
end

--Draws the setting window (the cog)
function script.windowSettings(dt)
    Controls.drawBindings()
end
