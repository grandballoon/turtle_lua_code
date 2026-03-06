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


# Setup

## What You Need

1. **Turtle Graphics** — the app (you probably already have it if you're reading this)
2. **Sublime Text** — a text editor for writing your code

## Installing Sublime Text

Download Sublime Text from [sublimetext.com/download](https://sublimetext.com/download). It's free to use.

**Mac:** Open the downloaded file and drag Sublime Text to your Applications folder.

**Windows:** Run the installer and follow the prompts.

## Setting Up Sublime Text

1. Open Sublime Text.
2. Press Cmd+Shift+P (Mac) or Ctrl+Shift+P (Windows) to open the Command Palette.
3. Type "Install Package Control" and hit Enter. Wait a few seconds.
4. Open the Command Palette again, type "Install Package" and hit Enter.
5. When the second input field appears, type "Lua Love" and select it.

## Making Sublime the Default Editor

**Mac:** Right-click any `.lua` file in Finder → Get Info → under "Open With," select Sublime Text → click "Change All."

**Windows:** Right-click any `.lua` file → Open With → Choose Another App → select Sublime Text → check "Always use this app."

## Using It

1. Open the Turtle Graphics app.
2. Click "Open in Editor" in the top-right corner. Your code opens in Sublime Text.
3. Edit the code, save (Cmd+S or Ctrl+S), and watch the turtle redraw.
4. You can drag and drop any valid file of lua code, ending in `.lua`, onto the Turtle window to run that code. That file, in whatever location on your computer, will be the one to load the next time you click "Open in Editor."

That's it. You're ready to go.