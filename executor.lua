-- executor.lua
-- Loads and runs a user-provided Lua file inside a sandbox environment.
-- Errors are caught and returned to the caller rather than crashing the app.

local executor = {}

-- Run a file in the given sandbox environment.
-- Returns true on success, or false + an error message on failure.
-- Two failure modes are distinguished:
--   "syntax error"  — the file couldn't be compiled (bad Lua syntax)
--   "runtime error" — the file ran but threw an error during execution
function executor.run_file(filename, env)
    local code, read_err = love.filesystem.read(filename)
    if not code then
        return false, "read error: " .. tostring(read_err)
    end

    local chunk, load_err = load(code, filename, "t", env)
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