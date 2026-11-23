async function _verifyFocus(page) {
  await page.bringToFront()
  await page.setViewportSize({ width: 1440, height: 900 })
  page.setDefaultTimeout(10000)
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const visit = async (path) => {
    await page.goto(`${origin}${path}`)
    await page.waitForFunction(() => {
      const application = window.Stimulus
      if (!application) return false
      return [...document.querySelectorAll("[data-controller]")].every((element) =>
        element.dataset.controller
          .split(/\s+/)
          .every((name) => application.getControllerForElementAndIdentifier(element, name)),
      )
    })
  }
  // Where focus is, and whether the ring is drawn there.
  const focus = (locator) =>
    locator.evaluate((element) => ({
      here: document.activeElement === element,
      ring: getComputedStyle(element).outlineStyle !== "none",
    }))
  const closed = (selector) =>
    page.waitForFunction((selector) => !document.querySelector(selector).open, selector)

  await visit("/components/dialog.html")
  const members = "dialog[id$='-members']"
  const opener = page.locator(`[data-controller~='lc-dialog']:has(${members}) > button`).first()

  await opener.click()
  await page.waitForFunction((selector) => document.querySelector(selector).open, members)
  await page.keyboard.press("Escape")
  await closed(members)
  let state = await focus(opener)
  verify(state.here, "Escape returns focus to the button that opened the dialog")
  verify(!state.ring, "a dialog opened with the mouse and closed with Escape leaves no ring")

  await page.keyboard.press("Tab")
  await page.keyboard.press("Shift+Tab")
  state = await focus(opener)
  verify(state.here && state.ring, "tabbing back to the button shows the ring again")

  await page.keyboard.press("Enter")
  await page.waitForFunction((selector) => document.querySelector(selector).open, members)
  await page.keyboard.press("Escape")
  await closed(members)
  state = await focus(opener)
  verify(
    state.here && state.ring,
    "a dialog opened and closed by keyboard returns focus with its ring",
  )

  await visit("/components/menu.html")
  const trigger = page.getByRole("button", { name: "Project actions", exact: true }).first()
  const triggerId = await trigger.getAttribute("id")
  const expanded = (value) =>
    page.waitForFunction(
      ([id, value]) => document.getElementById(id)?.getAttribute("aria-expanded") === value,
      [triggerId, value],
    )

  await trigger.click()
  await expanded("true")
  await page.keyboard.press("Escape")
  await expanded("false")
  state = await focus(trigger)
  verify(
    state.here && !state.ring,
    "a menu opened with the mouse and closed with Escape leaves no ring",
  )

  await trigger.click()
  await expanded("true")
  await page.getByRole("menuitem").first().click()
  await expanded("false")
  state = await focus(trigger)
  verify(state.here, "choosing a menu item returns focus to the menu's button")
  verify(!state.ring, "choosing a menu item with the mouse leaves no ring on the button")

  await page.keyboard.press("Tab")
  await page.keyboard.press("Shift+Tab")
  await page.keyboard.press("ArrowDown")
  await expanded("true")
  await page.keyboard.press("Escape")
  await expanded("false")
  state = await focus(trigger)
  verify(
    state.here && state.ring,
    "a menu opened and closed by keyboard returns focus with its ring",
  )

  await visit("/components/emoji.html")
  const picker = page.getByRole("button", { name: "Choose an emoji", exact: true }).first()
  await picker.click()
  const emoji = page.locator(".lc-emoji-picker__body button[data-emoji]").first()
  await emoji.waitFor()
  await emoji.click()
  await page.waitForFunction(
    (button) => button.getAttribute("aria-expanded") === "false",
    await picker.elementHandle(),
  )
  state = await focus(picker)
  verify(state.here && !state.ring, "choosing an emoji with the mouse returns focus without a ring")

  return checks
}
