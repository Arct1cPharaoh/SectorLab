local Packs = {}

local PACKS_FOLDER = __dirname .. '/packs'

-- This track's ID
Packs.trackID = ac.getTrackFullID('_')

local function readPack(path, fileName)
    local contents = io.load(path)

    if not contents then
        return nil
    end

    local ok, pack = pcall(JSON.parse, contents)

    if not ok or type(pack) ~= 'table' then
        ac.log('SectorLab: could not read ' .. path)
        return nil
    end

    pack.fileName = fileName
    return pack
end

-- Every pack in packs folder available for this track
function Packs.loadForTrack()
    local found = {}
    local fileNames = io.scanDir(PACKS_FOLDER, '*.json') or {}

    for _, fileName in ipairs(fileNames) do
        local path = PACKS_FOLDER .. '/' .. fileName
        local pack = readPack(path, fileName)

        if pack and pack.track == Packs.trackID then
            table.insert(found, pack)
        end
    end

    return found
end

local function fileNameFor(pack)
    local safeName = pack.name:gsub('[^%w%-_]', '_')
    return safeName .. '.json'
end

-- Write a pack to the packs folder, overwriting its old file
function Packs.save(pack)
    pack.fileName = pack.fileName or fileNameFor(pack)

    -- only pack data goes in the file, not fileName
    local data = {
        name = pack.name,
        track = pack.track,
        sections = pack.sections,
    }

    io.createDir(PACKS_FOLDER)
    local path = PACKS_FOLDER .. '/' .. pack.fileName
    return io.save(path, JSON.stringify(data))
end

return Packs
