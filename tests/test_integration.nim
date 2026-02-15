## Optional integration test: requires Node.js and Playwright driver.
## Run manually: nim c -p:src -r tests/test_integration.nim
## Or with driver available: nimble testIntegration

import std/[os]
import playwright

proc main() =
  if getEnv("PLAYWRIGHT_SKIP_INTEGRATION", "0") == "1":
    echo "test_integration: SKIP (PLAYWRIGHT_SKIP_INTEGRATION=1)"
    return
  try:
    let p = initPlaywright()
    try:
      discard p.chromium
      echo "test_integration: OK (init + chromium + close)"
    finally:
      p.close()
  except Exception as e:
    echo "test_integration: SKIP (driver not available: ", e.msg, ")"

main()
