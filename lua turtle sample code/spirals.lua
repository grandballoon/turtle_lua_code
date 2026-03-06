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


outward_spiral()