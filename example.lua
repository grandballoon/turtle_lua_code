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

function square2()
    for i=1,4 do
        fd(100)
        rt(90)
    end
end
pencolor(245, 0, 0)
square2()
rt(90)
fd(50)
pensize(30)
square2()