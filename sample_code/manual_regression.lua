-- manual_regression.lua
-- Copy snippets from this file into example.lua to validate baseline behavior
-- during the REPL refactor.

-- 1) Basic movement
forward(80)
right(90)
forward(80)

-- 2) Pen settings
pencolor(255, 120, 30)
pensize(4)
left(90)
forward(80)

-- 3) Speed controls
speed(8)
right(135)
forward(60)

-- 4) Reset semantics (current behavior)
-- reset()
-- forward(50)
