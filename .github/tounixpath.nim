import os
import strutils

func toUnix(path: string): string =
  if ":" in path or "\\" in path:
    result.add "/"
    result.add path.replace(r":\", "/").replace(r"\", "/")
  else:
    result = path.normalizedPath()

when isMainModule:
  echo paramStr(1).toUnix()
