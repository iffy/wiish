[![Build Status](https://travis-ci.org/iffy/wiish.svg?branch=master)](https://travis-ci.org/iffy/wiish)
[![Windows build status](https://ci.appveyor.com/api/projects/status/hnv03meyx4absx4t/branch/master?svg=true)](https://ci.appveyor.com/project/iffy/wiish/branch/master)

<div style="text-align:center;"><img src="./logo.png"></div>

[Docs](https://www.iffycan.com/wiish/) | [Changelog](./CHANGELOG.md)

Wiish (Why Is It So Hard) GUI framework might one day make it easy to develop, package and deploy auto-updating,  cross-platform applications for desktop and mobile.  If it succeeds, maybe the name will have to change :)

**Wiish is currently ALPHA quality software.**  Don't make anything with it unless you're willing to rewrite it when this package changes.

# Quickstart

1. Install [Nim](https://nim-lang.org/install.html) and `nimble`

2. Install Wiish:

    ```
    nimble install https://github.com/iffy/wiish.git
    ```

3. Install other dependencies:
    - Android SDK and Android NDK for Android apps
    - **Ubuntu**: `apt-get install libsdl2-dev libsdl2-ttf-dev libgtk-3-dev libwebkit2gtk-4.0-dev`
    - **macOS**: no other deps
    - **Windows**: no other deps (maybe?)

4. Create a project and run it:

    ```
    wiish init somedir
    cd somedir
    wiish run
    ```

See `wiish --help` for how to build executables and apps.  For example:

```
wiish run --ios
wiish run --android
wiish build
wiish init --base-template opengl my_opengl_app
```

# Features

Wiish provides 2 main things:

1. `wiish` - A command line tool for running, building and packaging apps.
2. `wiishpkg` - A Nim library for making apps.  This is further divided into:
    - `wiishpkg/webview_desktop` - Library for making Webview-based desktop apps.
    - `wiishpkg/webview_mobile` - Library for making Webview-based mobile apps.
    - `wiishpkg/sdlapp` - Library for making SDL and/or OpenGL apps (both desktop and mobile).

The GUI component is designed to work separately from other features (e.g. auto-updating, packaging, etc...) so that different GUI libraries can be swapped in/out.

Here is what's currently supported:

**Library**

| Feature                | Windows | macOS | Linux | iOS | Android |
|------------------------|:-------:|:-----:|:-----:|:---:|:-------:|
| `wiish run`            |         |   Y   |   Y   |  Y  |    Y    |
| `wiish build`          |         |   Y   |       |  Y  |    Y    |
| `wiish package`        |         |       |       |     |         |
| Code signing           |         |       |       |     |         |
| Log to file            |         |   Y   |       |     |         |
| Log to console w/ run  |         |   Y   |   Y   |  Y  |    Y    |
| Package resources      |         |   Y   |       |  Y  |    Y    |
| Menu bar               |         |       |       |  -  |    -    |
| Automatic updates      |         |       |       |  -  |    -    |
| App icon               |         |   Y   |       |  Y  |    Y    |
| File associations      |         |       |       |  -  |    -    |

**GUI**

| Feature | Windows | macOS | Linux | iOS | Android |
|---------|:-------:|:-----:|:-----:|:---:|:-------:|
| OpenGL  |         |   Y   |   Y   |  Y  |    Y    |
| SDL2    |         |   Y   |   Y   |  Y  |         |
| Webview |         |   Y   |   Y   |  Y  |    Y    |

**Y** = complete, **-** = not applicable

# Examples

See the [`examples`](./examples) directory for more examples of how to use this library.  You can also initialize a project using these examples with `wiish init`.  See `wiish init --help` for information.

# Developing wiish

See [CONTRIBUTING.md](./CONTRIBUTING.md) for information about contributing to Wiish development.

