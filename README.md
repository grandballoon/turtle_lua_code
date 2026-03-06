# Turtle Graphics

Write code, see it draw. Edit the file, save, and the turtle redraws automatically.

## Getting Started

1. Open the Turtle app.
2. Click "Open in Editor" in the top corner to open your code file.
3. Type a command, save the file, and watch the turtle move.

## Commands

**Moving:** `forward(100)` moves the turtle 100 pixels. `back(50)` moves it backward. You can shorten these to `fd(100)` and `bk(50)`.

**Turning:** `right(90)` turns 90 degrees clockwise (the turtle won't move; it will only *turn*). `left(45)` turns counter-clockwise. Shortcuts: `rt(90)` and `lt(45)`.

**Pen:** `penup()` lifts the pen so the turtle moves without drawing. `pendown()` puts it back. `pencolor("red")` changes the color — try "blue", "gold", "purple", "skyblue", or any name from the built-in palette. `pensize(5)` makes the line thicker. Try different numbers and see what they do.

**Position:** `home()` returns to the center. `goto(100, 50)` draws a line to that point. `teleport(100, 50)` jumps there without drawing. Try different numbers to get a sense for coordinates.

**Shapes:** `circle(60)` draws a circle with radius 60.

**Loops:** Lua's `for` loop lets you repeat commands. This draws a square:

```
for i = 1, 4 do
    forward(100)
    right(90)
end
```

## Drag and Drop

You can drag any `.lua` file onto the turtle window to run it. The app will start watching that file for changes instead. This is helpful if you'd like to store your code in a particular place, but still have it easily accessible from the Turtle app.


