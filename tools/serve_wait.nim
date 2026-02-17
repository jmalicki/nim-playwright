## Launcher: start the serve binary with a ready pipe, block until server has signalled
## (or failed). Does not return until ready or failure. On success: prints "PORT PID"
## to stdout and exits 0. On failure: exits non-zero. Unix only (pipe/dup2).
## Usage: serve_wait [DIRECTORY]  (default directory: current dir)
## Server binary: PLAYWRIGHT_SERVE_BIN (default: nimplaywright-serve)

import std/[net, os, osproc]

when defined(posix):
  import std/posix
else:
  echo "serve_wait requires Posix (pipe signalling)"
  quit(1)

const readyFdNum = 10

proc findFreePort(): Port =
  let sock = newSocket()
  try:
    sock.bindAddr(Port(0), "127.0.0.1")
    let (_, port) = sock.getLocalAddr()
    return port
  finally:
    sock.close()

proc main(): int =
  when defined(posix):
    let directory = if paramCount() >= 1: paramStr(1) else: "."
    let serverBin = getEnv("PLAYWRIGHT_SERVE_BIN", "nimplaywright-serve")

    let port = findFreePort()
    var fds: array[0..1, cint]
    if posix.pipe(fds) != 0:
      echo "serve_wait: pipe failed"
      return 1
    let readFd = fds[0]
    let writeFd = fds[1]

    if posix.dup2(writeFd, readyFdNum.cint) < 0:
      echo "serve_wait: dup2 failed"
      discard posix.close(readFd)
      discard posix.close(writeFd)
      return 1
    discard posix.close(writeFd)

    putEnv("PLAYWRIGHT_SERVE_READY_FD", $readyFdNum)
    let serverProc = startProcess(
      serverBin,
      args = ["-p:" & $port.uint16, directory],
      options = {poUsePath}
    )
    discard posix.close(readyFdNum.cint)

    var buf: array[1, char]
    let n = posix.read(readFd, buf[0].addr, 1)
    discard posix.close(readFd)

    if n > 0:
      echo port.uint16, " ", serverProc.processID()
      return 0

    let code = serverProc.waitForExit()
    if code != 0:
      return code
    return 1
  else:
    return 1

when isMainModule:
  quit(main())
