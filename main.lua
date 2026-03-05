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
-- example.lua
-- Edit this file in any text editor. The app will auto-reload on save.
-- The turtle uses four basic commands: forward, back, left, and right.
-- (You can also type fd, bk, lt, and rt to save yourself typing.)
-- As a first challenge, try completing the square.

forward(100)
right(90)
forward(100)
]]

local function make_sandbox_env()
    local env = {
        math     = math,
        ipairs   = ipairs,
        pairs    = pairs,
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

    -- Movement
    env.forward  = function(...) return turtle.forward(turtle, ...) end
    env.back     = function(...) return turtle.back(turtle, ...) end
    env.left     = function(...) return turtle.left(turtle, ...) end
    env.right    = function(...) return turtle.right(turtle, ...) end
    env.fd = env.forward
    env.bk = env.back
    env.lt = env.left
    env.rt = env.right

    -- Pen
    env.penup    = function(...) return turtle.penup(turtle, ...) end
    env.pendown  = function(...) return turtle.pendown(turtle, ...) end
    env.pencolor = function(...) return turtle.pencolor(turtle, ...) end
    env.pensize  = function(...) return turtle.pensize(turtle, ...) end

    -- Canvas
    env.bgcolor  = function(...) return turtle.bgcolor(turtle, ...) end
    env.clear    = function(...) return turtle.reset(turtle, ...) end
    env.reset    = function(...) return turtle.reset(turtle, ...) end

    -- Navigation
    env.circle   = function(...) return turtle.circle(turtle, ...) end
    env.goto     = function(...) return turtle.goto(turtle, ...) end
    env.teleport = function(...) return turtle.teleport(turtle, ...) end
    env.home     = function(...) return turtle.home(turtle, ...) end

    -- Speed
    env.speed          = function(...) return turtle.speed(turtle, ...) end
    env.set_move_speed = function(...) return turtle.set_move_speed(turtle, ...) end
    env.set_turn_speed = function(...) return turtle.set_turn_speed(turtle, ...) end

    return env
end

-- If the commands file doesn't exist, seed it with the starter template.
local function ensure_commands_file()
    if love.filesystem.getInfo(commands_filename) then return end
    love.filesystem.write(commands_filename, starter)
end

-- Reset the turtle, then load and run the commands file in a fresh sandbox.
local function run_commands_file()
    if not love.filesystem.getInfo(commands_filename) then return end

    turtle.reset()

    local env = make_sandbox_env()
    local ok, err = executor.run_file(commands_filename, env)
    if not ok then
        write_log("ERROR", err)
    else
        write_log("INFO", ("started %s"):format(commands_filename))
    end
end

-- ===== LÖVE callbacks =====

function love.load()
    love.window.setTitle("Turtle")
    love.graphics.setFont(love.graphics.newFont(14))
    love.filesystem.setIdentity("tlc-final")

    local save_dir = love.filesystem.getSaveDirectory()
    love.filesystem.write(runtime_log_filename, "")
    write_log("INFO", "session started")
    write_log("INFO", ("save dir: %s"):format(tostring(save_dir)))

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
end

function love.draw()
    turtle.draw()
end