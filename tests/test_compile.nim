## Compile-time tests: ensure the package builds and types are available.
## Run with: nimble test

import playwright

static:
  doAssert compiles(initPlaywright())
  doAssert compiles(LaunchOptions(headless: true))
  doAssert compiles(LaunchOptions())
  doAssert compiles(NewPageOptions())
  doAssert compiles(GotoOptions())
  doAssert compiles(ScreenshotOptions())
  # Type usage
  doAssert compiles(Playwright())
  doAssert compiles(BrowserType())
  doAssert compiles(Browser())
  doAssert compiles(Page())
  doAssert compiles(BrowserContext())

when isMainModule:
  echo "test_compile: OK"
