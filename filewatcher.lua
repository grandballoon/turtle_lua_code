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

--[[
NOTES

Don't know why init is called init; it doesn't initialize the file, it just sets the last_modified time. Must
be dependent on an initialization pattern in another file.

Don't know why the same 'info' variable initialization happens in both methods.

So check_and_reset only checks and resets the modtime; it doesn't reset the file. It's a "reset yourself" message
to some other part of the codebase. OK, this file is less important than I thought, I will come back to it. I feel like
it could probably just be one function that returns true or false.

Steps:

]]