import unittest
import strutils
import os
import osproc

proc nimcheck(args: varargs[string]) =
  var cmd = @["nim", "check", "--hints:off", "-d:testconcepts"]
  cmd.add(args)
  let rc = execCmd(cmd.join(" "))
  if rc != 0:
    raise ValueError.newException("Error")

suite "SDL":
  test "macOS":
    nimcheck "--os:macosx", "examples"/"sdl2"/"main_desktop.nim"
  test "linux":
    nimcheck "--os:linux", "examples"/"sdl2"/"main_desktop.nim"
  test "windows":
    nimcheck "--os:windows", "examples"/"sdl2"/"main_desktop.nim"