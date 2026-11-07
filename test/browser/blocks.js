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
  ]) {
    await page.goto(`${origin}/blocks/${id}.html`)
    await page.locator('#palette-picker-trigger[aria-label^="Color palette:"]').waitFor()
    const frame = page.frameLocator(`iframe[title="${title} interactive preview"]`)
    await frame.locator("body").waitFor()
    const files = { application_header: 1, docs_shell: 1, mobile_navigation: 2 }[id]
    verify(
      (await page.locator("pre").count()) === files,
      `${title} exposes its ${files} example files`,
    )
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
