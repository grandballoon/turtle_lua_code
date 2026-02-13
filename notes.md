Friday, Feb 6, 8:03 AM
Current thinking is that if I can understand the turtle.pencolor() function, it'll work as well as
the bgcolor() implementation. So here are my notes on the turtle.pencolor() function:

The turtle table at the top of turtle.lua has a penColor attribute set to {1, 1, 1, 1} in its default declaration. (This is black, in rgba values). (line 6)

It's set to the same value in turtle.reset() on line 39.

The turtle.pencolor(self, r, g, b, a) function on line 92 looks like the following:

function turtle.pencolor(self, r,g,b,a)
    a = a or 1
    self.penColor = {r or 1, g or 1, b or 1, a}
end

Simple. Default values of 1, in other words it resets to the default value whenever called without arguments.

The turtle.update(dt) function (big method here) sets love.graphics.setColor to turtle.penColor if the pen is down—that must be part of the interface between the turtle file and the renderer.

It looks like that's all of the turtle.pencolor concerns in turtle.lua

No reference to penColor in executor.lua, which is good. Same for filewatcher.lua

The only reference to pencolor in main.lua is the following env method:

env.pencolor = function(...) return turtle.pencolor(turtle, ...) end

So let's try changing the pencolor in-place as per normal and get a feel for the live API.

I think this architecture decision was bad. What I've ended up with is spaghetti code, not something near to being finished. It DOES work, but not in the way that I want. Angry, frustrated, hurt.

So what's the most stripped-down version of this I can extract?

The actual experience should be:

type a command
state changes
type another command
state changes again
type a third command
state changes once more.

Run these commands in any file or lua environment you prefer—a text editor or a live coding session. Run them sequentially as a full script or think through it in a state-by-state way. 