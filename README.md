[![Build Status](https://travis-ci.org/iffy/wiish.svg?branch=master)](https://travis-ci.org/iffy/wiish)
[![Windows build status](https://ci.appveyor.com/api/projects/status/hnv03meyx4absx4t/branch/master?svg=true)](https://ci.appveyor.com/project/iffy/wiish/branch/master)

Wiish (Why Is It So Hard) GUI framework might one day make it easy to develop, package and deploy auto-updating,  cross-platform applications for desktop and mobile.  If it succeeds, maybe the name will have to change :)

# Planned Features

| Feature             | Windows | macOS | Linux | iOS | Android |
|---------------------|:-------:|:-----:|:-----:|:---:|:-------:|
| Run                 |         |   Y   |   Y   |     |         |
| Create executable   |         |   Y   |       |     |         |
| Create installer    |         |       |       |     |         |
| Code signing        |         |       |       |     |         |
| Logging             |         |       |       |     |         |
| Automatic updates   |         |       |       |  -  |    -    |
| App icon            |         |       |       |     |         |
| File associations   |         |       |       |  -  |    -    |
| Widgets             |         |       |       |     |         |

# Using wiish

## Install

First install Nim and nimble, then do

~~~
nimble install https://github.com/iffy/wiish.git
~~~

## Make a project

```
wiish init somedir
cd somedir
```

Then run or build it with:

```
wiish run
wiish build
```

See `wiish --help` for more information.

# Developing wiish

## Running tests

~~~
nimble test
~~~

## Running examples

~~~
nim c -r examples/basic/basic.nim
nim c -r examples/fonts/fonts.nim
~~~

## Current Plan

In order of preference, my plan is to use:

1. [nimx](https://github.com/yglukhov/nimx), but I have yet to get it to run

2. SDL + Skia

3. GLFW + Vulkan ( + MoltenVK + Metal ) + Skia

If Skia is too painful to get working, I'll attempt NanoVG.

And if none of that works and something better doesn't come along, I'll write my own in Nim.

## Notes

This is where I'm currently recording what I've learned about GUI development.

### Backends

- [**OpenGL**](https://en.wikipedia.org/wiki/OpenGL#Vulkan) is an API definition.  There are several language bindings, too.  It assumes you've created a context and does nothing to help you make such a context.  There are other things (like SDL, GLUT and GLFW)

- [**OpenGL ES**](https://www.khronos.org/opengles/) is a subset of OpenGL designed for mobile devices (low power).

- [**Vulkan**](https://en.wikipedia.org/wiki/Vulkan_(API)) is the next generation of OpenGL that's supposed to combine OpenGL and OpenGL ES.

- **Metal** is Apple's proprietary low-level graphics API thinger.  And there's MoltenVK which is supposed to allow Vulkan to run on macOS and iOS.

### Getting OpenGL Contexts

- **GLFW** is for making windows (desktop) with OpenGL and OpenGL ES contexts.

- [**SDL**](https://www.khronos.org/opengl/wiki/Related_toolkits_and_APIs) does what GLFW does plus sound and other stuff.



### Drawing

- [Skia](https://en.wikipedia.org/wiki/Skia_Graphics_Engine) is a pain to figure out how to use.  Can use OpenGL

- [NanoVG](https://github.com/memononen/nanovg) is a vector graphics library for OpenGL.  It's a single file: <https://github.com/memononen/nanovg/tree/master/src>

### Widgets

- Qt

- [Nuklear](https://github.com/vurtun/nuklear) might be nice for making GUIs.  It has widgets.

- nimx

### To research

- [bgfx](https://bkaradzic.github.io/bgfx/index.html)

### Glossary

- A [**retained mode** GUI](https://en.wikipedia.org/wiki/Retained_mode) is when a bunch of objects are retained by the library (in a tree or something) and the developer doesn't cause rendering to happen right away by making calls.
- An [**immediate mode** GUI](https://en.wikipedia.org/wiki/Immediate_mode_(computer_graphics)) is when you directly write the graphics to the display.  You probably have to issue all drawing commands on each frame.

