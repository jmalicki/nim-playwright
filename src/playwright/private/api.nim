## High-level Playwright API: Playwright, BrowserType, Browser, Page.

import std/json
import wire

type
  LaunchOptions* = object
    headless*: bool
    slowMo*: int
    timeout*: float

  NewPageOptions* = object
    viewport*: tuple[width, height: int]
    ignoreHttpsErrors*: bool

  GotoOptions* = object
    timeout*: float
    waitUntil*: string

  ScreenshotOptions* = object
    path*: string
    fullPage*: bool

  Playwright* = ref object
    driver: Driver
    guid: string

  BrowserType* = ref object
    driver: Driver
    guid: string
    name: string

  Browser* = ref object
    driver: Driver
    guid: string

  BrowserContext* = ref object
    driver: Driver
    guid: string

  Page* = ref object
    driver: Driver
    guid: string
    mainFrameGuid*: string  ## Set from newPage response when available

  Frame* = ref object
    driver: Driver
    guid: string

proc getStrFromJson*(j: JsonNode; key: string): string =
  ## Extract string or guid from JSON (for wire results). Exported for tests.
  if j != nil and j.hasKey(key):
    let v = j[key]
    if v.kind == JString: return v.getStr()
    if v.kind == JObject and v.hasKey("guid"): return v["guid"].getStr()
  return ""

proc getStr(j: JsonNode; key: string): string = getStrFromJson(j, key)

proc initPlaywright*(): Playwright =
  let driver = startDriver()
  # Root has guid ""; call initialize to get Playwright object.
  var params = newJObject()
  params["sdkLanguage"] = %"nim"
  let res = driver.call("", "initialize", params)
  let pw = res.getOrDefault("playwright")
  result = Playwright(driver: driver, guid: pw.getStr("guid"))

proc close*(p: Playwright) =
  if p.driver != nil:
    p.driver.close()
    p.driver = nil

proc chromium*(p: Playwright): BrowserType =
  let res = p.driver.call(p.guid, "chromium", newJObject())
  BrowserType(driver: p.driver, guid: res.getStr("browserType"),
      name: "chromium")

proc firefox*(p: Playwright): BrowserType =
  let res = p.driver.call(p.guid, "firefox", newJObject())
  BrowserType(driver: p.driver, guid: res.getStr("browserType"),
      name: "firefox")

proc webkit*(p: Playwright): BrowserType =
  let res = p.driver.call(p.guid, "webkit", newJObject())
  BrowserType(driver: p.driver, guid: res.getStr("browserType"), name: "webkit")

proc launch*(bt: BrowserType; options: LaunchOptions = LaunchOptions()): Browser =
  var params = newJObject()
  params["headless"] = %options.headless
  if options.slowMo > 0: params["slowMo"] = %options.slowMo
  if options.timeout > 0: params["timeout"] = %options.timeout
  let res = bt.driver.call(bt.guid, "launch", params)
  Browser(driver: bt.driver, guid: res.getStr("browser"))

proc newPage*(b: Browser; options: NewPageOptions = NewPageOptions()): Page =
  var params = newJObject()
  if options.viewport.width > 0:
    params["viewport"] = %* {"width": options.viewport.width,
        "height": options.viewport.height}
  if options.ignoreHttpsErrors: params["ignoreHTTPSErrors"] = %true
  let res = b.driver.call(b.guid, "newPage", params)
  let pageObj = res.getOrDefault("page")
  let pageGuid = if pageObj.kind == JString: pageObj.getStr() else: getStr(pageObj, "guid")
  if pageGuid.len == 0: return Page(driver: b.driver, guid: res.getStr("page"), mainFrameGuid: "")
  let frameGuid = if pageObj.kind == JObject:
    getStr(pageObj.getOrDefault("mainFrame"), "guid") else: ""
  Page(driver: b.driver, guid: pageGuid, mainFrameGuid: frameGuid)

proc newContext*(b: Browser): BrowserContext =
  let res = b.driver.call(b.guid, "newContext", newJObject())
  BrowserContext(driver: b.driver, guid: res.getStr("context"))

proc close*(b: Browser) =
  discard b.driver.call(b.guid, "close", newJObject())

proc goto*(page: Page; url: string; options: GotoOptions = GotoOptions()) =
  var params = newJObject()
  params["url"] = %url
  if options.timeout > 0: params["timeout"] = %options.timeout
  if options.waitUntil.len > 0: params["waitUntil"] = %options.waitUntil
  discard page.driver.call(page.guid, "goto", params)

proc title*(page: Page): string =
  let res = page.driver.call(page.guid, "title", newJObject())
  if res != nil and res.kind == JString: return res.getStr()
  if res != nil and res.hasKey("value"): return res["value"].getStr()
  return ""

proc screenshot*(page: Page; path: string = "";
    options: ScreenshotOptions = ScreenshotOptions()) =
  var params = newJObject()
  if path.len > 0: params["path"] = %path
  if options.path.len > 0: params["path"] = %options.path
  if options.fullPage: params["fullPage"] = %true
  discard page.driver.call(page.guid, "screenshot", params)

proc close*(page: Page) =
  discard page.driver.call(page.guid, "close", newJObject())

proc mainFrame*(page: Page): Frame =
  ## Return the main frame of the page (for click by selector).
  if page.mainFrameGuid.len > 0:
    return Frame(driver: page.driver, guid: page.mainFrameGuid)
  let res = page.driver.call(page.guid, "mainFrame", newJObject())
  let frameGuid = res.getStr("frame")
  let guid = if frameGuid.len > 0: frameGuid else: res.getStr("guid")
  Frame(driver: page.driver, guid: guid)

proc click*(frame: Frame; selector: string) =
  ## Click the element matching the selector.
  var params = newJObject()
  params["selector"] = %selector
  discard frame.driver.call(frame.guid, "click", params)

proc waitForSelector*(frame: Frame; selector: string; timeout: float = 5000) =
  ## Wait for an element matching the selector to appear.
  var params = newJObject()
  params["selector"] = %selector
  if timeout > 0: params["timeout"] = %timeout
  discard frame.driver.call(frame.guid, "waitForSelector", params)

proc newPage*(ctx: BrowserContext): Page =
  let res = ctx.driver.call(ctx.guid, "newPage", newJObject())
  let pageObj = res.getOrDefault("page")
  let pageGuid = if pageObj.kind == JString: pageObj.getStr() else: getStr(pageObj, "guid")
  let frameGuid = if pageObj.kind == JObject:
    getStr(pageObj.getOrDefault("mainFrame"), "guid") else: ""
  Page(driver: ctx.driver, guid: if pageGuid.len > 0: pageGuid else: res.getStr("page"), mainFrameGuid: frameGuid)
