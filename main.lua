-- main.lua
local turtle = require "turtle"
local filewatcher = require "filewatcher"
local executor = require "executor"

-- User-editable commands live in the LÖVE save directory.
-- This makes them easy to locate and safe to write on all platforms.
local commands_filename = "example.lua"

local output_lines = {}
local run_on_startup = true
local show_overlay = true
local overlay_timeout = 8
local last_message_time = 0

local function push_log(line)
    table.insert(output_lines, line)
    while #output_lines > 300 do table.remove(output_lines, 1) end
    print(line)
    last_message_time = love and love.timer and love.timer.getTime() or os.time()
end

-- Simple button strip for the overlay
local buttons = {}

local function add_button(id, label, on_click)
    table.insert(buttons, { id = id, label = label, on_click = on_click, x = 0, y = 0, w = 0, h = 0 })
end

local function _url_encode_path(path)
    -- Minimal encoding for spaces; good enough for typical save paths.
    return (path:gsub(' ', '%%20'))
end

local function open_commands_folder()
    local dir = love.filesystem.getSaveDirectory()
    local url = 'file://' .. _url_encode_path(dir)
    local ok = love.system.openURL(url)
    if not ok then push_log('Could not open folder: ' .. dir) end
end

local function open_commands_file()
    local dir = love.filesystem.getSaveDirectory()
    local sep = package.config:sub(1,1) -- path separator
    local full = dir .. sep .. commands_filename
    local url = 'file://' .. _url_encode_path(full)
    local ok = love.system.openURL(url)
    if not ok then push_log('Could not open file: ' .. full) end
end


local function make_sandbox_env()
    local env = {
        print = function(...)
            local t = {}
            for i = 1, select("#", ...) do table.insert(t, tostring(select(i, ...))) end
            push_log(table.concat(t, " "))
        end,
        math = math,
        ipairs = ipairs,
        pairs = pairs,
        tostring = tostring,
        tonumber = tonumber,
        -- NOTE: we intentionally do not expose os/io/debug by default.
    }

    env.forward = function(...) return turtle.forward(turtle, ...) end
    env.back = function(...) return turtle.back(turtle, ...) end
    env.left = function(...) return turtle.left(turtle, ...) end
    env.right = function(...) return turtle.right(turtle, ...) end
    -- Shorthand aliases
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

local function ensure_commands_file()
    if love.filesystem.getInfo(commands_filename) then return end

    -- Seed a friendly starter file.
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
    love.filesystem.write(commands_filename, starter)
end

local function run_commands_file()
    if not love.filesystem.getInfo(commands_filename) then
        push_log(("commands file not found: %s"):format(commands_filename))
        return
    end

    -- Stop any currently running user code, reset turtle and clear canvas
    executor.interrupt_all()
    turtle.reset()

    local env = make_sandbox_env()
    local entry, err = executor.run_file(commands_filename, env)
    if not entry then
        push_log("Load error: " .. tostring(err))
    else
        push_log("Started: " .. commands_filename)
    end
end

-- ===== LÖVE callbacks =====

function love.load()
    love.window.setTitle("LOVE Turtle — file-driven")
    love.graphics.setFont(love.graphics.newFont(14))

    turtle.init()

    ensure_commands_file()
    filewatcher.init(commands_filename)

    -- buttons (top overlay)
    add_button("run", "Run", function() run_commands_file() end)
    add_button("open_folder", "Open Folder", function() open_commands_folder() end)
    add_button("open_file", "Open File", function() open_commands_file() end)

    if run_on_startup then run_commands_file() end
end

function love.update(dt)
    turtle.update(dt)

    if filewatcher.check_and_reset() then
        push_log("File change detected: " .. commands_filename)
        run_commands_file()
    end

    local msgs = executor.update(dt)
    for _, m in ipairs(msgs) do push_log(m) end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end
    -- buttons are always clickable when overlay is shown
    for _, b in ipairs(buttons) do
        if x >= b.x and x <= (b.x + b.w) and y >= b.y and y <= (b.y + b.h) then
            if b.on_click then b.on_click() end
            return
        end
    end
end


function love.keypressed(key)
    -- Toggle overlay visibility
    if key == "f1" then
        show_overlay = not show_overlay
        return
    end

    -- Keyboard shortcut: Ctrl/Cmd+R runs commands.lua
    local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    local cmd  = love.keyboard.isDown("lgui") or love.keyboard.isDown("rgui") -- macOS command key
    local mod  = ctrl or cmd
    if mod and key == "r" then
        run_commands_file()
    end
end


function love.draw()
    turtle.draw()

    local w, h = love.graphics.getDimensions()

    if show_overlay then
        -- Top bar with buttons
        local bar_h = 34
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.rectangle("fill", 8, 8, w - 16, bar_h)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.rectangle("line", 8, 8, w - 16, bar_h)

        local bx = 14
        local by = 12
        local pad = 10

        for _, b in ipairs(buttons) do
            local tw = love.graphics.getFont():getWidth(b.label)
            b.w = tw + 18
            b.h = 22
            b.x = bx
            b.y = by

            love.graphics.setColor(1, 1, 1, 0.12)
            love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 4, 4)
            love.graphics.setColor(1, 1, 1, 0.85)
            love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 4, 4)
            love.graphics.print(b.label, b.x + 9, b.y + 3)

            bx = bx + b.w + pad
        end

        -- Log panel (recent messages)
        local now = love.timer.getTime()
        local alpha = 1
        if overlay_timeout and overlay_timeout > 0 then
            local age = now - last_message_time
            if age > overlay_timeout then alpha = 0 end
        end

        if alpha > 0 then
            local panel_h = 130
            love.graphics.setColor(0, 0, 0, 0.60 * alpha)
            love.graphics.rectangle("fill", 8, 8 + bar_h + 8, 520, panel_h)
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.rectangle("line", 8, 8 + bar_h + 8, 520, panel_h)

            local y = 14 + bar_h + 8
            local start_line = math.max(1, #output_lines - 6)
            for i = start_line, #output_lines do
                love.graphics.print(output_lines[i], 16, y)
                y = y + 18
            end
        end
    end


end