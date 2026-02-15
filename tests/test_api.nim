## Tests for API helpers (getStrFromJson) and option types. No driver required.

import std/[json]
import playwright/private/api

proc main() =
  # getStrFromJson: missing key
  doAssert getStrFromJson(newJObject(), "x") == ""
  doAssert getStrFromJson(nil, "x") == ""

  # getStrFromJson: string value
  doAssert getStrFromJson(%* {"title": "Hello"}, "title") == "Hello"

  # getStrFromJson: object with guid (wire format)
  doAssert getStrFromJson(%* {"playwright": {"guid": "pw-1"}}, "playwright") == "pw-1"
  doAssert getStrFromJson(%* {"browserType": {"guid": "bt-1"}}, "browserType") == "bt-1"
  doAssert getStrFromJson(%* {"browser": {"guid": "b-1"}}, "browser") == "b-1"
  doAssert getStrFromJson(%* {"page": {"guid": "p-1"}}, "page") == "p-1"
  doAssert getStrFromJson(%* {"context": {"guid": "c-1"}}, "context") == "c-1"

  # Option types: default construction
  let launchOpt = LaunchOptions()
  doAssert launchOpt.headless == false
  doAssert launchOpt.slowMo == 0
  doAssert launchOpt.timeout == 0.0

  doAssert LaunchOptions(headless: true).headless == true
  doAssert LaunchOptions(slowMo: 100).slowMo == 100

  let pageOpt = NewPageOptions()
  doAssert pageOpt.viewport.width == 0
  doAssert pageOpt.viewport.height == 0
  doAssert pageOpt.ignoreHttpsErrors == false

  let gotoOpt = GotoOptions()
  doAssert gotoOpt.timeout == 0.0
  doAssert gotoOpt.waitUntil == ""

  let screenOpt = ScreenshotOptions()
  doAssert screenOpt.path == ""
  doAssert screenOpt.fullPage == false

  echo "test_api: OK"

main()
