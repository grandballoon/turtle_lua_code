-- filewatcher.lua
-- minimal implementation: watches a single file

local filewatcher = {}

local last_modified = 0
local filename = nil


function filewatcher.init(file)
    filename = file
    local info = love.filesystem.getInfo(filename)
    -- if the file exists, return its modtime, or 0
    last_modified = info and info.modtime or 0
end

function filewatcher.check_and_reset()
    -- filename must have been set in order for anything to happen
    if not filename then return false end
    local info = love.filesystem.getInfo(filename)
    if not info then return false end
    if info.modtime > last_modified then
        last_modified = info.modtime
        return true
    end
    return false
end

return filewatcher
