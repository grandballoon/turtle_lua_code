-- main.lua
local turtle = require "turtle"
local filewatcher = require "filewatcher"
local executor = require "executor"

-- User-editable commands live in the LÖVE save directory.
-- This makes them easy to locate and safe to write on all platforms.
local commands_filename = "example.lua"
local runtime_log_filename = "runtime.log"

local function starts_with(s, prefix)
    return type(s) == "string" and s:sub(1, #prefix) == prefix
end

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
-- Edit this file in any text editor. The app will auto-reload on save.
-- Tip: click "Open Folder" in the overlay to find this file quickly.
-- The turtle uses four basic commands: forward, back, left, and right
-- (You can just type fd, bk, lt, and rt to save yourself typing, but you do need the parentheses.)
-- As a first challenge, try completing the square.

forward(100)
right(90)
forward(100)
]]

-- 
local function make_sandbox_env()
    --[[ 
    Lua libraries
    ]]
    local env = {
        math = math,
        ipairs = ipairs,
        pairs = pairs,
        tostring = tostring,
        tonumber = tonumber,
        -- NOTE: we intentionally do not expose os/io/debug by default.
    }

    env.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        write_log("USER", table.concat(parts, "\t"))
    end
   
    --[[
    Turtle API:
        - movement commands (forward, back, left, right)

        - penup
        - pendown
        - clear
        - reset
        - set_move_speed
        - set_turn_speed
        - pencolor
        - bgcolor
        - pensize
        - speed
        
    ]]
    env.forward = function(...) return turtle.forward(turtle, ...) end
    env.back = function(...) return turtle.back(turtle, ...) end
    env.left = function(...) return turtle.left(turtle, ...) end
    env.right = function(...) return turtle.right(turtle, ...) end
    env.fd = env.forward
    env.bk = env.back
    env.lt = env.left
    env.rt = env.right

    env.penup = function(...) return turtle.penup(turtle, ...) end
    env.pendown = function(...) return turtle.pendown(turtle, ...) end
    env.clear = function(...) return turtle.reset(turtle, ...) end
    env.reset = function(...) return turtle.reset(turtle, ...) end
    env.set_move_speed = function(...) return turtle.set_move_speed(turtle, ...) end
    env.set_turn_speed = function(...) return turtle.set_turn_speed(turtle, ...) end
    env.pencolor = function(...) return turtle.pencolor(turtle, ...) end
    env.bgcolor = function(...) return turtle.bgcolor(turtle, ...) end
    env.pensize = function(...) return turtle.pensize(turtle, ...) end
    env.speed = function(...) return turtle.speed(turtle, ...) end
    env.circle = function(...) return turtle.circle(turtle, ...) end

    return env
end

-- if the file exists, return it. If not, populate a started file and create it.
local function ensure_commands_file()
    if love.filesystem.getInfo(commands_filename) then return end

    -- Seed a friendly starter file.
    
    love.filesystem.write(commands_filename, starter)
end

-- get the command file, stop all commands, reset the canvas, make a new sandbox, and then run the commands, capturing errors
-- and logs.
local function run_commands_file()
    if not love.filesystem.getInfo(commands_filename) then
        return
    end

    -- Stop any currently running user code, reset turtle and clear canvas
    executor.interrupt_all()
    turtle.reset() -- this line/pattern will need to be changed in order to allow the user to think through multiple executions

    local env = make_sandbox_env()
    local entry, err = executor.run_file(commands_filename, env)
    if not entry then
        write_log("ERROR", ("failed to run %s: %s"):format(commands_filename, tostring(err)))
    else
        write_log("INFO", ("started %s"):format(commands_filename))
    end
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

    ensure_commands_file()
    filewatcher.init(commands_filename)

    run_commands_file()
end

function love.update(dt)
    turtle.update(dt)

    if filewatcher.check_and_reset() then
        run_commands_file()
    end
-- call the executor's update file to... what?
    local msgs = executor.update(dt)
    for i = 1, #msgs do
        local msg = msgs[i]
        if starts_with(msg, "error") then
            write_log("ERROR", msg)
        elseif starts_with(msg, "warning") then
            write_log("WARN", msg)
        elseif starts_with(msg, "finished") then
            write_log("INFO", msg)
        end
    end
end


function love.draw()
    turtle.draw()
end

--[[
NOTES

This structure has the pattern of preferring to re-run the entire commands file.
Every time it does that, it also clears the canvas, resets the turtle, and recreates
the entire sandbox environment—the latter of which, at the very least, seems wasteful.

The behavior of the canvas and the turtle should be determined by the turtle commands,
not the renderer. The user should be able to decide whether to reset (by using the reset command)
or whether to simply add to the existing drawing. We shouldn't need to reset the turtle every time
we want to make a change—only when we want to reset the turtle.

That's a job for the turtle.draw() method, not for every execution of the command list.
]]
