-- main.lua
local turtle = require "turtle"
local filewatcher = require "filewatcher"
local session = require "session"

-- User-editable commands live in the LÖVE save directory.
-- This makes them easy to locate and safe to write on all platforms.
local commands_filename = "example.lua"
local runtime_log_filename = "runtime.log"

local function write_log(level, message)
    local line = ("[%0.3f] [%s] %s"):format(love.timer.getTime(), level, tostring(message))
    print(line)
    local ok, err = love.filesystem.append(runtime_log_filename, line .. "\n")
    if not ok then
        print(("[LOG-ERROR] failed to append %s: %s"):format(runtime_log_filename, tostring(err)))
    end
end

local starter = [[
-- commands.lua
-- Edit this file in any text editor.
-- Tip: click "Open Folder" in the overlay to find this file quickly.
-- F5 runs this file.
-- F6 toggles save behavior: auto_run vs notify_only.
-- The turtle uses four basic commands: forward, back, left, and right
-- (You can just type fd, bk, lt, and rt to save yourself typing, but you do need the parentheses.)
-- As a first challenge, try completing the square.

forward(100)
right(90)
forward(100)
]]

local runtime = nil
local trigger_mode = "notify_only" -- "notify_only" | "auto_run"
local pending_file_change = false

-- if the file exists, return it. If not, populate a started file and create it.
local function ensure_commands_file()
    if love.filesystem.getInfo(commands_filename) then return end

    -- Seed a friendly starter file.

    love.filesystem.write(commands_filename, starter)
end

local function run_commands_file()
    if not love.filesystem.getInfo(commands_filename) then
        return
    end

    local entry, err = runtime:run_file_fresh(commands_filename)
    if not entry then
        write_log("ERROR", ("failed to run %s: %s"):format(commands_filename, tostring(err)))
        return false
    end
    pending_file_change = false
    return true
end

local function toggle_trigger_mode()
    if trigger_mode == "notify_only" then
        trigger_mode = "auto_run"
    else
        trigger_mode = "notify_only"
    end
    write_log("INFO", ("trigger mode: %s"):format(trigger_mode))
end

-- ===== LÖVE callbacks =====

function love.load()
    love.window.setTitle("LOVE Turtle — file-driven")
    love.graphics.setFont(love.graphics.newFont(14))

    -- Set a stable save identity so logs always go to a known directory.
    love.filesystem.setIdentity("tlc-final")

    local save_dir = love.filesystem.getSaveDirectory()
    local ok, err = love.filesystem.write(runtime_log_filename, "")
    if not ok then
        print(("[LOG-ERROR] failed to create %s: %s"):format(runtime_log_filename, tostring(err)))
    end
    write_log("INFO", "session started")
    write_log("INFO", ("save dir: %s"):format(tostring(save_dir)))
    write_log("INFO", ("log file: %s/%s"):format(tostring(save_dir), runtime_log_filename))

    turtle.init()
    runtime = session.new({ log = write_log })
    write_log("INFO", ("trigger mode: %s (F5 run, F6 toggle)"):format(trigger_mode))

    ensure_commands_file()
    filewatcher.init(commands_filename)

    run_commands_file()
end

function love.update(dt)
    turtle.update(dt)

    if filewatcher.check_and_reset() then
        pending_file_change = true
        write_log("INFO", ("detected changes in %s"):format(commands_filename))
        if trigger_mode == "auto_run" then
            run_commands_file()
        else
            write_log("INFO", "run pending (press F5)")
        end
    end

    runtime:update(dt)
end

function love.keypressed(key)
    if key == "f5" then
        run_commands_file()
    elseif key == "f6" then
        toggle_trigger_mode()
        if trigger_mode == "auto_run" and pending_file_change then
            run_commands_file()
        end
    end
end


function love.draw()
    turtle.draw()
end
