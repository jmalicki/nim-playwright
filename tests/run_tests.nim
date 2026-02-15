## Single entry point to run all unit tests (no driver required).
## Usage: nim c -p:src -r tests/run_tests.nim

import std/[osproc, os]

proc run(cmd: string): bool =
  let (output, exitCode) = execCmdEx(cmd, options = {poUsePath})
  echo output
  exitCode == 0

proc main() =
  let srcDir = currentSourcePath().parentDir().parentDir() / "src"
  let p = "-p:" & srcDir
  var failed = false
  for name in ["test_compile", "test_wire", "test_api"]:
    let path = currentSourcePath().parentDir() / (name & ".nim")
    if run("nim c " & p & " " & path) and run("nim c " & p & " -r " & path):
      echo ""
    else:
      failed = true
  if failed:
    quit(1)
  echo "All tests passed."

main()
