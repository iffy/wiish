## Wiish config file parsing
import parsetoml
import strutils

type
  ## Config is a project's configuration
  Config* = object of RootObj
    name*: string
    version*: string
    src*: string
    dst*: string
    icon*: string
    resourceDir*: string
    nimflags*: seq[string]
    # macos/ios
    codesign_identity*: string
    bundle_identifier*: string
    # macos
    category_type*: string
    # ios
    sdk_version*: string
    # android
    java_package_name*: string



proc get*[T](maintoml: TomlValueRef, sections:seq[string], key: string, default: T): TomlValueRef =
  for section in sections:
    if maintoml.hasKey(section):
      let toml = maintoml[section]
      if toml.hasKey(key):
        return toml[key]
  return default

proc parseConfig*(filename:string): TomlValueRef =
  parsetoml.parseFile(filename)

proc getConfig*(filename: string, sections:seq[string]):Config =
  let toml = parseConfig(filename)
  result = Config()
  result.name = toml.get(sections, "name", ?"WiishApp").stringVal
  result.version = toml.get(sections, "version", ?"0.1.0").stringVal
  result.src = toml.get(sections, "src", ?"main.nim").stringVal
  result.dst = toml.get(sections, "dst", ?"dist").stringVal
  result.icon = toml.get(sections, "icon", ?"").stringVal
  result.resourceDir = toml.get(sections, "resourceDir", ?"resources").stringVal
  result.nimflags = @[]
  for flag in toml.get(sections, "nimflags", ?(@[])).arrayVal:
    result.nimflags.add(flag.stringVal)
  # macos/ios
  result.codesign_identity = toml.get(sections, "codesign_identity", ?"").stringVal
  result.bundle_identifier = toml.get(sections, "bundle_identifier", ?"com.example.wiishdemo").stringVal
  # macos
  result.category_type = toml.get(sections, "category_type", ?"").stringVal
  # ios
  result.sdk_version = toml.get(sections, "sdk_version", ?"").stringVal
  # android
  result.java_package_name = toml.get(sections, "java_package_name", ?"com.example.WiishApp").stringVal

template getMacosConfig*(filename: string): Config =
  getConfig(filename, @["macos", "desktop", "main"])

template getWindowsConfig*(filename: string): Config =
  getConfig(filename, @["windows", "desktop", "main"])

template getLinuxConfig*(filename: string): Config =
  getConfig(filename, @["linux", "desktop", "main"])

template getiOSConfig*(filename: string): Config =
  getConfig(filename, @["ios", "mobile", "main"])

template getAndroidConfig*(filename: string): Config =
  getConfig(filename, @["android", "mobile", "main"])

template getMyOSConfig*(filename: string): Config =
  when defined(ios):
    getiOSConfig(filename)
  elif defined(android):
    getAndroidConfig(filename)
  elif defined(macosx):
    getMacosConfig(filename)
  elif defined(windows):
    getWindowsConfig(filename)
  elif defined(linux):
    getLinuxConfig(filename)
