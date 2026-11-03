async function _verifyComponentSimplification(page) {
  await page.bringToFront()
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const response = await page.request.get(`${origin}/api.json`, { ignoreHTTPSErrors: true })
  const reference = await response.json()
  const retired = [
    "lc_status_pill",
    "lc_medallion",
    "lc_eyebrow",
    "lc_form_card",
    "lc_card_surface",
    "lc_sheet",
    "lc_form_actions",
    "lc_pill_row",
    "lc_pill",
    "lc_segmented",
    "lc_segmented_tab",
    "lc_form_alert",
    "lc_disclosure",
  ]
  verify(
    reference.components.every((component) => !retired.includes(component.name)),
    "The public API contains the consolidated helpers and no retired wrappers",
  )
  await page.setViewportSize({ width: 1440, height: 900 })
  await page.goto(`${origin}/components/card.html`)
  verify(
    (await page
      .locator('aside nav[aria-label="Documentation"] a[href^="/components/"]')
      .count()) === 36,
    "The sidebar groups the catalog into 36 component and foundation pages",
  )
  await page.emulateMedia({ reducedMotion: "reduce" })
  try {
    for (const theme of ["light", "dark"]) {
      const card = await page.evaluate((theme) => {
        document.documentElement.dataset.theme = theme
        const formCard = document.querySelector("#example-4 .lc-card")
        const invalidCard = document.querySelector("#example-5 .lc-card")
        const input = formCard.querySelector("input")
        const probe = document.createElement("span")
        probe.style.backgroundColor = "var(--background)"
        formCard.append(probe)
        for (const animation of document.getAnimations()) animation.finish()
        const root = getComputedStyle(formCard)
        const result = {
          fill: root.backgroundColor,
          input: getComputedStyle(input).backgroundColor,
          page: getComputedStyle(probe).backgroundColor,
          invalidBorder: getComputedStyle(invalidCard).borderColor,
          defaultBorder: root.borderColor,
        }
        formCard.style.setProperty("--lc-card-bg", "#123456")
        for (const animation of formCard.getAnimations()) animation.finish()
        result.custom = getComputedStyle(formCard).backgroundColor
        result.cutout = getComputedStyle(formCard).getPropertyValue("--lc-avatar-cutout").trim()
        formCard.style.removeProperty("--lc-card-bg")
        probe.remove()
        return result
      }, theme)
      verify(
        card.input !== card.page && card.input !== card.fill,
        `${theme}: inputs keep a fill distinct from the card and the page`,
      )
      verify(
        card.invalidBorder !== card.defaultBorder && card.invalidBorder !== "rgba(0, 0, 0, 0)",
        `${theme}: validation feedback marks the containing card`,
      )
      verify(
        card.custom === "rgb(18, 52, 86)" && card.cutout === "#123456",
        `${theme}: card color overrides also update avatar cutouts`,
      )
    }
    await page.goto(`${origin}/components/avatar.html`)
    const avatarSizes = await page
      .locator("#example-0 .lc-avatar")
      .evaluateAll((avatars) =>
        avatars.slice(0, 2).map((avatar) => avatar.getBoundingClientRect().width),
      )
    verify(avatarSizes[1] > avatarSizes[0], "Large avatars render larger than the default size")
    await page.goto(`${origin}/components/icon_badge.html`)
    verify(
      await page
        .locator("#example-1 .lc-icon-badge")
        .first()
        .evaluate(
          (icon) =>
            getComputedStyle(icon).borderRadius === "3.40282e+38px" ||
            parseFloat(getComputedStyle(icon).borderRadius) >= icon.offsetWidth / 2,
        ),
      "Icon badge includes the round presentation formerly called Medallion",
    )
    await page.setViewportSize({ width: 390, height: 900 })
    await page.goto(`${origin}/components/dialog.html`)
    const stage = page.locator("#example-2 [data-example-preview]")
    const trigger = stage.locator('button[data-action="lc-dialog#open"]')
    const dialog = stage.locator("dialog")
    await page.waitForFunction(async () => {
      const { application } = await import("controllers/application")
      const dialog = document.querySelector("#example-2 dialog")
      return dialog && application.getControllerForElementAndIdentifier(dialog, "lc-sheet")
    })
    await trigger.evaluate((button) => button.click())
    await dialog.waitFor({ state: "visible" })
    verify(
      (await dialog.getAttribute("data-lc-sheet-detents-value")) === "medium large",
      "Dialog owns the mobile height options",
    )
    verify(
      await dialog.evaluate((dialog) => dialog.matches(":modal")),
      "Mobile dialogs retain native modal semantics",
    )
    await page.bringToFront()
    const rect = await dialog.boundingBox()
    await page.mouse.move(rect.x + rect.width / 2, rect.y + 8)
    await page.mouse.down()
    await page.mouse.move(rect.x + rect.width / 2, Math.min(880, rect.y + 358), { steps: 8 })
    await page.mouse.up()
    await dialog.waitFor({ state: "hidden" })
    verify(
      !(await dialog.evaluate((dialog) => dialog.open)),
      "Dragging a mobile dialog down dismisses it",
    )
  } finally {
    await page.emulateMedia({ reducedMotion: "no-preference" })
    await page.setViewportSize({ width: 1440, height: 900 })
  }
  await page.goto(`${origin}/`)
  verify(
    await page.evaluate(() => {
      const card = document.querySelector("[aria-labelledby=bento-code-title]")
      const details = card.querySelector("details")
      const summary = details.querySelector("summary")
      return (
        summary.scrollWidth <= summary.clientWidth &&
        details.getBoundingClientRect().right <= card.getBoundingClientRect().right
      )
    }),
    "The homepage collapsible fits its card without spilling into adjacent content",
  )
  return checks
}
