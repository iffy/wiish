
import unittest

import wiishpkg/cmdparser

test "can parse flags":
  var p = mkParser:
    flag("-h", "--help", help = "something")
    flag("-a")
  
  check p.parse("-a").a == true
  check p.parse("--help").help == true
  check p.parse("-h").help == true

test "can parse string opts":
  var p = mkParser:
    opt("-o", string)
  
  check p.parse("-o hello").o == "hello"