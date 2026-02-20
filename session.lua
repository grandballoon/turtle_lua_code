-- session.lua
-- Owns a long-lived sandbox environment and execution flow for user code.

local turtle = require "turtle"
local executor = require "executor"

local session = {}
session.__index = session

local function starts_with(s, prefix)
    return type(s) == "string" and s:sub(1, #prefix) == prefix
end

local function make_sandbox_env(log)
    local env = {
        math = math,
        ipairs = ipairs,
        pairs = pairs,
        tostring = tostring,
        tonumber = tonumber,
    }

    env.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        log("USER", table.concat(parts, "\t"))
    end

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

    return env
end

function session.new(opts)
    opts = opts or {}

    local self = setmetatable({}, session)
    self.log = opts.log or function() end
    self.env = make_sandbox_env(self.log)

    return self
end

-- Script profile:
-- Rebuilds sandbox and turtle state so each run reflects only the current file.
function session:run_file_fresh(filename)
    if not love.filesystem.getInfo(filename) then
        return nil, ("file not found: %s"):format(filename)
    end

    turtle.reset()
    self.env = make_sandbox_env(self.log)

    executor.interrupt_all()
    local entry, err = executor.run_file(filename, self.env)
    if not entry then
        return nil, err
    end

    self.log("INFO", ("started script run: %s"):format(filename))
    return entry
end

-- REPL profile:
-- Keeps a persistent sandbox and turtle state between runs.
function session:run_file_persistent(filename)
    if not love.filesystem.getInfo(filename) then
        return nil, ("file not found: %s"):format(filename)
    end

    executor.interrupt_all()
    local entry, err = executor.run_file(filename, self.env)
    if not entry then
        return nil, err
    end

    self.log("INFO", ("started repl file run: %s"):format(filename))
    return entry
end

function session:run_chunk_persistent(code, chunk_name)
    local name = chunk_name or "repl_chunk"
    executor.interrupt_all()
    local entry, err = executor.run_string(code, name, self.env)
    if not entry then
        return nil, err
    end

    self.log("INFO", ("started repl chunk: %s"):format(name))
    return entry
end

function session:update(dt)
    local msgs = executor.update(dt)
    for i = 1, #msgs do
        local msg = msgs[i]
        if starts_with(msg, "error") then
            self.log("ERROR", msg)
        elseif starts_with(msg, "warning") then
            self.log("WARN", msg)
        elseif starts_with(msg, "finished") then
            self.log("INFO", msg)
        end
    end
end

return session
