## Nim bindings for Playwright
##
## Browser automation and end-to-end testing with Chromium, Firefox, and WebKit.
## Requires Node.js and Playwright installed (e.g. `npm init playwright@latest` or `npx playwright install`).
##
## Example:
##   .. code-block:: nim
##     import playwright
##     var p = initPlaywright()
##     try:
##       let browser = p.chromium.launch()
##       let page = browser.newPage()
##       page.goto("https://playwright.dev/")
##       echo page.title()
##       page.screenshot(path = "example.png")
##       browser.close()
##     finally:
##       p.close()

import playwright/private/api

export api
