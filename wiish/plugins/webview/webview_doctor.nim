## Webview plugin doctor
import wiish/building/buildutil
import wiish/doctor

when defined(linux):
  import distros
  import osproc
  import strformat

proc checkDoctor*(): seq[DoctorResult] =
  when defined(linux):
    # TODO: make this work for other distors
    let packages = [
      ("gtk+-3.0", "libgtk-3-dev"),
      ("webkit2gtk-4.0", "libwebkit2gtk-4.0-dev"),
    ]
    for (name, installname) in packages:
      result.dr "webview", name:
        dr.targetOS = {Linux}
        if execCmdEx("pkg-config --cflags " & name).exitCode != 0:
          dr.status = NotWorking
          dr.error = &"Missing library {name}"
          dr.fix = "Maybe this will work:\l\l  "
          let cmd = foreignDepInstallCmd(installname)
          if cmd[1]:
            dr.fix.add "sudo "
          dr.fix.add cmd[0]
