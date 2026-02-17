-- main.lua
local turtle = require "turtle"
local filewatcher = require "filewatcher"
local executor = require "executor"

-- User-editable commands live in the LÖVE save directory.
-- This makes them easy to locate and safe to write on all platforms.
local commands_filename = "example.lua"

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
    env.pensize = function(...) return turtle.pensize(turtle, ...) end
    env.speed = function(...) return turtle.speed(turtle, ...) end

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
end

-- ===== LÖVE callbacks =====

function love.load()
    love.window.setTitle("LOVE Turtle — file-driven")
    love.graphics.setFont(love.graphics.newFont(14))

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