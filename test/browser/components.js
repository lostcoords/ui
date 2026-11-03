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
    await page.waitForFunction(async () => {
      const { application } = await import("controllers/application")
      return [...document.querySelectorAll("[data-controller]")].every((element) =>
        element.dataset.controller
          .split(/\s+/)
          .filter(Boolean)
          .every((identifier) =>
            application.getControllerForElementAndIdentifier(element, identifier),
          ),
      )
    })
  }

  await visit("button")
  const contrast = await page.evaluate(() => {
    const root = document.documentElement
    const theme = root.getAttribute("data-theme")
    const palette = root.getAttribute("data-palette")
    const panel = document.querySelector('[data-controller="example"]')
    const canvas = document.createElement("canvas")
    canvas.width = canvas.height = 1
    const context = canvas.getContext("2d", { willReadFrequently: true })
    const luminance = (color) => {
      context.fillStyle = color
      context.fillRect(0, 0, 1, 1)
      return [...context.getImageData(0, 0, 1, 1).data]
        .slice(0, 3)
        .map((value) => {
          const channel = value / 255
          return channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4
        })
        .reduce((sum, value, index) => sum + value * [0.2126, 0.7152, 0.0722][index], 0)
    }
    const colors = [...getComputedStyle(root)].filter((name) => name.startsWith("--syntax-"))
    const palettes = [...document.querySelectorAll('input[name="palette"]')].map(
      (input) => input.value,
    )
    let minimum = Infinity
    for (const mode of ["light", "dark"]) {
      if (mode === "dark") root.dataset.theme = "dark"
      else delete root.dataset.theme
      for (const choice of palettes) {
        if (choice === "original") delete root.dataset.palette
        else root.dataset.palette = choice
        const background = luminance(getComputedStyle(panel).backgroundColor)
        for (const color of colors) {
          const foreground = luminance(getComputedStyle(root).getPropertyValue(color))
          minimum = Math.min(
            minimum,
            (Math.max(background, foreground) + 0.05) / (Math.min(background, foreground) + 0.05),
          )
        }
      }
    }
    if (theme) root.setAttribute("data-theme", theme)
    else root.removeAttribute("data-theme")
    if (palette) root.setAttribute("data-palette", palette)
    else root.removeAttribute("data-palette")
    return { minimum, colors: colors.length }
  })
  verify(
    contrast.colors > 0 && contrast.minimum >= 4.5,
    "Syntax colors meet AA contrast in every palette and theme",
  )

  const form = page.locator("[data-example-preview] form").first()
  await form.locator("button").click()
  verify(page.url().endsWith("button.html"), "Example forms stay on the docs page")
  verify(
    (await page.locator("pre").allTextContents()).some((source) => source.includes("ui_button_to")),
    "Copied examples use the render API",
  )

  const iconSpacing = await page
    .locator('[data-example-preview] button:has(>svg[data-icon="inline-start"])')
    .first()
    .evaluate((button) => {
      const svg = button.querySelector("svg").getBoundingClientRect()
      const rect = button.getBoundingClientRect()
      const style = getComputedStyle(button)
      const start = parseFloat(style.paddingInlineStart)
      const end = parseFloat(style.paddingInlineEnd)
      const centered = Math.abs(svg.y + svg.height / 2 - rect.y - rect.height / 2) < 1
      button.dir = "rtl"
      const rtl = parseFloat(getComputedStyle(button).paddingRight) === start
      button.removeAttribute("dir")
      return { optical: start < end, centered, rtl }
    })
  verify(iconSpacing.optical, "Leading icons reduce padding at the inline start")
  verify(iconSpacing.centered, "Button icons remain vertically centered")
  verify(iconSpacing.rtl, "Icon padding follows the writing direction")
  const endSpacing = await page
    .locator('[data-example-preview] button:has(>svg[data-icon="inline-end"])')
    .first()
    .evaluate((button) => {
      const style = getComputedStyle(button)
      return parseFloat(style.paddingInlineEnd) < parseFloat(style.paddingInlineStart)
    })
  verify(endSpacing, "Trailing icons reduce padding at the inline end")

  const shortCode = page.locator("#usage-code")
  verify(await shortCode.isVisible(), "Usage code is visible by default")
  verify((await shortCode.locator("[data-syntax]").count()) > 0, "ERB code is syntax highlighted")
  const fullCode = page.locator('[data-example-target="toggle"]').first()
  const longCode = page.locator(`#${await fullCode.getAttribute("aria-controls")}`)
  const collapsedHeight = await longCode.evaluate((node) => node.clientHeight)
  await fullCode.click()
  verify(
    (await fullCode.getAttribute("aria-expanded")) === "true",
    "Long examples expand without changing their source",
  )
  verify(
    (await longCode.evaluate((node) => node.clientHeight)) > collapsedHeight,
    "Expanded code reveals the clipped lines",
  )
  await fullCode.click()
  verify((await fullCode.getAttribute("aria-expanded")) === "false", "Long examples collapse again")

  await visit("segmented")
  const selected = page
    .locator('main section[id^="example-"]')
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
  await page.bringToFront()
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
