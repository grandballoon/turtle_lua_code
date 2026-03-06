-- executor.lua
-- Loads and runs a user-provided Lua file inside a sandbox environment.
-- Errors are caught and returned to the caller rather than crashing the app.
--
-- Supports two modes:
--   run_file(filename, env)        — reads from the LÖVE sandbox (save dir)
--   run_external(filepath, env)    — reads from an absolute filesystem path

local executor = {}

-- Run a file from the LÖVE sandbox in the given environment.
-- Returns true on success, or false + an error message on failure.
function executor.run_file(filename, env)
    local code, read_err = love.filesystem.read(filename)
    if not code then
        return false, "read error: " .. tostring(read_err)
    end
    return executor.run_string(code, filename, env)
end

-- Run a file from an absolute filesystem path in the given environment.
-- Returns true on success, or false + an error message on failure.
function executor.run_external(filepath, env)
    local f, open_err = io.open(filepath, "r")
    if not f then
        return false, "read error: " .. tostring(open_err)
    end
    local code = f:read("*a")
    f:close()
    return executor.run_string(code, filepath, env)
end

-- Run a code string in the given environment.
-- Returns true on success, or false + an error message on failure.
function executor.run_string(code, name, env)
    local chunk, load_err = load(code, name or "user_code", "t", env)
    if not chunk then
        return false, "syntax error: " .. tostring(load_err)
    end

    local ok, run_err = pcall(chunk)
    if not ok then
        return false, "runtime error: " .. tostring(run_err)
    end

    return true
end

return executor