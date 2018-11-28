## Changelog

When you make a change, include a description of the change as one or more new markdown files in the `changes/` directory. When new versions are released, the changes in the directory will be added to CHANGELOG.md and then deleted.

The filenames should follow this format:

```
changes/TYPE-TITLE.md
```

where `TYPE` is one of:

- `fix` = for bug fixes
- `new` = for new features
- `break` = for breaking changes
- `misc` = for every other kind of change

and `TITLE` is a unique name for your change (the purpose is just to avoid conflicts).  It could include an issue number.

If the change fixes a GitHub issue, include that in the change file like this: `(#103)`

## Design Plan

Wiish components are meant to be replaceable and expendable.  For instance:

- You should be able to use the `wiish` command line tool without importing anything from `wiishpkg` in your app.  

- If you want to write low-level OpenGL, you should be able to do that.  Or if you want to use a higher-level library, you should be able to do that, too.

- Auto-updating and logging should be usable no matter what GUI library you use.

In other words, components shouldn't be interwined so much that they're inseparable.  Also, you should always be able to drop down the a lower level if needed.  Instead, they should be easily replaced.

---

For the GUI, my plan is to explore using these:

1. Webview
2. [nimx](https://github.com/yglukhov/nimx)
3. SDL + Skia
4. GLFW + Vulkan ( + MoltenVK + Metal ) + Skia

If Skia is too painful to get working, I'll attempt NanoVG.

And if none of that works and something better doesn't come along, I'll write my own in Nim.

## Running tests

~~~
nimble test
tests/dochecks.sh
~~~

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
- [FTGL](http://ftgl.sourceforge.net/docs/html/index.html) for font rendering
- Building Nim for Android: <https://forum.nim-lang.org/t/3575>

### Glossary

- A [**retained mode** GUI](https://en.wikipedia.org/wiki/Retained_mode) is when a bunch of objects are retained by the library (in a tree or something) and the developer doesn't cause rendering to happen right away by making calls.
- An [**immediate mode** GUI](https://en.wikipedia.org/wiki/Immediate_mode_(computer_graphics)) is when you directly write the graphics to the display.  You probably have to issue all drawing commands on each frame.
