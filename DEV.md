# Building apps

The process of building an app is different among macOS, Linux, Windows, iOS and Android.  Even the definition of what an "app" is is different.  For instance, you likely want to make a .dmg file for distributing a program on macOS, and for Windows you might want an installer.  For Linux you'll probably want to make a package.

This section will try to diagram the common and differing parts of building an "app".

## Inputs

- resources (images, media, HTML, CSS, etc...)
- Nim source files
- platform-specific source files (Java/Objective-C)
- configuration

Following are the various steps or artifacts for a given platform:

### iOS

1. Compile Nim to exectuable
2. Make `.app` directory
3. Copy in/compile shared libs
4. Create various other files in `.app` dir (Info.plist, icons, LaunchScreen.storyboard, Entitlements.plist)
5. `.app` is final, distribution format

### Android

1. All kinds of Java junk
2. An activity
3. Compile Nim to shared lib
