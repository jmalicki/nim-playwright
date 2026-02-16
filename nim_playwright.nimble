# Package

version       = "0.1.0"
author        = "Joseph Malicki"
description   = "Nim bindings for Playwright - browser automation and testing"
license       = "MIT"
srcDir        = "src"

# Dependencies
requires "nim >= 2.0.0"

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
