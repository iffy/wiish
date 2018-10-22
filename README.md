Wiish (Why Is It So Hard) GUI framework might one day make it easy to develop, package and deploy auto-updating,  cross-platform applications for desktop and mobile.

# TODO

- [ ] MacOS
    - [ ] Generate icon files from png files
- [ ] Windows desktop app
- [ ] Linux desktop app
- [ ] iOS app
- [ ] Android app

# Getting wiish

Right now, there's no precompiled binaries for `wiish`.  To build it, clone this repo, then:

~~~
nimble build
~~~

# Usage

1. First make a `wiish.toml` (see [examples/basicmac/wiish.toml](examples/basicmac/wiish.toml) for an example).

2. Create a source Nim file (see [examples/basicmac/basicmac.nim](examples/basicmac/basicmac.nim)).

3. Run the application with `./wiish run`

4. Package the application with `./wiish build --mac`


# Running tests

~~~
nimble test
~~~

# Running examples

~~~
nim c -r examples/basic/basic.nim
nim c -r examples/fonts/fonts.nim
~~~


# Thoughts

- GLFW is for making windows (desktop) with OpenGL and OpenGL ES contexts.  Not for mobile, but OpenGL could be for mobile.

- SDL does what GLFW does plus sound and other stuff <https://www.khronos.org/opengl/wiki/Related_toolkits_and_APIs>

- NanoVG is a vector graphics library for OpenGL <https://github.com/memononen/nanovg>.  Single file: <https://github.com/memononen/nanovg/tree/master/src>

- Nuklear might be nice for making GUIs