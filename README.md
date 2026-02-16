# nim-playwright

Nim bindings for [Playwright](https://playwright.dev/) — browser automation and end-to-end testing with Chromium, Firefox, and WebKit.

## Prerequisites

- **Nim** 2.0+
- **Node.js** (for the Playwright driver)
- **Playwright browsers** — installed automatically when you run `nimble runExample`, or once by hand:

  ```bash
  npx playwright install chromium
  # or: npx playwright install   # all browsers
  ```

## Installation

```bash
nimble install nim_playwright
# or clone and use locally
nimble develop
```

> **Note:** The Nimble package name is `nim_playwright` (underscore). If the package is not yet on the [Nimble registry](https://github.com/nim-lang/packages), install from Git: `nimble install https://github.com/YOUR_ORG/nim-playwright`.

## Quick start

```nim
import playwright

var p = initPlaywright()
try:
  let browser = p.chromium.launch()
  let page = browser.newPage()
  page.goto("https://playwright.dev/")
  echo page.title()
  page.screenshot(path = "example.png")
  browser.close()
finally:
  p.close()
```

Run the example (from the project root). This installs Chromium if needed, then runs the script:

```bash
nimble runExample
# or manually: npx playwright install chromium && nim c -p:src -r examples/screenshot.nim
```

## API overview

- **`initPlaywright()`** – start the Playwright driver and return a `Playwright` instance. Call **`close()`** when done.
- **`p.chromium` / `p.firefox` / `p.webkit`** – get a `BrowserType`.
- **`browserType.launch(options?)`** – launch a browser (`LaunchOptions`: `headless`, `slowMo`, `timeout`).
- **`browser.newPage(options?)`** – create a new page.
- **`page.goto(url, options?)`** – navigate to a URL.
- **`page.title()`** – page title.
- **`page.screenshot(path=..., options?)`** – save a screenshot.
- **`browser.close()`** / **`page.close()`** – close resources.

## Driver

The library talks to the official Playwright driver over stdio (length-prefixed JSON). By default it runs:

```bash
npx -y playwright@latest run-driver
```

Override with the environment variable **`PLAYWRIGHT_NIM_DRIVER`** (e.g. point to a local `node` + script path).

## Tests

Unit tests (no browser/driver required):

```bash
nimble test
```

They cover wire protocol encoding/decoding, API JSON helpers, option types, and compile-time checks. See [CONTRIBUTING.md](CONTRIBUTING.md#running-tests) for the optional integration test.

## Development

- **Pre-commit:** `pip install pre-commit && pre-commit install` — runs `nim check` and common file checks on commit.
- **CI:** GitHub Actions runs on push/PR (build + unit tests).
- **Publishing to Nimble:** See [CONTRIBUTING.md](CONTRIBUTING.md#publishing-to-nimble).

## Status

Early stage. The wire protocol matches Playwright’s driver; more API methods and options can be added as needed. Contributions welcome.

## License

MIT
