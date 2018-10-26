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
    nimflags*: seq[string]

const DEFAULTS* = (
  name: "Wiish App",
  version: "0.1.0",
  src: "app.nim",
  dst: "dist",
  nimflags: @[],
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
    let toml = maintoml.get(section)
    if toml.hasKey(key):
      return toml[key]
  return default

proc readConfig*(filename:string):Config =
  result = Config()
  result.toml = parsetoml.parseFile(filename)
  var toml = result.toml
  result.name = toml.get(@["main"], "name", ?DEFAULTS.name).stringVal
  result.version = toml.get(@["main"], "version", ?DEFAULTS.version).stringVal
  result.src = toml.get(@["main"], "src", ?DEFAULTS.src).stringVal
  result.dst = toml.get(@["main"], "dst", ?DEFAULTS.dst).stringVal
  result.nimflags = @[]
  for flag in toml.get(@["main"], "nimflags", ?DEFAULTS.nimflags).arrayVal:
    result.nimflags.add(flag.stringVal)
