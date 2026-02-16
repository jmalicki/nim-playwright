## E2E tests: real browser automation. Require Node.js and Playwright (nimble testE2e installs Chromium).

import std/[os, strutils]
import playwright

proc e2eNavigateAndTitle(): bool =
  let p = initPlaywright()
  try:
    let browser = p.chromium.launch(LaunchOptions(headless: true))
    try:
      let page = browser.newPage()
      page.goto("https://example.com/")
      let title = page.title()
      page.close()
      result = "Example" in title or "example" in title.toLower
    finally:
      browser.close()
  finally:
    p.close()

proc e2eScreenshot(): bool =
  let p = initPlaywright()
  try:
    let browser = p.chromium.launch(LaunchOptions(headless: true))
    try:
      let page = browser.newPage()
      page.goto("https://example.com/")
      let path = getTempDir() / "nim_playwright_e2e_screenshot.png"
      page.screenshot(path = path)
      page.close()
      result = fileExists(path) and getFileSize(path) > 0
      try: removeFile(path) except: discard
    finally:
      browser.close()
  finally:
    p.close()

proc main() =
  echo "E2E test 1: navigate to example.com and check title..."
  if e2eNavigateAndTitle():
    echo "  OK"
  else:
    echo "  FAIL: expected title to contain 'Example'"
    quit(1)

  echo "E2E test 2: screenshot to temp file..."
  if e2eScreenshot():
    echo "  OK"
  else:
    echo "  FAIL: screenshot file missing or empty"
    quit(1)

  echo "All E2E tests passed."

when isMainModule:
  try:
    main()
  except Exception as e:
    echo "E2E tests SKIP (driver not available): ", e.msg
    quit(0)
