## Wiish configuration
import std/hashes
import std/tables; export tables

template extend*(T: typed) =
  ## Extend WiishConfig with purpose-specific configuration data
  var configs = initTable[WiishConfig, T]()

  proc has*(wc: WiishConfig, ext: typedesc[T]): bool =
    configs.hasKey(wc)

  proc get*(wc: WiishConfig, ext: typedesc[T]): T =
    ## Get a previously-attached config extension of type T
    if not configs.hasKey(wc):
      raise ValueError.newException("Attempting to access config of type " & $typedesc[ext] & " before it was added")
    return configs[wc]
  
  proc getOrDefault*(wc: WiishConfig, dft: T): T =
    configs.getOrDefault(wc, dft)
  
  proc add*(c: WiishConfig, sub: T) =
    ## Attach an additional configuration object of type T to
    ## the given WiishConfig
    configs[c] = sub

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
  
  MacConfig* = ref object
    codesign_identity*: string
    bundle_id*: string
    info_plist_append*: string
  
  MacDesktopConfig* = ref object
    category_type*: string
  
  MaciOSConfig* = ref object
    sdk_version*: string
    simulator*: bool
    provisioning_profile*: string

  AndroidArchPair = tuple
    abi: string
    cpu: string

  AndroidConfig* = ref object
    java_package_name*: string
    archs*: seq[AndroidArchPair]
    min_sdk_version*: Natural
    target_sdk_version*: Natural

proc hash*(c: WiishConfig): Hash = c[].hash

extend(MacConfig)
extend(MacDesktopConfig)
extend(MaciOSConfig)
extend(AndroidConfig)

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

var wiishConfig* = default(WiishConfig)

proc default*(t: typedesc[MacConfig]): MacConfig = MacConfig(
  codesign_identity: "",
  bundle_identifier: "com.example.wiishdemo",
  info_plist_append: ""
)
proc default*(t: typedesc[MacDesktopConfig]): MacDesktopConfig = MacDesktopConfig(
  category_type: "",
)
proc default*(t: typedesc[MaciOSConfig]): MaciOSConfig = MaciOSConfig(
  sdk_version: "",
  simulator: false,
  provisioning_profile: "",
)
proc default*(t: typedesc[AndroidConfig]): AndroidConfig = AndroidConfig(
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
