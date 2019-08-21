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

    Run `wiish doctor` to see what you need installed.  It will probably be:

    - **Ubuntu**: `apt-get install libsdl2-dev libsdl2-ttf-dev libgtk-3-dev libwebkit2gtk-4.0-dev`
    - **macOS**: Xcode
    - **Windows**: no other deps (maybe?)

4. Create a project and run it:

    ```
    wiish init somedir
    cd somedir
    wiish run
    ```

See `wiish --help` for how to build executables and apps and configure a project.  For example:

```
wiish doctor
wiish config
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
    - `wiishpkg/mobileutil` - Utilities for accessing native modules (e.g. file system)

The GUI component is designed to work separately from other features (e.g. auto-updating, packaging, etc...) so that different GUI libraries can be swapped in/out.

Here is what's currently supported:

**Library**

| Feature                | Windows | macOS | Linux | iOS | Android |
|------------------------|:-------:|:-----:|:-----:|:---:|:-------:|
| `wiish run`            |         |   Y   |   Y   |  Y  |    Y    |
| Code signing           |         |       |       |     |         |
| Log to file            |         |   Y   |       |     |         |
| Log to console w/ run  |         |   Y   |   Y   |  Y  |    Y    |
| Package resources      |         |   Y   |       |  Y  |    Y    |
| Menu bar               |         |       |       |  -  |    -    |
| Automatic updates      |         |       |       |  -  |    -    |
| App icon               |         |   Y   |       |  Y  |    Y    |
| File associations      |         |       |       |  -  |    -    |

| `wiish build --target` | OpenGL | SDL2 | Webview | Notes           |
|------------------------|:------:|:----:|:-------:|-----------------|
| `android`              |        |      |    Y    | No code signing |
| `ios`                  |        |      |    Y    | No code signing |
| `linux`                |        |      |         | No code signing |
| `mac`                  |        |      |    Y    | No code signing |
| `mac-dmg`              |        |      |         | No code signing |
| `win`                  |        |      |         | No code signing |
| `win-installer`        |        |      |         | No code signing |

**Y** = complete, **-** = not applicable

# Examples

See the [`examples`](./examples) directory for more examples of how to use this library.  You can also initialize a project using these examples with `wiish init`.  See `wiish init --help` for information.

# Developing wiish

See [CONTRIBUTING.md](./CONTRIBUTING.md) for information about contributing to Wiish development.



# Webview messaging

Wiish enables you to send/receive strings between JavaScript and your Nim code.

In JavaScript do this:

```javascript
window.wiish = window.wiish || {};
wiish.onReady = () => {
    wiish.onMessage(message => {
        // Handle message from Nim
    })
    wiish.sendMessage("Hello Nim! -Sincerely JavaScript");
}
```

In Nim do this:

```nim
import wiishpkg/webview_mobile

app.launched.handle:
    app.window.onReady.handle:
        app.window.sendMessage("Looks like you're ready, JS!")
    app.window.onMessage.handle(message):
        app.window.sendMessage("Thanks for the message, JS.")
```


# A note on quality

This library works as advertised, but it is a huge mess.  I'm learning as I'm going, and trying to wrangle all these platforms is ridiculous.  I happily welcome suggestions (and pull requests).
