## Wiish config file parsing
import parsetoml
import strutils

type
  ## Config is a project's configuration
  Config* = object of RootObj
    toml*: TomlValueRef
    name*: string
    version*: string
    src*: string
    dst*: string
    icon*: string
    nimflags*: seq[string]

const DEFAULTS* = (
  name: "Wiish App",
  version: "0.1.0",
  src: "myapp.nim",
  dst: "dist",
  nimflags: @[],
  icon: "",
)

proc get*(maintoml: TomlValueRef, key:string): TomlValueRef =
  let parts = key.split(".")
  var toml = maintoml
  for i,part in parts:
    if toml.hasKey(part):
      toml = toml[part]
      if i == parts.len-1:
        return toml
    else:
      break
  return nil

proc get*(maintoml: TomlValueRef, sections:seq[string], key: string, default: TomlValueRef): TomlValueRef =
  for section in sections:
    if maintoml.hasKey(section):
      let toml = maintoml.get(section)
      if toml.hasKey(key):
        return toml[key]
  return default

proc parseConfig*(filename:string): TomlValueRef =
  parsetoml.parseFile(filename)

proc getDesktopConfig*[T](toml: TomlValueRef, sections:seq[string] = @["desktop"]):T =
  result = T()
  result.toml = toml
  result.name = toml.get(sections, "name", ?DEFAULTS.name).stringVal
  result.version = toml.get(sections, "version", ?DEFAULTS.version).stringVal
  result.src = toml.get(sections, "src", ?DEFAULTS.src).stringVal
  result.dst = toml.get(sections, "dst", ?DEFAULTS.dst).stringVal
  result.icon = toml.get(sections, "icon", ?DEFAULTS.icon).stringVal
  result.nimflags = @[]
  for flag in toml.get(sections, "nimflags", ?DEFAULTS.nimflags).arrayVal:
    result.nimflags.add(flag.stringVal)

proc getDesktopConfig*[T](config: Config, sections:seq[string] = @["desktop"]):T =
  getDesktopConfig[T](config.toml, sections)

proc getDesktopConfig*(filename: string, sections:seq[string] = @["desktop"]):Config =
  getDesktopConfig[Config](parseConfig(filename), sections)

proc getMobileConfig*[T](toml: TomlValueRef, sections:seq[string] = @["mobile"]):T =
  result = T()
  result.toml = toml
  result.name = toml.get(sections, "name", ?DEFAULTS.name).stringVal
  result.version = toml.get(sections, "version", ?DEFAULTS.version).stringVal
  result.src = toml.get(sections, "src", ?DEFAULTS.src).stringVal
  result.dst = toml.get(sections, "dst", ?DEFAULTS.dst).stringVal
  result.nimflags = @[]
  for flag in toml.get(sections, "nimflags", ?DEFAULTS.nimflags).arrayVal:
    result.nimflags.add(flag.stringVal)

proc getMobileConfig*[T](config: Config, sections:seq[string] = @["mobile"]):T =
  getMobileConfig[T](config.toml, sections)

proc getMobileConfig*(filename: string, sections:seq[string] = @["mobile"]):Config =
  getMobileConfig[Config](parseConfig(filename), sections)
