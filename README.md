[![Tests](https://github.com/iffy/wiish/workflows/tests/badge.svg)](https://github.com/iffy/wiish/actions?query=branch%3Amaster)

<div style="text-align:center;"><img src="./logo.png"></div>

[Docs](https://www.iffycan.com/wiish/) | [Changelog](./CHANGELOG.md)

Wiish (Why Is It So Hard) GUI framework might one day make it easy to develop, package and deploy auto-updating, cross-platform applications for desktop and mobile.  If it succeeds, maybe the name will have to change :)

**Wiish is currently ALPHA quality software.**  Don't make anything with it unless you're willing to rewrite it when this package changes.

![Screenshots of macOS, iPhone simulator and Android emulator](img/sample.png)


# Quickstart

1. Install [Nim](https://nim-lang.org/install.html) and `nimble`

2. Install Wiish:

    ```bash
    nimble install https://github.com/iffy/wiish.git
    ```

3. Find out what other dependencies you need:

    ```bash
    wiish doctor
    ```

4. Create a project and run it:

    ```bash
    wiish init somedir
    cd somedir
    wiish run
    ```

See `wiish --help` for more, but here are other examples.  Some only work within a Wiish project:

```
wiish run --os ios-simulator
wiish run --os android
wiish build
wiish init --base-template opengl my_opengl_app
```

# Features

Wiish provides:

1. A `wiish` command line tool for running, building and packaging apps.
2. A `wiish` Nim library (i.e. `import wiish/...`) for app-specific helpers (e.g. auto-updating, asset-access, etc...)
3. Plugins for different GUI frameworks: `import wiish/plugins/...`

# Plugins

Wiish uses a plugin system to support various GUI frameworks:

- `wiish/plugins/webview` - For webview apps based on [oskca/webview](https://github.com/oskca/webview).
- `wiish/plugins/sdl2` - For SDL and OpenGL apps based on [nim-lang/sdl2](https://github.com/nim-lang/sdl2).

The GUI component is designed to work separately from other features (e.g. auto-updating, packaging, etc...) so that different GUI libraries can be swapped in/out.

It is hoped that more plugins will be introduced for other GUI frameworks.

## Support Matrix

| Host OS | `--os`     | Example      |        `wiish run`         |       `wiish build`        |
| ------- | ------------- | ------------ | :----------------: | :----------------: |
| windows | android       | opengl       |        :x:         |        :x:         |
| windows | android       | plainwebview |        :x:         |        :x:         |
| windows | android       | sdl2         |        :x:         |        :x:         |
| windows | android       | webview      |        :x:         |        :x:         |
| windows | mobiledev     | opengl       |        :x:         |         -          |
| windows | mobiledev     | plainwebview |        :x:         |         -          |
| windows | mobiledev     | sdl2         |        :x:         |         -          |
| windows | mobiledev     | webview      |        :x:         |         -          |
| windows | windows       | opengl       |        :x:         | :white_check_mark: |
| windows | windows       | plainwebview |        :x:         | :white_check_mark: |
| windows | windows       | sdl2         |        :x:         | :white_check_mark: |
| windows | windows       | webview      |        :x:         | :white_check_mark: |
| linux   | android       | opengl       |        :x:         | :white_check_mark: |
| linux   | android       | plainwebview |        :x:         |        :x:         |
| linux   | android       | sdl2         |        :x:         | :white_check_mark: |
| linux   | android       | webview      |        :x:         | :white_check_mark: |
| linux   | mobiledev     | opengl       |        :x:         |         -          |
| linux   | mobiledev     | plainwebview |        :x:         |         -          |
| linux   | mobiledev     | sdl2         |        :x:         |         -          |
| linux   | mobiledev     | webview      |        :x:         |         -          |
| linux   | linux         | opengl       |        :x:         | :white_check_mark: |
| linux   | linux         | plainwebview |        :x:         | :white_check_mark: |
| linux   | linux         | sdl2         |        :x:         | :white_check_mark: |
| linux   | linux         | webview      |        :x:         | :white_check_mark: |
| mac     | android       | opengl       | :white_check_mark: | :white_check_mark: |
| mac     | android       | plainwebview |        :x:         |        :x:         |
| mac     | android       | sdl2         | :white_check_mark: | :white_check_mark: |
| mac     | android       | webview      | :white_check_mark: | :white_check_mark: |
| mac     | ios           | opengl       |        :x:         |        :x:         |
| mac     | ios           | plainwebview |        :x:         |        :x:         |
| mac     | ios           | sdl2         |        :x:         |        :x:         |
| mac     | ios           | webview      |        :x:         |        :x:         |
| mac     | ios-simulator | opengl       |        :x:         | :white_check_mark: |
| mac     | ios-simulator | plainwebview |        :x:         |        :x:         |
| mac     | ios-simulator | sdl2         |        :x:         | :white_check_mark: |
| mac     | ios-simulator | webview      |        :x:         | :white_check_mark: |
| mac     | mobiledev     | opengl       |        :x:         |         -          |
| mac     | mobiledev     | plainwebview |        :x:         |         -          |
| mac     | mobiledev     | sdl2         |        :x:         |         -          |
| mac     | mobiledev     | webview      | :white_check_mark: |         -          |
| mac     | mac           | opengl       | :white_check_mark: | :white_check_mark: |
| mac     | mac           | plainwebview | :white_check_mark: | :white_check_mark: |
| mac     | mac           | sdl2         | :white_check_mark: | :white_check_mark: |
| mac     | mac           | webview      | :white_check_mark: | :white_check_mark: |

### GUI-independent features

| Feature                 | macOS | Windows | Linux |  iOS  | Android |
| ----------------------- | :---: | :-----: | :---: | :---: | :-----: |
| App icons               |   Y   |         |       |   Y   |    Y    |
| `wiish run` logs stdout |   Y   |    Y    |   Y   |   Y   |    Y    |
| Log files               |       |         |       |       |         |
| Static assets           |   Y   |         |       |   Y   |    Y    |
| Automatic updating      |       |         |       |   -   |    -    |
| File associations       |       |         |       |       |         |
| Menu bar access         |       |         |       |   -   |    -    |

### Distribution formats

| Package           | Supported | Code signing |
| ----------------- | :-------: | :----------: |
| macOS `.dmg`      |           |              |
| Windows Portable  |           |              |
| Windows Installer |           |              |
| Linux `.AppImage` |           |              |
| iOS `.ipa`        |           |              |
| Android `.apk`    |     Y     |              |


# Examples

See the [`examples`](./examples) directory for more examples of how to use this library.  You can also initialize a project using these examples with `wiish init`.  See `wiish init --help` for information.


# Plugins

## sdl2

## webview| 

### Messaging

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
import wiish/plugins/webview/desktop
var app = newWebviewDesktopApp()
app.life.addListener proc(ev: DesktopEvent) =
  case ev.kind
  of desktopAppStarted:
    var win = app.newWindow(
      url = some_html_url,
    )
    win.onReady.handle:
      win.sendMessage("Hello JavaScript! -Sincerely Nim")
    win.onMessage.handle(msg):
      discard "Handle message from JavaScript"
app.start()
```


# A note on quality

This library works as advertised, but it is a huge mess.  I'm learning as I'm going, and trying to wrangle all these platforms is ridiculous.  I happily welcome suggestions (and pull requests).

# Developing wiish

See [CONTRIBUTING.md](./CONTRIBUTING.md) for information about contributing to Wiish development.