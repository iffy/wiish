# v0.3.0 - 2021-01-12

- **NEW:** Added `info_plist_append` section to wiish.toml to allow apps to append data to the standard `Info.plist` file for macOS and iOS.
- **NEW:** iOS apps are now single-threaded by default
- **NEW:** For iOS, Wiish now uses Xcode to build the app instead of crafting it itself. This also means that you can modify the Xcode build to suit your needs.
- **FIX:** Renamed OS-specific webview window types to WebviewWindow
- **FIX:** `mobileutil.documentsPath` now works for mobiledev
- **FIX:** Webview desktop app no longer hangs when using async Nim features. ([#97](https://github.com/iffy/wiish/issues/97))
- **FIX:** Look for a `[mobiledev]` section in `wiish.toml`

# v0.2.0 - 2020-12-29

- **BREAKING CHANGE:** Combined DesktopEvent and MobileEvent into LifeEvent
- **BREAKING CHANGE:** Changed command line interface to use `--target TARGET` format instead of `--macos`, `--windows`, etc...  This will make it easier to to `--target mac` and `--target mac-dmg`.
- **BREAKING CHANGE:** Split main data directory into plugin-specific data directories
- **NEW:** JavaScript in Android and iOS webview apps can now interact with Nim code ([#30](https://github.com/iffy/wiish/issues/30))
- **NEW:** `wiish doctor` now lets you filter in a more structured way.  For instance, you can choose to see what you need to do to build for iOS without seeing what you lack for Android.
- **NEW:** Switch from `re` to `regex`
- **NEW:** Added a better webview demo
- **NEW:** Added `-v`/`--version` to `wiish`
- **NEW:** Added very basic automated `wiish run` tests
- **NEW:** Added a CHANGELOG.
- **NEW:** nimbase.h is now included in the wiish package in case it can't be found otherwise
- **FIX:** OpenGL example on iOS now gets events again.
- **FIX:** webview - Linux `wiish run` now works
- **FIX:** PNG images can now be resized on any OS thanks to [flippy](https://github.com/treeform/flippy). ([#41](https://github.com/iffy/wiish/issues/41))
- **FIX:** Running `wiish build` and `wiish run` outside of a Wiish project now fails with a helpful error.
- `wiish init --help` now shows possible project templates


