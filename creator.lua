local track = require('track')
local Packs = require('packs')

local sim = ac.getSim()
local Creator = {}

Creator.pack = nil -- New pack
Creator.pendingStart = nil
Creator.pendingFinish = nil

function Creator.newPack()
    Creator.pack = {
        name = 'New pack',
        track = Packs.trackID,
        sections = {},
    }
    Creator.pendingStart = nil
    Creator.pendingFinish = nil
end

function Creator.setStartHere()
    Creator.pendingStart = math.floor(track.trackM())
end

function Creator.setFinishHere()
    Creator.pendingFinish = math.floor(track.trackM())
end

function Creator.canAddSection()
    return Creator.pendingStart ~= nil
       and Creator.pendingFinish ~= nill
end

-- Length of the marked section
function Creator.pendingLength()
    local start, finish = Creator.pendingStart, Creator.pendingFinish
    return (finish - start) % sim.trackLengthM
end

function Creator.addSection()
    local sections = Creator.pack.sections
    table.insert(sections, {
        name = 'section ' .. (#sections + 1),
        start = Creator.pendingStart,
        finish = Creator.pendingFinish,
    })
    Creator.pendingStart = nil
    Creator.pendingFinish = nil
end

return Creator
