async function _verifyMenus(page) {
  await page.bringToFront()
  await page.setViewportSize({ width: 1440, height: 900 })
  page.setDefaultTimeout(10000)
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }

  // On a cold docs server the first visit's menus miss their first key press, as the keyboard suite's menus do.
  await page.goto(`${origin}/components/button.html`)
  await page.goto(`${origin}/components/menu.html`)
  await page.waitForFunction(() => {
    const application = window.Stimulus
    if (!application) return false
    return [...document.querySelectorAll("[data-controller]")].every((element) =>
      element.dataset.controller
        .split(/\s+/)
        .every((name) => application.getControllerForElementAndIdentifier(element, name)),
    )
  })

  const trigger = page.getByRole("button", { name: "Actions for Alex", exact: true }).first()
  const box = await trigger.boundingBox()
  const control = await trigger.evaluate((button) => {
    const probe = document.createElement("div")
    probe.style.height = "var(--lc-control-md)"
    button.parentElement.append(probe)
    const height = probe.getBoundingClientRect().height
    probe.remove()
    return height
  })
  verify(
    box.width === control && box.height === control,
    "The icon trigger is a square at the shared control height",
  )
  const scale = async () =>
    trigger.evaluate((button) => {
      const value = getComputedStyle(button.querySelector("svg")).scale
      return value === "none" ? 1 : Number.parseFloat(value)
    })
  verify((await scale()) === 1, "The icon trigger's icon rests at full size")

  await trigger.focus()
  await page.keyboard.press("ArrowDown")
  verify(
    await page
      .waitForFunction(
        (id) => document.getElementById(id)?.getAttribute("aria-expanded") === "true",
        await trigger.getAttribute("id"),
        { timeout: 2000 },
      )
      .then(
        () => true,
        () => false,
      ),
    "Arrow Down opens the icon-triggered menu",
  )
  await page.waitForTimeout(400)
  verify((await scale()) > 1, "The open trigger's icon grows")
  const labels = await page.evaluate(
    (id) => {
      const menu = document.getElementById(id)
      return [...menu.querySelectorAll("[role=menuitem]")].map((item) => ({
        text: item.textContent.trim(),
        start: Math.round(
          item.querySelector(":scope > span:not([data-slot])").getBoundingClientRect().left,
        ),
        itemStart: Math.round(item.getBoundingClientRect().left),
        width: Math.round(item.getBoundingClientRect().width),
      }))
    },
    await trigger.getAttribute("aria-controls"),
  )
  verify(labels.length === 4, "The row menu renders four options, including the form-backed one")
  verify(
    new Set(labels.map((label) => label.start)).size === 1,
    `Labels align with and without icons: ${JSON.stringify(labels)}`,
  )
  verify(
    new Set(labels.map((label) => label.width)).size === 1,
    "Options, including the one inside a form, share one width",
  )
  verify(labels[0].start - labels[0].itemStart > 20, "The label sits after the leading icon column")
  await page.keyboard.press("Escape")

  const currency = page.getByRole("button", { name: "Euro", exact: true }).first()
  await currency.focus()
  await page.keyboard.press("ArrowDown")
  const radios = page.locator(
    `#${await currency.getAttribute("aria-controls")} [role=menuitemradio]`,
  )
  verify((await radios.count()) === 3, "Checked options are menu radio items")
  verify(
    await page.evaluate(() => document.activeElement?.getAttribute("role") === "menuitemradio"),
    "Arrow keys reach menu radio items",
  )
  const marks = await radios.evaluateAll((items) =>
    items.map((item) => getComputedStyle(item.querySelector("svg:last-child")).visibility),
  )
  verify(marks.join() === "visible,hidden,hidden", "Only the checked option shows its check mark")

  await page.keyboard.press("Escape")
  await page.getByRole("button", { name: "Project actions", exact: true }).first().click()
  const plain = await page.evaluate(() => {
    const menu = document.querySelector("[data-slot=menu][data-open]")
    const item = menu.querySelector("[role=menuitem]")
    const label = item.querySelector(":scope > span")
    return Math.round(label.getBoundingClientRect().left - item.getBoundingClientRect().left)
  })
  verify(
    plain === 12,
    `A menu without leading visuals keeps the label at the item padding (${plain}px)`,
  )
  await page.keyboard.press("Escape")

  await trigger.click()
  const pinned = page.getByRole("menuitemcheckbox", { name: "Pinned" }).first()
  await pinned.click()
  verify(
    (await pinned.getAttribute("aria-checked")) === "true",
    "A checkbox option checks on click",
  )
  verify(await pinned.isVisible(), "A checkbox option leaves its menu open")
  await pinned.click()
  verify((await pinned.getAttribute("aria-checked")) === "false", "A second click unchecks it")
  await page.keyboard.press("Escape")

  await page.goto(`${origin}/components/popover.html`)
  const row = page.getByText("Tap anywhere on the row").first()
  await row.click()
  const pay = page.locator('[data-slot=popover][aria-label="How to pay Alex"]').first()
  await pay.waitFor()
  verify(await pay.isVisible(), "A panel-only popover opens from its host row")
  await row.click({ force: true })
  await page.waitForTimeout(300)
  verify(
    !(await pay.evaluate((panel) => panel.hasAttribute("data-open"))),
    "A second row click closes it",
  )

  return checks
}
