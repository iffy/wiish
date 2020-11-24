import ./build; export build

proc wiishWebviewBuild*(step: BuildStep, ctx: ref BuildContext) =
  discard