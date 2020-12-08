[![Tests](https://github.com/iffy/wiish/workflows/tests/badge.svg)](https://github.com/iffy/wiish/actions?query=branch%3Amaster)

<div style="text-align:center;"><img src="./logo.png"></div>

[Docs](https://www.iffycan.com/wiish/) | [Changelog](./CHANGELOG.md)

Wiish (Why Is It So Hard) GUI framework might one day make it easy to develop, package and deploy auto-updating, cross-platform applications for desktop and mobile.  If it succeeds, maybe the name will have to change :)

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
    - **Windows**: Don't know yet

4. Create a project and run it:

    ```
    wiish init somedir
    cd somedir
    wiish run
    ```

See `wiish --help` for how to build executables and apps and configure a project.  For example:

```
wiish doctor
wiish run --os ios
wiish run --os android
wiish build
wiish init --base-template opengl my_opengl_app
```

# Features

Wiish provides these main things:

1. `wiish` - A command line tool for running, building and packaging apps.
2. `wiish` - A Nim library `import wiish/...` for help with making apps.

## Plugins

Wiish uses a plugin system to support various GUI methods:

- `wiish/plugins/webview` - For webview apps based on [oskca/webview](https://github.com/oskca/webview).
- `wiish/plugins/sdl2` - For SDL and OpenGL apps based on [nim-lang/sdl2](https://github.com/nim-lang/sdl2).

The GUI component is designed to work separately from other features (e.g. auto-updating, packaging, etc...) so that different GUI libraries can be swapped in/out.

## Support

### GUI framework support

| Product        | webview | OpenGL | SDL2  |
| -------------- | :-----: | :----: | :---: |
| macOS `.app`   |    Y    |   Y    |   Y   |
| Windows `.exe` |         |        |       |
| Linux binary   |    Y    |        |       |
| iOS `.app`     |    Y    |   Y    |   Y   |
| Android `.apk` |    Y    |   Y    |   Y   |
| mobiledev      |    Y    |        |       |

### GUI-independent features

| Feature                    | macOS | Windows | Linux |  iOS  | Android |
| -------------------------- | :---: | :-----: | :---: | :---: | :-----: |
| App icons                  |   Y   |         |       |   Y   |    Y    |
| `wiish run` logs to stdout |   Y   |    Y    |   Y   |   Y   |    Y    |
| Log files                  |       |         |       |       |         |
| Static assets              |   Y   |         |       |   Y   |    Y    |
| Automatic updating         |       |         |       |   -   |    -    |
| File associations          |       |         |       |       |         |
| Menu bar access            |       |         |       |   -   |    -    |

### Distribution formats

| Package           | Supported | Code signing |
| ----------------- | :-------: | :----------: |
| macOS `.dmg`      |           |              |
| Windows Installer |           |              |
| Linux AppImage    |           |              |
| iOS `.ipa`        |           |              |
| Android `.apk`    |           |              |

### Cross-compiling support

| Host system | macOS | Windows | Linux |  iOS  | Android |
| ----------- | :---: | :-----: | :---: | :---: | :-----: |
| macOS       |   Y   |         |       |   Y   |    Y    |
| Windows     |   -   |    Y    |       |   -   |         |
| Linux       |   -   |         |   Y   |   -   |    Y    |


# Examples

See the [`examples`](./examples) directory for more examples of how to use this library.  You can also initialize a project using these examples with `wiish init`.  See `wiish init --help` for information.

# Developing wiish

See [CONTRIBUTING.md](./CONTRIBUTING.md) for information about contributing to Wiish development.



# Webview messaging

When using the `wiish/plugins/webview` plugin, you send/receive strings between JavaScript and your Nim like this:

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
import wiish/webview_mobile

app.launched.handle:
    app.window.onReady.handle:
        app.window.sendMessage("Looks like you're ready, JS!")
    app.window.onMessage.handle(message):
        app.window.sendMessage("Thanks for the message, JS.")
```


# A note on quality

This library works as advertised, but it is a huge mess.  I'm learning as I'm going, and trying to wrangle all these platforms is ridiculous.  I happily welcome suggestions (and pull requests).
