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

local Creator = require('creator')
local MIN_SECTION_METRES = 50
local mode = 'play'

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

-- Switch Play mode to a different oack
local function usePack(pack)
    currentPack = pack
    timers = {}
    timer = nil
    selectedIndex = nil
end

-- Two posts and a top bar across the track
local function drawGate(distance, color)
    local leftEnd, rightEnd = track.gateEnds(distance)
    render.debugLine(leftEnd, leftEnd + GATE_HEIGHT, color)
    render.debugLine(rightEnd, rightEnd + GATE_HEIGHT, color)
    render.debugLine(leftEnd + GATE_HEIGHT, rightEnd + GATE_HEIGHT, color)
end

local function drawCreatorGates()
    for _, section in ipairs(Creator.pack.sections) do
        drawGate(section.start, rgbm.colors.gray)
        drawGate(section.finish, rgbm.colors.gray)
    end

    if Creator.pendingStart then
        drawGate(Creator.pendingStart, rgbm.colors.lime)
    end

    if Creator.pendingFinish then
        drawGate(Creator.pendingFinish, rgbm.colors.orange)
    end
end

render.on('main.track.transparent', function()
    if mode == 'create' then
        drawCreatorGates()
        return
    end

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

    if mode == 'create' then
        if Controls.setStart:pressed() then
            Creator.setStartHere()
        end

        if Controls.setFinish:pressed() then
            Creator.setFinishHere()
        end
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

-- Draws the in game window in play mode
local function drawPlayWindow()
    if not currentPack then
        ui.text('No packs for track: ' .. Packs.trackID)
        if ui.button('Copy ID') then
            ac.setClipboardText(Packs.trackID)
            ac.setSystemMessage('SectorLab', 'Track ID copied!')
        end
        return
    end

    ui.text('Packs:')
    for _, pack in ipairs(packs) do
        if ui.selectable(pack.name, pack == currentPack) then
            usePack(pack)
        end
    end
    ui.separator()

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

local function gateText(distance)
    return distance and string.format('%d m', distance) or 'not set'
end

local function drawCreateWindow()
    Creator.pack.name = ui.inputText('Pack name', Creator.pack.name)
    ui.text(string.format('Car at: %.0f m', track.trackM()))
    ui.separator()

    ui.text('Start: ' .. gateText(Creator.pendingStart))
    ui.sameLine()

    if ui.button('Set start here') then
        Creator.setStartHere()
    end

    ui.text('Finish: ' .. gateText(Creator.pendingFinish))
    ui.sameLine()

    if ui.button('Set finish here') then
        Creator.setFinishHere()
    end

    if Creator.canAddSection() then
        if Creator.pendingLength() < MIN_SECTION_METRES then
            ui.text('Warning: section is very short!')
        end

        if ui.button('Add section') then
            Creator.addSection()
        end
    end

    ui.separator()
    for index, section in ipairs(Creator.pack.sections) do
        ui.text(string.format('%d. %s (%d m to %d m)',
            index, section.name, section.start, section.finish))
    end

    local hasSections = #Creator.pack.sections > 0
    if hasSections and ui.button('Save pack') then
        if Packs.save(Creator.pack) then
            packs = Packs.loadForTrack()
            ac.setSystemMessage('SectorLab', 'Saved ' .. Creator.pack.name)
        else
            ac.setSystemMessage('SectorLab', 'Could not save pack')
        end
    end

    local hasSections = #Creator.pack.sections > 0
    if hasSections and ui.button('Try pack in Play') then
        usePack(Creator.pack)
        mode = 'play'
    end
end

-- renders window in game
function script.windowMain(dt)
    if ui.button('play') then
        mode = 'Play'
    end

    ui.sameLine()

    if ui.button('Create') then
        mode = 'create'
        
        if not Creator.pack then
            Creator.newPack()
        end
    end

    ui.separator()

    if mode == 'create' then
        drawCreateWindow()
    else
        drawPlayWindow()
    end
end

--Draws the setting window (the cog)
function script.windowSettings(dt)
    Controls.drawBindings()
end
