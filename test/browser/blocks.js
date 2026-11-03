async function _verifyBlocks(page) {
  await page.bringToFront()
  page.setDefaultTimeout(10000)
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  await page.setViewportSize({ width: 1440, height: 1000 })
  await page.goto(`${origin}/blocks.html`)
  verify(
    await page.getByRole("heading", { name: "Blocks", exact: true }).isVisible(),
    "Blocks index opens",
  )

  for (const [id, title] of [
    ["application_header", "Application header"],
    ["mobile_navigation", "Mobile navigation"],
    ["global_search", "Global search"],
  ]) {
    await page.goto(`${origin}/blocks/${id}.html`)
    await page.locator('#palette-picker-trigger[aria-label^="Color palette:"]').waitFor()
    const frame = page.frameLocator(`iframe[title="${title} interactive preview"]`)
    await frame.locator("body").waitFor()
    verify((await page.locator("pre").count()) === 3, `${title} exposes ERB, CSS and JavaScript`)
    await page.getByRole("button", { name: "Mobile", exact: true }).click()
    verify(
      (await frame.locator("body").evaluate(() => innerWidth)) === 390,
      `${title} has a real mobile preview viewport`,
    )
    verify(
      await frame.locator("html").evaluate((node) => node.scrollWidth <= innerWidth),
      `${title} fits the mobile viewport`,
    )
    if (id === "application_header") {
      const menu = frame.getByRole("button", { name: "Workspace menu", exact: true })
      await menu.click()
      await frame.getByRole("menu", { name: "Workspace", exact: true }).waitFor()
      await page.keyboard.press("Escape")
      verify(
        (await menu.getAttribute("aria-expanded")) === "false",
        "Mobile header menu dismisses with Escape",
      )
    }
    if (id === "mobile_navigation") {
      await frame.getByRole("link", { name: "Notes", exact: true }).click()
      verify(
        await frame.getByLabel("Capture a thought").isVisible(),
        "Bottom navigation switches content",
      )
      const create = frame.getByRole("button", { name: "Create something", exact: true })
      await create.focus()
      await page.keyboard.press("Enter")
      await frame.getByRole("menuitem", { name: "New project", exact: true }).waitFor()
      await page.keyboard.press("Escape")
      verify(
        (await create.getAttribute("aria-expanded")) === "false",
        "Action stack dismisses with Escape",
      )
      await create.click()
      await frame.getByRole("menuitem", { name: "New project", exact: true }).click()
      verify(
        await frame.getByRole("heading", { name: "Untitled project", exact: true }).isVisible(),
        "Quick action creates a local draft",
      )
    }
    if (id === "global_search") {
      const trigger = frame.getByRole("button", { name: "Search workspace", exact: true })
      await trigger.click()
      const dialog = frame.getByRole("dialog", { name: "Search workspace", exact: true })
      await dialog.waitFor()
      const input = dialog.getByLabel("Search projects, people, and notes")
      await input.fill("no-such-workspace-item")
      verify(
        await dialog.getByText("Nothing here just yet.", { exact: true }).isVisible(),
        "Search shows an empty state",
      )
      await input.fill("Alex")
      verify(
        (await dialog.locator('[data-blocks-search-target="result"]:visible').count()) === 1,
        "Search filters sample results",
      )
      await page.keyboard.press("ArrowDown")
      await page.keyboard.press("Enter")
      await dialog.waitFor({ state: "hidden" })
      verify(
        (await frame.locator('[data-blocks-search-target="selectionTitle"]').textContent()) ===
          "Alex Lee",
        "Keyboard result selection opens the chosen item",
      )
      verify(
        await trigger.evaluate((node) => node === document.activeElement),
        "Search restores trigger focus",
      )
      await page.keyboard.press("Control+k")
      await dialog.waitFor()
      await dialog.getByRole("button", { name: "Clear search", exact: true }).click()
      verify((await input.inputValue()) === "", "Search clears the query")
      await page.keyboard.press("Escape")
      await dialog.waitFor({ state: "hidden" })
      checks.push("Search shortcut and Escape work")
    }
    const theme = page.getByRole("button", { name: /Switch to (light|dark) theme/ })
    await theme.click()
    await page.waitForFunction(() => {
      const frame = document.querySelector("iframe")
      return (
        frame.contentDocument.documentElement.dataset.theme ===
        document.documentElement.dataset.theme
      )
    })
    checks.push(`${title} follows the documentation theme`)
    await page.getByRole("button", { name: "Desktop", exact: true }).click()
    verify(
      (await frame.locator("body").evaluate(() => innerWidth)) > 390,
      `${title} restores the desktop preview`,
    )
  }

  return checks
}
