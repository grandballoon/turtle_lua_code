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

square2()