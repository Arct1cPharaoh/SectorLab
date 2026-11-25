local Packs = {}

local PACKS_FOLDER = __dirname .. '/packs'

-- This track's ID
Packs.trackID = ac.getTrackFullID('_')

local function readPack(path)
    local contents = io.load(path)

    if not contents then
        return nil
    end

    local ok, pack = pcall(JSON.parse, contents)

    if not ok or type(pack) ~= 'table' then
        ac.log('SectorLab: could not read ' .. path)
        return nil
    end

    return pack
end

-- Every pack in packs folder available for this track
function Packs.loadForTrack()
    local found = {}
    local fileNames = io.scanDir(PACKS_FOLDER, '*.json') or {}

    for _, fileName in ipairs(fileNames) do
        local pack = readPack(PACKS_FOLDER .. '/' .. fileName)

        if pack and pack.track == Packs.trackID then
            table.insert(found, pack)
        end
    end

    return found
end

return Packs
