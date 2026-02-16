# Contributing

## Development setup

- Nim 2.0+
- Install [pre-commit](https://pre-commit.com/): `pip install pre-commit && pre-commit install`

## Pre-commit hooks

Hooks run on `git commit` and ensure:

- **nim check** – package compiles and passes semantic checks
- Trailing whitespace, EOF newline, YAML check, etc.

Optionally format code with: `nimpretty src/playwright.nim src/playwright/private/*.nim examples/*.nim tests/*.nim`

Run manually: `pre-commit run --all-files`

## Running tests

Unit tests (no Node/Playwright required):

```bash
nimble test
# or (if nimble reports VCS error before first commit): nim c -p:src -r tests/run_tests.nim
```

- **test_compile.nim** – compile-time checks and type availability
- **test_wire.nim** – wire protocol encode/decode (length-prefixed frames)
- **test_api.nim** – `getStrFromJson` and option types

Integration test (driver only):

```bash
nimble testIntegration
```

E2E tests (real browser – installs Chromium if needed):

```bash
nimble testE2e
```

These open example.com, check the page title, and take a screenshot. If the driver isn’t available, the E2E script exits with code 0 and prints SKIP.

## CI

On push/PR to `main` or `master`, GitHub Actions:

1. **Test** – `nim check`, build package, build example, `nimble test`
2. **Lint** – `nimpretty --check` on all tracked Nim sources

## Publishing to Nimble

The package name is **nim_playwright** (Nimble disallows hyphens). To publish to the [official Nimble package list](https://github.com/nim-lang/packages):

1. **Tag a release** (e.g. `v0.1.0`) and push to GitHub.
2. **Add the package to the registry**:
   - Fork [nim-lang/packages](https://github.com/nim-lang/packages)
   - Edit `packages.json` and add an entry (see existing entries for format), e.g.:

   ```json
   {
     "name": "nim_playwright",
     "url": "https://github.com/YOUR_USER/nim-playwright",
     "method": "git",
     "tags": ["playwright", "browser", "automation", "testing", "chromium", "firefox", "webkit"],
     "description": "Nim bindings for Playwright - browser automation and testing",
     "license": "MIT",
     "web": "https://github.com/YOUR_USER/nim-playwright"
   }
   ```

   Use the repo URL where the package is hosted (replace `YOUR_USER`).

3. Open a PR against `nim-lang/packages`. After merge, users can run:

   ```bash
   nimble install nim_playwright
   ```

For version updates, tag a new release; Nimble installs by default from the latest tag (or `#head` for development).
