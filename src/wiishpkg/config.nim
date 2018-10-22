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

proc readConfig*(filename:string):Config =
  result = Config()
  result.toml = parsetoml.parseFile(filename)
  var toml = result.toml
  result.name = toml["main"]["name"].stringVal
  result.version = toml["main"]["version"].stringVal
  result.src = toml["main"]["src"].stringVal
  result.dst = toml["main"]["dst"].stringVal

