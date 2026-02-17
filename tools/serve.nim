## Static file server with ready signalling for E2E. Uses nimhttpd as a library.
## When PLAYWRIGHT_SERVE_READY_FD is set, writes one byte when listening so
## serve_wait can return without polling. Usage: serve -p:PORT DIRECTORY

import std/[asyncdispatch, mimetypes, os, parseopt, strutils]
import std/httpcore
import nimhttpd

when defined(posix):
  import std/posix

const
  address4 = "127.0.0.1"
  address6 = "0:0:0:0:0:0:0:1"

proc main() =
  var port = 1337
  var directory = getCurrentDir()

  for kind, key, val in getopt():
    case kind
    of cmdShortOption, cmdLongOption:
      if key == "p" and val.len > 0:
        try:
          port = val.parseInt
        except ValueError:
          quit(2)
    of cmdArgument:
      if key.dirExists:
        directory = key.expandFilename
    else:
      discard

  var settings: NimHttpSettings
  settings.directory = directory
  settings.port = Port(port)
  settings.address4 = address4
  settings.address6 = address6
  settings.name = "NimHTTPd"
  settings.version = "1.5.1"
  settings.title = "Index"
  settings.logging = false
  settings.mimes = newMimeTypes()
  settings.mimes.register("htm", "text/html")
  settings.headers = newHttpHeaders()

  serve(settings)

  when defined(posix):
    let readyFdStr = getEnv("PLAYWRIGHT_SERVE_READY_FD")
    if readyFdStr.len > 0:
      try:
        let readyFd = readyFdStr.parseInt.cint
        asyncCheck (proc() {.async.} =
          await sleepAsync(150)
          var byte: char = 'x'
          discard posix.write(readyFd, byte.addr, 1)
          discard posix.close(readyFd)
        )()
      except ValueError:
        discard

  runForever()

when isMainModule:
  main()
