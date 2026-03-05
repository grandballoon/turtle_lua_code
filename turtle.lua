-- turtle.lua
local turtle = {
    -- position & rendering
    x = 400, y = 300, angle = 0,
    penDown = true,
    penColor = {1, 1, 1, 1},
    bgColor = {0.07, 0.07, 0.07, 1},
    penSize = 2,

    canvas = nil,
    msaa = 4,

    -- animation queue
    actions = {},       -- queued actions
    current = nil,      -- current action being animated
    -- base speeds (when speed_setting == 1)
    base_move_speed = 100,  -- px/sec at speed 1
    base_turn_speed = 180,  -- deg/sec at speed 1
    -- user-facing speed setting (0..10)
    speed_setting = 5,
    -- stored segments (for export/debug)
    segments = {}
}

-- ---------------------------------------------------------------------------
-- Named color palette
-- All values are LÖVE-native 0..1 RGBA. Alpha defaults to 1.
-- ---------------------------------------------------------------------------
local COLORS = {
    -- basics
    white        = {1,     1,     1,     1},
    black        = {0,     0,     0,     1},
    red          = {1,     0,     0,     1},
    green        = {0,     0.8,   0,     1},
    blue         = {0,     0,     1,     1},
    yellow       = {1,     1,     0,     1},
    orange       = {1,     0.55,  0,     1},
    purple       = {0.6,   0,     0.8,   1},
    pink         = {1,     0.41,  0.71,  1},
    brown        = {0.55,  0.27,  0.07,  1},
    gray         = {0.5,   0.5,   0.5,   1},
    grey         = {0.5,   0.5,   0.5,   1},  -- alias

    -- reds / pinks
    crimson      = {0.86,  0.08,  0.24,  1},
    coral        = {1,     0.50,  0.31,  1},
    salmon       = {0.98,  0.50,  0.45,  1},
    hotpink      = {1,     0.41,  0.71,  1},
    deeppink     = {1,     0.08,  0.58,  1},
    magenta      = {1,     0,     1,     1},
    maroon       = {0.5,   0,     0,     1},

    -- oranges / yellows
    gold         = {1,     0.84,  0,     1},
    khaki        = {0.94,  0.90,  0.55,  1},
    peach        = {1,     0.85,  0.73,  1},
    lightyellow  = {1,     1,     0.88,  1},

    -- greens
    lime         = {0,     1,     0,     1},
    limegreen    = {0.20,  0.80,  0.20,  1},
    forestgreen  = {0.13,  0.55,  0.13,  1},
    darkgreen    = {0,     0.39,  0,     1},
    olive        = {0.5,   0.5,   0,     1},
    teal         = {0,     0.5,   0.5,   1},
    mint         = {0.60,  1,     0.60,  1},
    sage         = {0.56,  0.74,  0.56,  1},

    -- blues
    cyan         = {0,     1,     1,     1},
    skyblue      = {0.53,  0.81,  0.98,  1},
    ["sky blue"] = {0.53,  0.81,  0.98,  1},  -- space variant
    steelblue    = {0.27,  0.51,  0.71,  1},
    royalblue    = {0.25,  0.41,  0.88,  1},
    navy         = {0,     0,     0.5,   1},
    dodgerblue   = {0.12,  0.56,  1,     1},
    turquoise    = {0.25,  0.88,  0.82,  1},
    indigo       = {0.29,  0,     0.51,  1},

    -- purples
    violet       = {0.93,  0.51,  0.93,  1},
    lavender     = {0.71,  0.49,  0.86,  1},
    plum         = {0.87,  0.63,  0.87,  1},
    orchid       = {0.85,  0.44,  0.84,  1},

    -- neutrals
    silver       = {0.75,  0.75,  0.75,  1},
    lightgray    = {0.83,  0.83,  0.83,  1},
    lightgrey    = {0.83,  0.83,  0.83,  1},
    darkgray     = {0.25,  0.25,  0.25,  1},
    darkgrey     = {0.25,  0.25,  0.25,  1},
    charcoal     = {0.21,  0.27,  0.31,  1},
    cream        = {1,     0.99,  0.82,  1},
    ivory        = {1,     1,     0.94,  1},
    beige        = {0.96,  0.96,  0.86,  1},
}

-- Resolve a color argument to a {r,g,b,a} table in 0..1 space.
-- Accepts:
--   "red"            -> named color lookup (case-insensitive)
--   r, g, b [, a]    -> raw numbers, already 0..1
-- Returns nil if the name is not found, so callers can warn.
local function resolve_color(r, g, b, a)
    if type(r) == "string" then
        local entry = COLORS[r] or COLORS[r:lower()]
        if not entry then
            return nil  -- unknown name; caller should log a warning
        end
        -- return a copy so callers can't mutate the palette
        return {entry[1], entry[2], entry[3], entry[4]}
    end

    -- numeric path: values expected in 0..1
    a = (type(a) == "number") and math.max(0, math.min(1, a)) or 1
    r = (type(r) == "number") and math.max(0, math.min(1, r)) or 1
    g = (type(g) == "number") and math.max(0, math.min(1, g)) or 1
    b = (type(b) == "number") and math.max(0, math.min(1, b)) or 1
    return {r, g, b, a}
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

function turtle.init()
    local w, h = love.graphics.getDimensions()
    turtle.canvas = love.graphics.newCanvas(w, h, {msaa = turtle.msaa})
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")
    turtle.reset()
end

function turtle.reset()
    turtle.x = 400
    turtle.y = 300
    turtle.angle = 0
    turtle.penDown = true
    turtle.penColor = {1, 1, 1, 1}
    turtle.bgColor = {0.07, 0.07, 0.07, 1}
    turtle.penSize = 2
    turtle.actions = {}
    turtle.current = nil
    turtle.segments = {}

    if turtle.canvas then
        love.graphics.setCanvas(turtle.canvas)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setCanvas()
    end
end

-- ---------------------------------------------------------------------------
-- Speed helpers
-- ---------------------------------------------------------------------------

function turtle.speed(self, n)
    if type(n) ~= "number" then return end
    self.speed_setting = math.max(0, math.min(10, n))
end

local function move_speed_for(t)
    if t.speed_setting == 0 then return math.huge end
    return t.base_move_speed * t.speed_setting
end

local function turn_speed_for(t)
    if t.speed_setting == 0 then return math.huge end
    return t.base_turn_speed * t.speed_setting
end

-- ---------------------------------------------------------------------------
-- Public API — all state changes are enqueued so they fire in order
-- ---------------------------------------------------------------------------

function turtle.forward(self, dist)
    table.insert(self.actions, { type="move", remaining = dist or 0, distance = dist or 0 })
end

function turtle.back(self, dist)
    turtle.forward(self, -(dist or 0))
end

function turtle.right(self, ang)
    table.insert(self.actions, { type="turn", remaining = ang or 0, angle = ang or 0 })
end

function turtle.left(self, ang)
    turtle.right(self, -(ang or 0))
end

-- penup / pendown / pensize are now queued so they respect animation order
function turtle.penup(self)
    table.insert(self.actions, { type="penup" })
end

function turtle.pendown(self)
    table.insert(self.actions, { type="pendown" })
end

function turtle.pensize(self, s)
    if type(s) == "number" then
        table.insert(self.actions, { type="pensize", size = s })
    end
end

function turtle.pencolor(self, r, g, b, a)
    table.insert(self.actions, { type="pencolor", r = r, g = g, b = b, a = a })
end

function turtle.bgcolor(self, r, g, b, a)
    table.insert(self.actions, { type="bgcolor", r = r, g = g, b = b, a = a })
end

-- circle(radius): positive radius = counter-clockwise, negative = clockwise.
-- Approximated as 360 steps of fd(r * 2π / 360) + rt(1), which is the same
-- idiom learners already use in sample_code/left_right_circle.lua — just
-- automated and smooth. A dedicated action type keeps the queue short.
function turtle.circle(self, radius)
    radius = radius or 50
    table.insert(self.actions, {
        type      = "circle",
        radius    = radius,
        steps     = 360,        -- one degree per step
        remaining = 360,        -- steps left
        -- step geometry computed once here, reused each update tick
        step_dist = math.abs(radius) * 2 * math.pi / 360,
        step_turn = (radius >= 0) and -1 or 1,  -- negative radius = clockwise
    })
end

function turtle.set_move_speed(self, v) self.base_move_speed = tonumber(v) or self.base_move_speed end
function turtle.set_turn_speed(self, v) self.base_turn_speed = tonumber(v) or self.base_turn_speed end

-- ---------------------------------------------------------------------------
-- Internal queue management
-- ---------------------------------------------------------------------------

local function start_next(t)
    if t.current then return end
    local nxt = table.remove(t.actions, 1)
    if nxt then
        nxt.started = true
        if nxt.type == "move" then
            nxt.start_x = t.x
            nxt.start_y = t.y
        end
        t.current = nxt
    end
end

-- ---------------------------------------------------------------------------
-- Update: consume instant actions first, then animate one timed action
-- ---------------------------------------------------------------------------

-- Actions that resolve in zero time (no animation needed).
local INSTANT = {
    penup    = true,
    pendown  = true,
    pensize  = true,
    pencolor = true,
    bgcolor  = true,
}

function turtle.update(dt)
    -- Drain all instant actions before advancing any animation.
    while true do
        start_next(turtle)
        local a = turtle.current
        if not a then return end
        if not INSTANT[a.type] then break end

        if a.type == "penup" then
            turtle.penDown = false

        elseif a.type == "pendown" then
            turtle.penDown = true

        elseif a.type == "pensize" then
            turtle.penSize = a.size

        elseif a.type == "pencolor" then
            local c = resolve_color(a.r, a.g, a.b, a.a)
            if c then
                turtle.penColor = c
            else
                -- unknown color name: silently keep current color
                -- (a future version could surface this to the learner)
            end

        elseif a.type == "bgcolor" then
            local c = resolve_color(a.r, a.g, a.b, a.a)
            if c then turtle.bgColor = c end
        end

        turtle.current = nil
    end

    local a = turtle.current

    -- ---- move ----
    if a.type == "move" then
        local speed = move_speed_for(turtle)
        local dir   = (a.remaining >= 0) and 1 or -1
        local step  = (speed == math.huge) and a.remaining or (speed * dt * dir)
        if math.abs(step) > math.abs(a.remaining) then step = a.remaining end

        local rad = math.rad(turtle.angle)
        turtle.x = turtle.x + math.cos(rad) * step
        turtle.y = turtle.y + math.sin(rad) * step
        a.remaining = a.remaining - step

        if math.abs(a.remaining) < 1e-6 then
            if turtle.penDown then
                local sx, sy = a.start_x or turtle.x, a.start_y or turtle.y
                table.insert(turtle.segments, {sx, sy, turtle.x, turtle.y, turtle.penColor, turtle.penSize})
                love.graphics.setCanvas(turtle.canvas)
                love.graphics.setBlendMode("alpha")
                love.graphics.setLineWidth(turtle.penSize)
                love.graphics.setColor(turtle.penColor)
                love.graphics.line(sx, sy, turtle.x, turtle.y)
                love.graphics.setCanvas()
                love.graphics.setBlendMode("alpha")
            end
            turtle.current = nil
        end

    -- ---- turn ----
    elseif a.type == "turn" then
        local speed = turn_speed_for(turtle)
        local dir   = (a.remaining >= 0) and 1 or -1
        local step  = (speed == math.huge) and a.remaining or (speed * dt * dir)
        if math.abs(step) > math.abs(a.remaining) then step = a.remaining end

        turtle.angle  = (turtle.angle + step) % 360
        a.remaining   = a.remaining - step

        if math.abs(a.remaining) < 1e-6 then turtle.current = nil end

    -- ---- circle ----
    -- Each update tick advances as many 1-degree steps as the current speed
    -- allows. The step geometry (arc length + turn) was computed at enqueue
    -- time so we don't repeat the trig here.
    elseif a.type == "circle" then
        local speed      = move_speed_for(turtle)   -- px/sec governs arc speed
        local arc_per_sec = speed                    -- px of arc per second
        local px_per_step = a.step_dist             -- px of arc per 1-degree step

        -- How many steps can we consume this frame?
        local steps_this_frame
        if speed == math.huge then
            steps_this_frame = a.remaining
        else
            steps_this_frame = math.floor((arc_per_sec * dt) / px_per_step)
            steps_this_frame = math.max(1, steps_this_frame)  -- at least 1 per frame
        end
        steps_this_frame = math.min(steps_this_frame, a.remaining)

        for _ = 1, steps_this_frame do
            local rad = math.rad(turtle.angle)
            local nx  = turtle.x + math.cos(rad) * a.step_dist
            local ny  = turtle.y + math.sin(rad) * a.step_dist

            if turtle.penDown then
                table.insert(turtle.segments, {turtle.x, turtle.y, nx, ny, turtle.penColor, turtle.penSize})
                love.graphics.setCanvas(turtle.canvas)
                love.graphics.setBlendMode("alpha")
                love.graphics.setLineWidth(turtle.penSize)
                love.graphics.setColor(turtle.penColor)
                love.graphics.line(turtle.x, turtle.y, nx, ny)
                love.graphics.setCanvas()
                love.graphics.setBlendMode("alpha")
            end

            turtle.x     = nx
            turtle.y     = ny
            turtle.angle = (turtle.angle + a.step_turn) % 360
            a.remaining  = a.remaining - 1
        end

        if a.remaining <= 0 then turtle.current = nil end

    else
        -- Unknown action type: drop it rather than stalling the queue.
        turtle.current = nil
    end
end

-- ---------------------------------------------------------------------------
-- Draw
-- ---------------------------------------------------------------------------

function turtle.draw()
    love.graphics.clear(turtle.bgColor)

    if turtle.canvas then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(turtle.canvas, 0, 0)
    end

    -- Preview the in-progress move so animation looks smooth between commits.
    if turtle.current and turtle.current.type == "move" and turtle.penDown then
        local a = turtle.current
        local sx = a.start_x or turtle.x
        local sy = a.start_y or turtle.y
        love.graphics.setBlendMode("alpha")
        love.graphics.setLineWidth(turtle.penSize)
        love.graphics.setColor(turtle.penColor)
        love.graphics.line(sx, sy, turtle.x, turtle.y)
    end

    -- Turtle head: small filled triangle pointing in the direction of travel.
    love.graphics.push()
    love.graphics.translate(turtle.x, turtle.y)
    love.graphics.rotate(math.rad(turtle.angle))
    local s = 10
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.polygon("fill", s, 0, -s * 0.6, s * 0.6, -s * 0.6, -s * 0.6)
    love.graphics.pop()
end

-- ---------------------------------------------------------------------------
-- Utilities
-- ---------------------------------------------------------------------------

function turtle.get_segments() return turtle.segments end

-- Expose the color table so external tooling (e.g. a color picker UI) can
-- enumerate valid names without duplicating the list.
function turtle.color_names()
    local names = {}
    for k in pairs(COLORS) do table.insert(names, k) end
    table.sort(names)
    return names
end

return turtle
