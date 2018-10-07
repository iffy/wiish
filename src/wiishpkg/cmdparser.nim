import macros
import strformat

type
  Parser[T] = object

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
  
template mkParser*(options: untyped): Parser =
  dumpTree:
    options
  processOptions:
    options
  let parser = Parser[string]()
  parser

proc parse*[T](p: Parser[T], input: string) =
  discard