fraction1 = 10/100
fraction2 = 50/100
fraction3 = 40/100

function fraction_circle(frac)
    for i = 1, (360 * frac) do
        fd(1)
        rt(1)
    end
end

for i = 1, 360 do
    fd(1)
    rt(1)
end

pencolor(240/255, 100/255, 150/255, 0.7)
fraction_circle(fraction1)
pencolor(100/255, 255/255, 150/255, 0.7)
fraction_circle(fraction2)
pencolor(100/255, 100/255, 255/255, 0.7)
fraction_circle(fraction3)