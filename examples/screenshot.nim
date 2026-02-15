## Example: launch Chromium, open a page, take a screenshot.
## Requires: Node.js, and run `npx playwright install chromium` once.

## Run from project root: nim c -p:src -r examples/screenshot.nim

import playwright

proc main() =
  let p = initPlaywright()
  try:
    let browser = p.chromium.launch(LaunchOptions(headless: true))
    try:
      let page = browser.newPage()
      page.goto("https://playwright.dev/")
      echo "Title: ", page.title()
      page.screenshot(path = "playwright-nim-example.png")
      echo "Screenshot saved to playwright-nim-example.png"
      page.close()
    finally:
      browser.close()
  finally:
    p.close()

main()
