-- main.lua
local turtle = require "turtle"
local filewatcher = require "filewatcher"
local executor = require "executor"

-- ---------------------------------------------------------------------------
-- File management state
-- ---------------------------------------------------------------------------

-- current_filepath: absolute path to the file being watched and executed.
-- Set by (in priority order):
--   1. Drag-and-drop (user drops a .lua file onto the turtle window)
--   2. Adjacent file on startup (commands.lua next to the executable)
--   3. Fallback: LÖVE save directory (existing behavior)
local current_filepath = nil
local use_external = false  -- true when current_filepath is an absolute path

-- Fallback filename within the LÖVE save directory.
local sandboxed_filename = "commands.lua"

local runtime_log_filename = "runtime.log"

-- ---------------------------------------------------------------------------
-- Logging
-- ---------------------------------------------------------------------------

local function write_log(level, message)
    local line = ("[%0.3f] [%s] %s"):format(love.timer.getTime(), level, tostring(message))
    print(line)
    local ok, err = love.filesystem.append(runtime_log_filename, line .. "\n")
    if not ok then
        print(("[LOG-ERROR] failed to append %s: %s"):format(runtime_log_filename, tostring(err)))
    end
end

-- ---------------------------------------------------------------------------
-- Starter template for first-time users
-- ---------------------------------------------------------------------------

local starter = [[
-- commands.lua
-- Edit this file in any text editor. The app will auto-reload on save.
-- The turtle uses four basic commands: forward, back, left, and right.
-- (You can also type fd, bk, lt, and rt to save yourself typing.)
-- As a first challenge, try completing the square.

forward(100)
right(90)
forward(100)
]]

-- ---------------------------------------------------------------------------
-- Platform detection (for "Open in Editor" button)
-- ---------------------------------------------------------------------------

local platform = "unknown"

local function detect_platform()
    local os_name = love.system.getOS()
    if os_name == "OS X" then
        platform = "mac"
    elseif os_name == "Windows" then
        platform = "windows"
    elseif os_name == "Linux" then
        platform = "linux"
    end
end

-- Open a file in the system default editor.
local function open_in_editor(filepath)
    if not filepath then return end
    if platform == "mac" then
        os.execute('open "' .. filepath .. '"')
    elseif platform == "windows" then
        os.execute('start "" "' .. filepath .. '"')
    elseif platform == "linux" then
        os.execute('xdg-open "' .. filepath .. '"')
    end
end

-- ---------------------------------------------------------------------------
-- "Open in Editor" button
-- ---------------------------------------------------------------------------

local button = {
    text = "Open in Editor",
    margin = 10,
    padding_x = 12,
    padding_y = 6,
    -- Computed in love.load once we know window dimensions and font metrics.
    x = 0, y = 0, w = 0, h = 0,
}

local function compute_button_rect()
    local font = love.graphics.getFont()
    local tw = font:getWidth(button.text)
    local th = font:getHeight()
    button.w = tw + button.padding_x * 2
    button.h = th + button.padding_y * 2
    local ww = love.graphics.getWidth()
    button.x = ww - button.w - button.margin
    button.y = button.margin
end

local function draw_button()
    -- Background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.85)
    love.graphics.rectangle("fill", button.x, button.y, button.w, button.h, 4, 4)
    -- Border
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    love.graphics.rectangle("line", button.x, button.y, button.w, button.h, 4, 4)
    -- Label
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.print(button.text, button.x + button.padding_x, button.y + button.padding_y)
end

local function button_hit(mx, my)
    return mx >= button.x and mx <= button.x + button.w
       and my >= button.y and my <= button.y + button.h
end

-- ---------------------------------------------------------------------------
-- Display: show current file path at bottom of window
-- ---------------------------------------------------------------------------

local function draw_filepath_label()
    if not current_filepath then return end
    local font = love.graphics.getFont()
    local label = current_filepath
    local th = font:getHeight()
    local ww, wh = love.graphics.getDimensions()
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    love.graphics.print(label, button.margin, wh - th - button.margin)
end

-- ---------------------------------------------------------------------------
-- Sandbox environment
-- ---------------------------------------------------------------------------

local function make_sandbox_env()
    local env = {
        math     = math,
        ipairs   = ipairs,
        pairs    = pairs,
        tostring = tostring,
        tonumber = tonumber,
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
    env["goto"]  = function(...) return turtle.goto(turtle, ...) end
    env.teleport = function(...) return turtle.teleport(turtle, ...) end
    env.home     = function(...) return turtle.home(turtle, ...) end

    -- Speed
    env.speed          = function(...) return turtle.speed(turtle, ...) end
    env.set_move_speed = function(...) return turtle.set_move_speed(turtle, ...) end
    env.set_turn_speed = function(...) return turtle.set_turn_speed(turtle, ...) end

    return env
end

-- ---------------------------------------------------------------------------
-- File management
-- ---------------------------------------------------------------------------

-- Try to find commands.lua adjacent to the executable / .love / .app.
-- Returns the absolute path if found, or nil.
local function find_adjacent_example()
    -- love.filesystem.getSource() returns the path to the .love file or
    -- the directory containing main.lua. On a fused build, this is the
    -- directory containing the executable.
    local source = love.filesystem.getSource()

    -- If source points to a .love file, use its parent directory.
    -- If it's a directory already, use it directly.
    local dir
    if source:match("%.love$") or source:match("%.exe$") then
        dir = source:match("(.+)[/\\]")
    else
        dir = source
    end

    if not dir then return nil end

    -- On macOS, if we're inside a .app bundle, the source will be
    -- something like /path/to/App.app/Contents/Resources.
    -- We want to look next to the .app bundle, not inside it.
    local app_root = dir:match("(.+%.app)")
    if app_root then
        dir = app_root:match("(.+)[/\\]")
    end

    if not dir then return nil end

    local path = dir .. "/commands.lua"
    local f = io.open(path, "r")
    if f then
        f:close()
        return path
    end
    return nil
end

-- Set the app to watch and run a given file.
-- If external is true, the path is absolute and read via io.open.
-- If false, the path is relative to the LÖVE save directory.
local function watch_file(path, external)
    current_filepath = path
    use_external = external
    filewatcher.init(path, external)
    write_log("INFO", ("watching: %s (external: %s)"):format(path, tostring(external)))
end

-- Run the currently watched file.
local function run_current_file()
    if not current_filepath then return end

    turtle.reset()
    local env = make_sandbox_env()
    local ok, err
    if use_external then
        ok, err = executor.run_external(current_filepath, env)
    else
        ok, err = executor.run_file(current_filepath, env)
    end

    if not ok then
        write_log("ERROR", err)
    else
        write_log("INFO", ("ran %s"):format(current_filepath))
    end
end

-- If the sandboxed commands file doesn't exist, seed it with the starter.
local function ensure_sandboxed_file()
    if love.filesystem.getInfo(sandboxed_filename) then return end
    love.filesystem.write(sandboxed_filename, starter)
end

-- ---------------------------------------------------------------------------
-- LÖVE callbacks
-- ---------------------------------------------------------------------------

function love.load()
    love.window.setTitle("Turtle")
    love.graphics.setFont(love.graphics.newFont(14))
    love.filesystem.setIdentity("tlc-final")

    detect_platform()

    local save_dir = love.filesystem.getSaveDirectory()
    love.filesystem.write(runtime_log_filename, "")
    write_log("INFO", "session started")
    write_log("INFO", ("save dir: %s"):format(tostring(save_dir)))
    write_log("INFO", ("platform: %s"):format(platform))

    turtle.init()
    compute_button_rect()

    -- Priority 1: look for commands.lua adjacent to the executable.
    local adjacent = find_adjacent_example()
    if adjacent then
        watch_file(adjacent, true)
    else
        -- Priority 2: fall back to the LÖVE save directory.
        ensure_sandboxed_file()
        watch_file(sandboxed_filename, false)
    end

    run_current_file()
end

function love.update(dt)
    turtle.update(dt)
    if filewatcher.check_and_reset() then
        run_current_file()
    end
end

function love.draw()
    turtle.draw()
    draw_button()
    draw_filepath_label()
end

function love.mousepressed(mx, my, btn)
    if btn == 1 and button_hit(mx, my) then
        if use_external then
            open_in_editor(current_filepath)
        else
            -- For sandboxed files, open the save directory so the user
            -- can find the file. Construct the full path.
            local full = love.filesystem.getSaveDirectory() .. "/" .. current_filepath
            open_in_editor(full)
        end
    end
end

function love.filedropped(file)
    local path = file:getFilename()
    if not path:match("%.lua$") then
        write_log("WARN", "dropped file is not a .lua file, ignoring: " .. path)
        return
    end
    write_log("INFO", "file dropped: " .. path)
    watch_file(path, true)
    run_current_file()
end