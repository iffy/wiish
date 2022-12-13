## Wiish configuration
import std/hashes
import std/macros
import std/tables; export tables

template extend*(T: typed, dft: untyped) =
  ## Extend WiishConfig with purpose-specific configuration data
  var configs = initTable[WiishConfig, T]()

  proc add*(c: WiishConfig, sub: T) =
    ## Attach an additional configuration object of type T to
    ## the given WiishConfig
    configs[c] = sub

  proc has*(wc: WiishConfig, ext: typedesc[T]): bool =
    configs.hasKey(wc)

  proc get*(wc: WiishConfig, ext: typedesc[T]): T =
    ## Get a previously-attached config extension of type T
    if not configs.hasKey(wc):
      wc.add(dft)
    return configs[wc]

  #     raise ValueError.newException("Attempting to access config of type " & $typedesc[ext] & " before it was added")
  #   return configs[wc]
  
  # proc getOrDefault*(wc: WiishConfig): T =
  #   if not wc.has(ext):
  #     echo "doesn't have"
  #     wc.add(default(ext))
  #     echo "added: ", wc.get(ext)[]
  #   wc.get(ext)
  #   configs.getOrDefault(wc, dft())
  
  # proc getOrDefault*(wc: WiishConfig, ext: typedesc[T]): T =
  #   echo "getOrDefault: ", wc[], " ", $ext
  #   if not wc.has(ext):
  #     echo "doesn't have"
  #     wc.add(default(ext))
  #     echo "added: ", wc.get(ext)[]
  #   wc.get(ext)
  
  template with*(wc: WiishConfig, ext: typedesc[T], varname: untyped, body: untyped): untyped =
    block:
      var varname {.inject.} = wc.get(ext)
      body


type
  WindowFormat* = enum
    Webview
    SDL

  WiishConfig* = ref object
    name*: string ## project name
    version*: string ## project version
    src*: string ## main nim file
    outDir*: string ## directory where build products should go
    iconPath*: string
    resourceDir*: string
    nimFlags*: seq[string]
    appWindowFormat*: WindowFormat
  
  BaseConfig* = ref object

  MacConfig* = ref object
    codesign_identity*: string
    bundle_id*: string
    info_plist_append*: string
  
  MacDesktopConfig* = ref object
    category_type*: string
  
  MaciOSConfig* = ref object
    sdk_version*: string
    provisioning_profile*: string

  AndroidArchPair = tuple
    abi: string
    cpu: string

  AndroidConfig* = ref object
    java_package_name*: string
    archs*: seq[AndroidArchPair]
    min_sdk_version*: Natural
    target_sdk_version*: Natural

proc hash*(c: WiishConfig): Hash =
  result = c[].hash

proc `$`*[C: ref object](cfg: C): string =
  $cfg[]

proc default(t: typedesc[WiishConfig]): WiishConfig = WiishConfig(
  name: "WiishApp",
  version: "0.1.0",
  src: "main.nim",
  outDir: "dist",
  iconPath: "",
  resourceDir: "resources",
  nimFlags: @[],
  appWindowFormat: Webview,
)

extend(MacConfig, MacConfig(
    codesign_identity: "",
    bundle_id: "com.example.wiishdemo",
    info_plist_append: ""
  )
)
extend(MacDesktopConfig, MacDesktopConfig(
    category_type: "",
  )
)
extend(MaciOSConfig, MaciOSConfig(
    sdk_version: "",
    provisioning_profile: "",
  )
)
extend(AndroidConfig, AndroidConfig(
    java_package_name: "com.example.wiishapp",
    archs: @[
      ("armeabi-v7a", "arm"),
      ("arm64-v8a", "arm64"),
      ("x86", "i386"),
      ("x86_64", "amd64"),
    ],
    min_sdk_version: 21,
    target_sdk_version: 26,
  )
)

var wiishConfig* = default(WiishConfig)
