local sim = ac.getSim()
local track = require('track')
local Timer = require('timer')
local Packs = require('packs')


local packs = Packs.loadForTrack()
local currentPack = packs[1]
local selectedIndex = nil -- Which section is picked
local timers = {} -- One timer per section
local timer = nil -- Timer for the picked section

local prevM = nil
local RUN_UP_METRES = 200
local Controls = require('controls')
local GATE_HEIGHT = vec3(0, 2, 0)

local function fmt(t)
    return t and string.format('%.3f s', t) or '--'
end

local function teleportToSectionStart()
    if not timer then
        return
    end

    track.teleportCarTo(timer.startM - RUN_UP_METRES)
    timer:reset()
    prevM = nil
end

local function selectSection(index)
    local section = currentPack.sections[index]

    if not timers[index] then
        timers[index] = Timer.new(section.start, section.finish)
    end

    selectedIndex = index
    timer = timers[index]
    teleportToSectionStart()
end

-- Step through sections
local function stepSection(direction)
    if not currentPack then
        return
    end

    local count = #currentPack.sections

    if count == 0 then
        return
    end

    if not selectedIndex then
        selectSection(direction > 0 and 1 or count)
        return
    end

    selectSection((selectedIndex - 1 + direction) % count + 1)
end

-- Two posts and a top bar across the track
local function drawGate(distance, color)
    local leftEnd, rightEnd = track.gateEnds(distance)
    render.debugLine(leftEnd, leftEnd + GATE_HEIGHT, color)
    render.debugLine(rightEnd, rightEnd + GATE_HEIGHT, color)
    render.debugLine(leftEnd + GATE_HEIGHT, rightEnd + GATE_HEIGHT, color)
end

render.on('main.track.transparent', function()
    if not timer then
        return
    end

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

    if Controls.nextSection:pressed() then
        stepSection(1)
    end

    if Controls.previousSection:pressed() then
        stepSection(-1)
    end

    local cur = track.trackM()

    if prevM and timer then
        local t, invalid = timer:update(dt, prevM, cur)

        if t then
            if invalid then
                ac.setSystemMessage('SectorLab', 'Invalid run: ' .. fmt(t))
            else
                ac.setSystemMessage('SectorLab', 'Section: ' .. fmt(t))
            end
        end
    end

    prevM = cur
end

-- Draws the in game window
function script.windowMain(dt)
    if not currentPack then
        ui.text('No packs for track: ' .. Packs.trackID)
        if ui.button('Copy ID') then
            ac.setClipboardText(Packs.trackID)
            ac.setSystemMessage('SectorLab', 'Track ID copied!')
        end
        return
    end

    ui.text(currentPack.name)
    for index, section in ipairs(currentPack.sections) do
        if ui.selectable(section.name, index == selectedIndex) then
            selectSection(index)
        end
    end

    ui.separator()

    if not timer then
        ui.text('Pick a section')
        return
    end

    ui.text(string.format('Distance: %.0f m', track.trackM()))
    ui.text(string.format('Section: %d m to %d m',
        timer.startM, timer.finishM))

    if timer.state == 'running' then
        local invalidTag = timer.invalid and '  (INVALID)' or ''
        ui.text('Running: ' .. fmt(timer.runTime) .. invalidTag)
    else
        ui.text('Waiting for start gate')
    end

    ui.text('Last: ' .. fmt(timer.last))
    ui.text('Best: ' .. fmt(timer.best))

    -- Reset Logic
    if ui.button('Previous') then
        stepSection(-1)
    end

    ui.sameLine()
    if ui.button('Reset') then
        teleportToSectionStart()
    end

    ui.sameLine()
    if ui.button('Next') then
        stepSection(1)
    end
end

--Draws the setting window (the cog)
function script.windowSettings(dt)
    Controls.drawBindings()
end
