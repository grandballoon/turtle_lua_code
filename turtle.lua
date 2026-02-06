-- turtle.lua
local turtle = {
    -- position & rendering
    x = 400, y = 300, angle = 0,
    penDown = true,
    penColor = {1,1,1,1},
    penSize = 2,

    canvas = nil,
    msaa = 4,

    -- animation queue
    actions = {},       -- queued actions
    current = nil,      -- current action
    -- base speeds (when speed_setting == 1)
    base_move_speed = 100,  -- px/sec at speed 1
    base_turn_speed = 180,  -- deg/sec at speed 1
    -- user-facing speed setting (0..10)
    speed_setting = 5,  -- default to 5 (mid speed)
    -- stored segments (for export/debug)
    segments = {}
}

-- init: create canvas and set defaults
function turtle.init()
    local w,h = love.graphics.getDimensions()
    turtle.canvas = love.graphics.newCanvas(w,h, {msaa = turtle.msaa})
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("miter")
    turtle.reset()
end

-- reset: full reset of state and canvas
function turtle.reset()
    turtle.x = 400
    turtle.y = 300
    turtle.angle = 0
    turtle.penDown = true
    turtle.penColor = {1,1,1,1}
    turtle.penSize = 2
    turtle.actions = {}
    turtle.current = nil
    turtle.segments = {}

    if turtle.canvas then
        love.graphics.setCanvas(turtle.canvas)
        love.graphics.clear(0,0,0,0)
        love.graphics.setCanvas()
    end
end

-- speed(n): 0..10 (0 => instant)
function turtle.speed(self, n)
    if type(n) ~= "number" then return end
    if n < 0 then n = 0 end
    if n > 10 then n = 10 end
    self.speed_setting = n
end

-- helpers to compute effective speeds
local function move_speed_for(t)
    if t.speed_setting == 0 then return math.huge end
    return t.base_move_speed * t.speed_setting
end
local function turn_speed_for(t)
    if t.speed_setting == 0 then return math.huge end
    return t.base_turn_speed * t.speed_setting
end

-- enqueue actions (public API used by sandbox)
function turtle.forward(self, dist)
    dist = dist or 0
    table.insert(self.actions, { type="move", remaining = dist, distance = dist })
end

function turtle.back(self, dist)
    self.forward(self, -(dist or 0))
end

function turtle.right(self, ang)
    ang = ang or 0
    table.insert(self.actions, { type="turn", remaining = ang, angle = ang })
end

function turtle.left(self, ang)
    self.right(self, -(ang or 0))
end

function turtle.penup(self) self.penDown = false end
function turtle.pendown(self) self.penDown = true end

function turtle.pencolor(self, r,g,b,a)
    a = a or 1
    self.penColor = {r or 1, g or 1, b or 1, a}
end

function turtle.pensize(self, s)
    if type(s) == "number" then self.penSize = s end
end

-- LUKE FUNCTION
function turtle.setbackgroundcolor(red, green, blue, alpha)
    love.graphics.setBackgroundColor(red, green, blue, alpha)
end

function turtle.set_move_speed(self, v) self.base_move_speed = tonumber(v) or self.base_move_speed end
function turtle.set_turn_speed(self, v) self.base_turn_speed = tonumber(v) or self.base_turn_speed end

-- internal: start next action if none
local function start_next(t)
    if t.current then return end
    local nxt = table.remove(t.actions, 1)
    if nxt then
        -- attach effective speed (resolved in update)
        nxt.started = true
        t.current = nxt
    end
end

-- update: animate actions with continuous interpolation
function turtle.update(dt)
    start_next(turtle)
    local a = turtle.current
    if not a then return end

    if a.type == "move" then
        local remaining = a.remaining
        local speed = move_speed_for(turtle) -- px/sec (math.huge if instant)
        -- compute step for this frame
        local dir = (remaining >= 0) and 1 or -1
        local step = speed * dt * dir
        -- if speed is infinite (instant), consume all
        if speed == math.huge then
            step = remaining
        end
        if math.abs(step) > math.abs(remaining) then step = remaining end

        local oldx, oldy = turtle.x, turtle.y
        local rad = math.rad(turtle.angle)
        turtle.x = turtle.x + math.cos(rad) * step
        turtle.y = turtle.y + math.sin(rad) * step

        if turtle.penDown then
            -- record segment
            table.insert(turtle.segments, {oldx, oldy, turtle.x, turtle.y, turtle.penColor, turtle.penSize})
            -- draw immediately into canvas for persistence
            love.graphics.setCanvas(turtle.canvas)
            love.graphics.setBlendMode("alpha")
            love.graphics.setLineWidth(turtle.penSize)
            love.graphics.setColor(turtle.penColor)
            love.graphics.line(oldx, oldy, turtle.x, turtle.y)
            love.graphics.setCanvas()
            love.graphics.setBlendMode("alpha")
        end

        a.remaining = a.remaining - step
        if a.remaining == 0 or math.abs(a.remaining) < 1e-6 then turtle.current = nil end

    elseif a.type == "turn" then
        local remaining = a.remaining
        local speed = turn_speed_for(turtle) -- deg/sec
        local dir = (remaining >= 0) and 1 or -1
        local step = speed * dt * dir
        if speed == math.huge then
            step = remaining
        end
        if math.abs(step) > math.abs(remaining) then step = remaining end

        turtle.angle = (turtle.angle + step) % 360
        a.remaining = a.remaining - step
        if a.remaining == 0 or math.abs(a.remaining) < 1e-6 then turtle.current = nil end

    else
        -- unknown action: drop it
        turtle.current = nil
    end
end

-- draw: canvas + turtle head
function turtle.draw()
    -- background
    love.graphics.clear(0.07, 0.07, 0.07, 1)

    -- persistent trail canvas
    if turtle.canvas then
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(turtle.canvas, 0, 0)
    end

    -- turtle head
    love.graphics.push()
    love.graphics.translate(turtle.x, turtle.y)
    love.graphics.rotate(math.rad(turtle.angle))
    local s = 10
    love.graphics.setColor(0,1,0,1)
    love.graphics.polygon("fill", s, 0, -s*0.6, s*0.6, -s*0.6, -s*0.6)
    love.graphics.pop()
end

-- utility
function turtle.get_segments() return turtle.segments end

return turtle
