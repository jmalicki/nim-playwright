# Package

version       = "0.1.0"
author        = "Joseph Malicki"
description   = "Nim bindings for Playwright - browser automation and testing"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 2.0.0"
requires "nimhttpd >= 1.0.0"

task buildServe, "Build static file server with ready signalling (for E2E)":
  exec "cp tools/style.css $(nimble path nimhttpd)/ 2>/dev/null || true"
  exec "nim c -o:tools/nimplaywright-serve -p:src tools/serve.nim"

task buildServeWait, "Build serve_wait launcher (block until server ready; Posix)":
  exec "nim c -o:tools/nimplaywright-serve-wait -p:src tools/serve_wait.nim"

task buildTools, "Build serve and serve_wait for E2E":
  exec "nimble buildServe"
  exec "nimble buildServeWait"

task test, "Run all unit tests (no driver required)":
  exec "nim c -p:src -r tests/run_tests.nim"

task testIntegration, "Run integration test (requires Node + Playwright driver)":
  exec "nim c -p:src -r tests/test_integration.nim"

task testE2e, "Install Chromium (if needed) and run E2E tests (real browser)":
  exec "npx -y playwright install chromium"
  exec "nim c -p:src -r tests/test_e2e.nim"

task runExample, "Install Chromium (if needed) and run the example script":
  exec "npx -y playwright install chromium"
  exec "nim c -p:src -r examples/screenshot.nim"
