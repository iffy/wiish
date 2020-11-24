## Wiish config file parsing
import parsetoml
import strutils
import strformat
import logging
import tables

type
  WindowFormat* = enum
    Webview,
    SDL,
  
  ConfigOption* = enum
    Name = "name",
    Version = "version",
    SourceDir = "src",
    OutputDir = "dst",
    Icon = "icon",
    ResourceDir = "resourceDir",
    NimFlags = "nimFlags",
    AppWindowFormat = "windowFormat",
    # macos/ios
    CodesignID = "codesign_identity",
    BundleID = "bundle_identifier",
    # macos
    CategoryType = "category_type",
    # ios
    SdkVersion = "sdk_version",
    IsSimulator = "simulator",
    ProvisioningProfile = "provisioning_profile",
    # android
    JavaPackageName = "java_package_name",

  ## Config is a project's configuration
  WiishConfig* = object of RootObj
    name*: string
    version*: string
    src*: string
    dst*: string
    icon*: string
    resourceDir*: string
    nimflags*: seq[string]
    windowFormat*: WindowFormat
    # macos/ios
    codesign_identity*: string
    bundle_identifier*: string
    # macos
    category_type*: string
    # ios
    sdk_version*: string
    ios_simulator*: bool
    ios_provisioning_profile*: string
    # android
    java_package_name*: string


proc get*[T](maintoml: TomlValueRef, sections:seq[string], key: string, default: T): TomlValueRef =
  ## Get a value from the first section that has the given key
  for section in sections:
    if maintoml.hasKey(section):
      let toml = maintoml[section]
      if toml.hasKey(key):
        return toml[key]
  return default

const OVERRIDE_KEY = "_override_"

proc override*[T](x:var TomlValueRef, key:string, val:T) =
  ## Set a command-line override
  x[OVERRIDE_KEY][key] = ?val

proc parseConfig*(filename:string): TomlValueRef =
  result = parsetoml.parseFile(filename)
  result[OVERRIDE_KEY] = newTTable()

proc getConfig*(toml: TomlValueRef, sections:seq[string]):WiishConfig =
  result = WiishConfig()
  for opt in low(ConfigOption)..high(ConfigOption):
    case opt
    of Name:
      result.name = toml.get(sections, $opt, ?"WiishApp").stringVal
    of Version:
      result.version = toml.get(sections, $opt, ?"0.1.0").stringVal
    of SourceDir:
      result.src = toml.get(sections, $opt, ?"main.nim").stringVal
    of OutputDir:
      result.dst = toml.get(sections, $opt, ?"dist").stringVal
    of Icon:
      result.icon = toml.get(sections, $opt, ?"").stringVal
    of ResourceDir:
      result.resourceDir = toml.get(sections, $opt, ?"resources").stringVal
    of NimFlags:
      result.nimflags = @[]
      for flag in toml.get(sections, $opt, ?(@[])).arrayVal:
        result.nimflags.add(flag.stringVal)
    of AppWindowFormat:
      let windowFormatString = toml.get(sections, $opt, ?"webview").stringVal
      case windowFormatString
      of "", "webview":
        result.windowFormat = Webview
      of "sdl":
        result.windowFormat = SDL
      else:
        warn &"Unknown windowFormat: {windowFormatString.repr}"
        result.windowFormat = Webview
    # macos/ios
    of CodesignID:
      result.codesign_identity = toml.get(sections, $opt, ?"").stringVal
    of BundleID:
      result.bundle_identifier = toml.get(sections, $opt, ?"com.example.wiishdemo").stringVal
    # macos
    of CategoryType:
      result.category_type = toml.get(sections, $opt, ?"").stringVal
    # ios
    of SdkVersion:
      result.sdk_version = toml.get(sections, $opt, ?"").stringVal
    of IsSimulator:
      result.ios_simulator = toml.get(sections, $opt, ?false).boolVal
    of ProvisioningProfile:
      result.ios_provisioning_profile = toml.get(sections, $opt, ?"").stringVal
    # android
    of JavaPackageName:
      result.java_package_name = toml.get(sections, $opt, ?"com.example.wiishapp").stringVal

template getMacosConfig*(parsed: TomlValueRef): WiishConfig =
  parsed.getConfig(@[OVERRIDE_KEY, "macos", "desktop", "main"])
template getMacosConfig*(filename: string): WiishConfig =
  filename.parseConfig().getMacosConfig()

template getWindowsConfig*(parsed: TomlValueRef): WiishConfig =
  parsed.getConfig(@[OVERRIDE_KEY, "windows", "desktop", "main"])
template getWindowsConfig*(filename: string): WiishConfig =
  filename.parseConfig().getWindowsConfig()

template getLinuxConfig*(parsed: TomlValueRef): WiishConfig =
  parsed.getConfig(@[OVERRIDE_KEY, "linux", "desktop", "main"])
template getLinuxConfig*(filename: string): WiishConfig =
  filename.parseConfig().getLinuxConfig()

template getiOSConfig*(parsed: TomlValueRef): WiishConfig =
  parsed.getConfig(@[OVERRIDE_KEY, "ios", "mobile", "main"])
template getiOSConfig*(filename: string): WiishConfig =
  filename.parseConfig().getiOSConfig()

template getAndroidConfig*(parsed: TomlValueRef): WiishConfig =
  parsed.getConfig(@[OVERRIDE_KEY, "android", "mobile", "main"])
template getAndroidConfig*(filename: string): WiishConfig =
  filename.parseConfig().getAndroidConfig()

template getMobileDevConfig*(parsed: TomlValueRef): WiishConfig =
  parsed.getConfig(@[OVERRIDE_KEY, "mobile", "main"])
template getMobileDevConfig*(filename: string): WiishConfig =
  filename.parseConfig().getMobileDevConfig()

template getMyOSConfig*(filename:string): WiishConfig =
  when defined(macosx):
    getMacosConfig(filename)
  elif defined(windows):
    getWindowsConfig(filename)
  else:
    getLinuxConfig(filename)

proc defaultConfig*():string =
  ## Return a default config file
  var
    main, desktop, mobile, macos, ios, android: seq[string]
  for opt in low(ConfigOption)..high(ConfigOption):
    case opt
    of Name:
      main.add(&"{opt} = \"Wiish Application\"")
    of Version:
      main.add(&"{opt} = \"0.1.0\"")
    of SourceDir:
      desktop.add(&"{opt} = \"main_desktop.nim\"")
      mobile.add(&"{opt} = \"main_mobile.nim\"")
    of OutputDir:
      main.add(&"{opt} = \"dist\"")
    of Icon:
      desktop.add(&"{opt} = \"\" # Path to an image file to use for the app icon")
      mobile.add(&"{opt} = \"\" # Path to an image file to use for the app icon")
    of ResourceDir:
      main.add(&"{opt} = \"resources\"")
    of NimFlags:
      main.add(&"{opt} = []")
    of AppWindowFormat:
      main.add(&"{opt} = \"webview\" # options: webview, sdl")
    # macos/ios
    of CodesignID:
      macos.add(&"{opt} = \"\"")
      ios.add(&"{opt} = \"\"")
    of BundleID:
      macos.add(&"{opt} = \"com.example.wiishapp\"")
      ios.add(&"{opt} = \"com.example.wiishapp\"")
    # macos
    of CategoryType:
      macos.add(&"{opt} = \"public.app-category.example\"")
    # ios
    of SdkVersion:
      ios.add(&"{opt} = \"\"")
    of IsSimulator:
      ios.add(&"{opt} = false")
    of ProvisioningProfile:
      ios.add(&"{opt} = \"\"")
    # android
    of JavaPackageName:
      android.add(&"{opt} = \"com.example.wiishexample\"")
  
  result = &"""[main]
{main.join("\L")}

[desktop]
{desktop.join("\L")}

[mobile]
{mobile.join("\L")}

[macos]
{macos.join("\L")}

[ios]
{ios.join("\L")}

[android]
{android.join("\L")}
"""