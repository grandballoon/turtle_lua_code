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

pencolor(245/255, 40/255, 145/255, 1.0)
fd(100)
rt(360)
pencolor(145/255, 245/255, 40/255, 1.0)
square()
bgcolor(245/255, 40/255, 145/255, 1.0)
rc()
rt(30)
square()
rc()
rt(30)