## wiish command line interface

import strformat
import parseopt
import tables
import macros
import wiishpkg/build

#----------------------------------------------------
# Command parser
#----------------------------------------------------
type
  Parser = object
    commands*: Table[string, Parser]

proc newParser():Parser =
  result = Parser()

macro processOptions(options: untyped): untyped =
  echo "processOptions"
  result = newStmtList()

  for opt in options[0]:
    case opt.kind:
    of nnkCommand:
      let identNode = opt[0]
      assert identNode.kind == nnkIdent
      case identNode.strVal:
      of "command":
        let commandName = opt[1].strVal
        echo "command: ", commandName
      else:
        error(fmt"Unknown parser option: {identNode.strVal}")
    of nnkCall:
      let identNode = opt[0]
      assert identNode.kind == nnkIdent
      case identNode.strVal:
      of "flag":
        echo "flag"
        for i in 1..opt.len-1:
          if opt[i].kind == nnkStrLit:
            echo opt[i]
      else:
        error(fmt"Unknown parser call: {identNode.strVal}")
    else:
      error(fmt"Unknown parser thing: {opt.kind}")

template parser(options: untyped): untyped =
  dumpTree:
    options
  processOptions:
    options
  

parser:
  flag("-h", "--help", help = "something")

  command "build":
    flag("--mac", help = "Build for mac")
    run:
      echo "The result"



type
  Command = enum
    Default,
    Build,

if isMainModule:
  var
    p = initOptParser()
    subcommand: Command

  for kind, key, val in p.getopt():
    case subcommand:
    of Default:
      case kind:
      of cmdArgument:
        case key:
        of "build":
          subcommand = Build
        else:
          echo &"Unknown command: {key}"
          quit(1)
      of cmdShortOption, cmdLongOption:
        case key:
        of "h", "help":
          discard
        else:
          echo &"Invalid argument: {key} {val}"
      of cmdEnd:
        discard
      else:
        echo &"Invalid argument: {key} {val}"
        quit(1)
    of Build:
      case kind
      of cmdEnd:
        discard
      else:
        echo &"Invalid argument: {key} {val}"
        quit(1)
  
  case subcommand:
  of Default:
    echo "No command given; run with --help for usage"
    quit(1)
  of Build:
    discard
  echo "Subcommand: ", subcommand


