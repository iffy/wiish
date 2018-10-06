# Installing dependencies

## macOS

~~~
nimble install
~~~

## Linux

TODO

## Windows

TODO

## iOS

TODO

## android

TODO

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