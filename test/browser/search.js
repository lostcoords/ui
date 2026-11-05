async function _verifySearch(page) {
  await page.bringToFront()
  await page.setViewportSize({ width: 1440, height: 900 })
  page.setDefaultTimeout(10000)
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const visible = () =>
    page.evaluate(() =>
      [...document.querySelectorAll("[data-docs-search-target=result]")]
        .filter((result) => result.checkVisibility())
        .map((result) => result.getAttribute("href")),
    )

  const ready = () =>
    page.waitForFunction(async () => {
      const { application } = await import("controllers/application")
      const element = document.querySelector("[data-controller~=docs-search]")
      return application.getControllerForElementAndIdentifier(element, "docs-search")
    })
  await page.goto(`${origin}/installation.html`)
  await ready()
  const trigger = page.getByRole("button", { name: "Search documentation" })
  await trigger.click()
  const input = page.getByRole("searchbox", {
    name: "Search components, helpers, guides and blocks",
  })
  await page.waitForFunction(() => document.querySelector("[data-docs-search-target=result]"))
  verify(
    await input.evaluate((element) => element === document.activeElement),
    "Opening search focuses the field",
  )
  verify(
    (await visible()).every((href) => !href.includes("#")),
    "An empty query lists the guide pages",
  )

  await input.fill("dialog")
  const results = await visible()
  verify(results[0] === "/components/dialog.html", "Typing a component name ranks its page first")
  verify(
    results.includes("/components/dialog.html#lc_dialog"),
    "Helpers appear alongside components",
  )

  await input.fill("lc_button")
  verify(
    (await visible()).some((href) => href.endsWith("#lc_button")),
    "Helper names match with underscores",
  )

  await input.fill("buton")
  verify((await visible()).includes("/components/button.html"), "A typo still finds the component")

  await input.fill("lazyLoadControllersFrom")
  verify(
    (await visible()).includes("/installation.html#javascript"),
    "Words in a page's text find the section that holds them",
  )
  verify(
    await page.evaluate(() =>
      [...document.querySelectorAll("[data-docs-search-target=result] mark")].some((mark) =>
        /lazyloadcontrollersfrom/i.test(mark.textContent),
      ),
    ),
    "A text match shows an excerpt with the words marked",
  )

  await input.fill("icon_position")
  verify(
    (await visible()).includes("/components/button.html#lc_button"),
    "Helper options find the helper",
  )

  await input.fill("zzzz nothing")
  verify(await page.getByText("No matches.").isVisible(), "A query with no results says so")

  await input.fill("switch themes")
  await page.keyboard.press("ArrowDown")
  verify(
    await page.evaluate(
      () => document.activeElement.getAttribute("href") === "/theming.html#dark-mode",
    ),
    "Arrow Down moves to the first result",
  )
  await page.keyboard.press("ArrowUp")
  await page.keyboard.press("Enter")
  await page.waitForURL(/theming\.html#dark-mode$/)
  verify(true, "Enter in the field opens the top result")
  await ready()

  await page.keyboard.press(process.platform === "darwin" ? "Meta+k" : "Control+k")
  await page.waitForFunction(
    () => document.querySelector("dialog[aria-label='Search documentation']").open,
  )
  verify(true, "The keyboard shortcut opens search")
  await page.keyboard.press("Escape")
  await page.waitForFunction(
    () => !document.querySelector("dialog[aria-label='Search documentation']").open,
  )
  verify(true, "Escape closes search")

  return checks
}
