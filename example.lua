-- example.lua
-- Edit this in Sublime/VS Code




function square()
    forward(100)
    right(90)
    forward(100)
    right(90)
    forward(100)
    right(90)
    forward(100)
    right(90)
end

function rcircle()
    for i = 1, 360 do
        fd(1)
        rt(1)
    end
end

function lcircle()
    for i = 1, 360 do
        fd(1)
        lt(1)
    end
end

function rc()
    rcircle()
end

function lc()
    lcircle()
end


function outward_spiral()
   for i = 360, 1, -1 do
        fd(2)
        rt(1 * (i / 100))
   end
end

function diminishing_spiral(scale)
    for i = 1, scale do
        fd(2)
        rt(1 * (i / 100))
    end
end

fraction1 = 10/100
fraction2 = 50/100
fraction3 = 40/100

function fraction_circle(frac)
    for i = 1, (360 * frac) do
        fd(1)
        rt(1)
    end
end

set_move_speed(100)
rcircle()
pencolor(240/255, 100/255, 150/255, 0.7)
fraction_circle(fraction1)
pencolor(100/255, 255/255, 150/255, 0.7)
fraction_circle(fraction2)
pencolor(100/255, 100/255, 255/255, 0.7)
fraction_circle(fraction3)
rt(90)
fd(100)