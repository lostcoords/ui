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
      [...document.querySelectorAll("dialog[open] [data-slot=search-result]")]
        .filter((result) => result.checkVisibility())
        .map((result) => result.getAttribute("href")),
    )

  const ready = () =>
    page.waitForFunction(() => {
      const application = window.Stimulus
      if (!application) return false
      return [
        ...document.querySelectorAll(
          "[data-controller~=docs-search], [data-controller~=lc-search]",
        ),
      ].every((element) =>
        element.dataset.controller
          .split(/\s+/)
          .every((name) => application.getControllerForElementAndIdentifier(element, name)),
      )
    })
  await page.goto(`${origin}/installation.html`)
  await ready()
  const trigger = page.getByRole("button", { name: "Search documentation" })
  await trigger.click()
  const input = page.getByRole("searchbox", { name: "Search documentation" })
  await page.waitForFunction(() => document.querySelector("dialog[open] [data-slot=search-result]"))
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
      [...document.querySelectorAll("dialog[open] [data-slot=search-result] mark")].some((mark) =>
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
  verify(
    await page.getByText("No results", { exact: true }).isVisible(),
    "A query with no results says so",
  )
  verify(
    (await page.getByRole("status").filter({ hasText: "0 results" }).count()) === 1,
    "The result count is announced",
  )

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

  // lc_search filtering the rows rendered in its block, on its own docs page.
  await page.goto(`${origin}/components/search.html`)
  await ready()
  const example = page.getByRole("button", { name: "Search the workspace", exact: true })
  await example.click()
  const dialog = page.getByRole("dialog", { name: "Search the workspace", exact: true })
  await dialog.waitFor()
  const field = dialog.getByRole("searchbox")
  verify(
    (await dialog.locator("[data-slot=search-result]:visible").count()) === 4,
    "An empty query shows every row in the block",
  )
  await field.fill("no-such-workspace-item")
  verify(
    await dialog.getByText("Nothing matches no-such-workspace-item", { exact: true }).isVisible(),
    "Filtering shows the empty note with the query",
  )
  await field.fill("brand")
  verify(
    (await dialog.locator("[data-slot=search-result]:visible").allTextContents())
      .join(" ")
      .includes("Fieldwork") &&
      (await dialog.locator("[data-slot=search-group]:visible").count()) === 1,
    "Keywords match, and groups without a match hide",
  )
  await field.fill("alex")
  await page.keyboard.press("Enter")
  await page.waitForURL(/#alex-lee$/)
  verify(true, "Enter opens the only result")
  await dialog.waitFor({ state: "hidden" })
  await page.keyboard.press("Shift+Tab")
  await example.click()
  await dialog.getByRole("button", { name: "Clear search", exact: true }).click()
  verify((await field.inputValue()) === "", "Clear empties the field")
  await page.keyboard.press("Escape")
  await dialog.waitFor({ state: "hidden" })
  verify(
    await example.evaluate((node) => node === document.activeElement),
    "Closing returns focus to the trigger",
  )

  // The same search answered by a server: the notes wait for the answer instead of flashing.
  let answer = null
  await page.route(
    (url) => url.pathname === "/remote-search",
    async (route) => {
      await new Promise((resolve) => (answer = resolve))
      const query = new URL(route.request().url()).searchParams.get("q")
      await route.fulfill({
        contentType: "text/html",
        body:
          query === "field"
            ? '<a data-slot="search-result" data-lc-search-target="result" href="#fieldwork">Fieldwork</a>'
            : "",
      })
    },
  )
  await page.evaluate(() => {
    document.querySelector(
      "[data-slot=search]:has(dialog[aria-label='Search the workspace'])",
    ).dataset.lcSearchSrcValue = "/remote-search"
  })
  await example.click()
  await field.fill("nothing-here")
  await page.waitForFunction(() =>
    document.querySelector("dialog[open] [data-slot=search-panel][aria-busy=true]"),
  )
  verify(
    !(await dialog.locator("[data-slot=search-empty]").isVisible()),
    "While the server answers, the empty note waits",
  )
  answer()
  await dialog.getByText("Nothing matches nothing-here", { exact: true }).waitFor()
  verify(true, "An empty answer shows the empty note")
  await field.fill("field")
  await page.waitForFunction(() =>
    document.querySelector("dialog[open] [data-slot=search-panel][aria-busy=true]"),
  )
  answer()
  await dialog.locator("a[href='#fieldwork']").waitFor()
  verify(
    !(await dialog.locator("[data-slot=search-empty]").isVisible()),
    "Results from the server replace the note",
  )

  return checks
}
