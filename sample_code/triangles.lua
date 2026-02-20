
function reqtri(side)
    for i = 1, 3 do
        fd(side)
        rt(120)
    end
end

function leqtri(side)
    for i = 1, 3 do
        fd(side)
        lt(120)
    end
end

for i = 1, 10 do
    leqtri(100)
    reqtri(100)
    rt(30)
end 