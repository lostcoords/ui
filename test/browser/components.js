async function _verifyComponents(page) {
  await page.bringToFront()
  await page.setViewportSize({ width: 1440, height: 900 })
  page.setDefaultTimeout(10000)
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const visit = async (component) => {
    await page.goto(`${origin}/components/${component}.html`)
    await page.locator('[data-controller~="showcase"]').waitFor()
    await page.locator('#palette-picker-trigger[aria-label^="Color palette:"]').waitFor()
  }

  await visit("button")
  const form = page.locator('[data-controller="example"] form').first()
  await form.locator("button").click()
  verify(page.url().endsWith("button.html"), "Example forms stay on the docs page")
  verify(
    (await page.locator("pre").allTextContents()).some((source) => source.includes("ui_button_to")),
    "Copied examples use the render API",
  )

  await visit("segmented")
  const selected = page
    .locator('[data-controller="example"]')
    .first()
    .locator('[data-ui-selection-target="option"][aria-pressed="true"]')
  await selected.focus()
  await page.keyboard.press("ArrowRight")
  verify(
    (await page.locator('input[name="view"]').inputValue()) === "year",
    "Keyboard selection updates the native form value",
  )
  verify((await selected.count()) === 1, "A segmented group keeps exactly one selected option")

  await page.getByRole("button", { name: "Annual", exact: true }).click()
  verify(
    (await page.locator('input[name="billing"]').inputValue()) === "annual",
    "A selected option submits its value",
  )
  await page.getByRole("button", { name: "Reset", exact: true }).click()
  verify(
    (await page.locator('input[name="billing"]').inputValue()) === "monthly",
    "Native form reset restores the initial selection",
  )
  verify(
    await page.getByRole("button", { name: "Custom", exact: true }).isDisabled(),
    "Disabled choices stay disabled",
  )

  await visit("pill")
  const pill = page.getByRole("button", { name: "Writing", exact: true }).first()
  await pill.click()
  verify((await pill.getAttribute("aria-pressed")) === "true", "Pill buttons expose pressed state")

  await visit("menu")
  const menuTrigger = page.getByRole("button", { name: "Project actions", exact: true })
  await menuTrigger.focus()
  await page.keyboard.press("Enter")
  await page.getByRole("menu").waitFor({ state: "visible" })
  verify(
    await page.evaluate(() => document.activeElement?.getAttribute("role") === "menuitem"),
    "Keyboard opening focuses the first menu item",
  )
  await page.keyboard.press("Escape")
  verify((await menuTrigger.getAttribute("aria-expanded")) === "false", "Escape closes the menu")
  verify(
    await menuTrigger.evaluate((node) => node === document.activeElement),
    "Escape restores menu trigger focus",
  )

  await visit("popover")
  const popoverTrigger = page.getByRole("button", { name: "Project details", exact: true })
  await popoverTrigger.focus()
  await page.keyboard.press("Enter")
  await page.getByRole("dialog", { name: "Design system" }).waitFor({ state: "visible" })
  verify(
    await page.evaluate(() => document.activeElement?.getAttribute("role") === "dialog"),
    "A text popover receives keyboard focus",
  )
  await page.keyboard.press("Escape")
  verify(
    (await popoverTrigger.getAttribute("aria-expanded")) === "false",
    "Escape closes the popover",
  )

  for (const width of [1440, 390]) {
    await page.setViewportSize({ width, height: 900 })
    await visit("dialog")
    await page.getByRole("button", { name: "New project", exact: true }).click()
    const dialog = page.getByRole("dialog", { name: "Create project" })
    await dialog.waitFor({ state: "visible" })
    verify(
      await dialog.evaluate((node) => node.matches(":modal")),
      `Dialog opens natively at ${width}px`,
    )
    verify(
      (await dialog.getAttribute("data-controller")) === "sheet",
      `Dialog has responsive sheet behavior at ${width}px`,
    )
    await dialog.getByRole("textbox", { name: "Project name" }).fill("A project")
    await dialog.getByRole("button", { name: "Create project", exact: true }).click()
    await dialog.waitFor({ state: "hidden" })
    checks.push(`Native dialog form closes at ${width}px`)
  }

  await visit("disclosure")
  const details = page.locator("main details").first()
  await details.locator("summary").click()
  verify(
    (await details.getAttribute("open")) !== null,
    "Disclosure expands through its native summary",
  )

  await visit("toast")
  verify(
    (await page.getByRole("status").filter({ hasText: "Project saved." }).count()) === 1,
    "A zero-timeout toast remains visible",
  )

  await page.goto(origin)
  verify(
    await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth),
    "Home has no horizontal overflow on mobile",
  )
  await page.locator("#palette-picker-trigger").click()
  await page.getByText("Rose & garnet", { exact: true }).click()
  await page.keyboard.press("Escape")
  await page.reload()
  verify(
    (await page.locator("html").getAttribute("data-palette")) === "rose",
    "Palette survives reload",
  )
  verify(
    (await page.evaluate(() => localStorage.getItem("lostcoords-ui:palette"))) === "rose",
    "Palette uses persistent host-local state",
  )
  await page.locator("#palette-picker-trigger").focus()
  await page.keyboard.press("Enter")
  verify(
    await page.evaluate(() => document.activeElement?.value === "rose"),
    "Keyboard palette opening focuses the current choice",
  )
  await page.keyboard.press("Escape")
  const wasDark = (await page.locator("html").getAttribute("data-theme")) === "dark"
  await page.getByRole("button", { name: /Switch to (light|dark) theme/ }).click()
  verify(
    ((await page.locator("html").getAttribute("data-theme")) === "dark") !== wasDark,
    "The theme button changes the whole page",
  )
  await page.reload()
  verify(
    ((await page.locator("html").getAttribute("data-theme")) === "dark") !== wasDark,
    "Theme survives reload",
  )
  return checks
}
