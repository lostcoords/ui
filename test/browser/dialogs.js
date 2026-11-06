async function _verifyDialogs(page) {
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
  const isOpen = (selector) =>
    page.evaluate((selector) => document.querySelector(selector).open, selector)

  await visit("/components/dialog.html")

  const members = "dialog[id$='-members']"
  await page.locator(`[data-controller~='lc-dialog']:has(${members}) > button`).first().click()
  await page.waitForFunction((selector) => document.querySelector(selector).open, members)
  const layout = await page.evaluate((selector) => {
    const dialog = document.querySelector(selector)
    const body = dialog.querySelector("[data-slot=dialog-body]")
    const actions = dialog.querySelector("[data-slot=dialog-actions]")
    return {
      width: dialog.offsetWidth,
      action: actions.firstElementChild.textContent.trim(),
      bodyScrolls: getComputedStyle(body).overflowY === "auto",
    }
  }, members)
  verify(Math.round(layout.width) === 640, "size: :lg opens a 40rem dialog on desktop")
  verify(layout.action === "Invite", "header actions sit before the close button")
  verify(layout.bodyScrolls, "the dialog body scrolls under a fixed header on desktop")
  await page.locator(`${members} [data-slot=dialog-dismiss]`).click()
  await page.waitForFunction((selector) => !document.querySelector(selector).open, members)
  verify(true, "a dialog without a built-in trigger closes through the caller's controller")

  const invite = "dialog[id$='-invite']"
  await page.getByRole("button", { name: "Invite with your own trigger" }).click()
  await page.waitForFunction((selector) => document.querySelector(selector).open, invite)
  const inviteWidth = await page.evaluate(
    (selector) => document.querySelector(selector).offsetWidth,
    invite,
  )
  verify(
    inviteWidth === 512,
    "a custom trigger opens the dialog, and data-dialog-size content widens it to 32rem",
  )
  await page.locator(`${invite} [data-slot=dialog-dismiss]`).click()
  await page.waitForFunction((selector) => !document.querySelector(selector).open, invite)

  const sheet = "#lc-confirm-sheet"
  const deleteButton = page.getByRole("button", { name: "Delete project", exact: true })
  await deleteButton.scrollIntoViewIfNeeded()
  await deleteButton.click()
  await page.waitForFunction((selector) => document.querySelector(selector).open, sheet)
  const destructive = await page.evaluate((selector) => {
    const dialog = document.querySelector(selector)
    const shown = [...dialog.querySelectorAll("[data-slot=confirm-sheet-accept]")].filter(
      (button) => !button.hidden,
    )
    return {
      message: dialog.querySelector("[data-slot=confirm-sheet-message]").textContent,
      variants: shown.map((button) => button.dataset.variant),
      label: shown[0]?.textContent.trim(),
      focused: document.activeElement === dialog,
    }
  }, sheet)
  const description = await page.evaluate((selector) => {
    const node = document.querySelector(`${selector} [data-slot=confirm-sheet-description]`)
    return node.hidden ? null : node.textContent
  }, sheet)
  verify(
    destructive.message === "Delete this project?",
    "the sheet shows the Turbo confirm message",
  )
  verify(
    description === "Its pages and files are deleted for everyone.",
    "data-turbo-confirm-description adds a line under the message",
  )
  verify(
    destructive.variants.join() === "destructive",
    "a destructive submitter gets the destructive accept button",
  )
  verify(
    destructive.label === "Delete project",
    "a short submitter label relabels the accept button",
  )
  verify(destructive.focused, "the sheet takes focus rather than its Cancel button")
  await page.keyboard.press("Escape")
  await page.waitForFunction((selector) => !document.querySelector(selector).open, sheet)
  verify(
    await page
      .waitForFunction(
        () =>
          document.querySelector("form:has(button[data-variant=destructive])[data-turbo-confirm]")
            .dataset.confirmed === "false",
      )
      .then(
        () => true,
        () => false,
      ),
    "Escape declines the confirmation",
  )

  const archive = page.getByRole("button", { name: "Archive", exact: true })
  await archive.click()
  await page.waitForFunction((selector) => document.querySelector(selector).open, sheet)
  const plain = await page.evaluate((selector) => {
    const shown = [
      ...document.querySelectorAll(`${selector} [data-slot=confirm-sheet-accept]`),
    ].filter((button) => !button.hidden)
    return {
      accepts: shown.map((button) => `${button.dataset.variant}:${button.textContent.trim()}`),
      description: document.querySelector(`${selector} [data-slot=confirm-sheet-description]`)
        .hidden,
    }
  }, sheet)
  verify(
    plain.accepts.join() === "primary:Archive project",
    "data-turbo-confirm-accept labels the primary accept button",
  )
  verify(plain.description, "a confirm without a description hides the line")
  await page.locator(`${sheet} button[data-variant=primary]`).click()
  await page.waitForFunction((selector) => !document.querySelector(selector).open, sheet)
  verify(
    await page
      .waitForFunction(
        () =>
          document.querySelector("form[data-turbo-confirm='Archive this project?']").dataset
            .confirmed === "true",
      )
      .then(
        () => true,
        () => false,
      ),
    "the accept button confirms",
  )
  verify(!(await isOpen(sheet)), "the sheet closes after answering")

  const membership = page.getByRole("button", { name: "Membership", exact: true })
  await membership.scrollIntoViewIfNeeded()
  await membership.click()
  await page.getByRole("menuitem", { name: "Leave project" }).click()
  await page.waitForFunction((selector) => document.querySelector(selector).open, sheet)
  const fromMenu = await page.evaluate((selector) => {
    const dialog = document.querySelector(selector)
    const shown = [...dialog.querySelectorAll("[data-slot=confirm-sheet-accept]")].filter(
      (button) => !button.hidden,
    )
    return {
      anchored: dialog.hasAttribute("data-anchored"),
      accept: shown
        .map((button) => `${button.dataset.variant}:${button.textContent.trim()}`)
        .join(),
    }
  }, sheet)
  verify(fromMenu.anchored, "a confirm raised from a menu opens beside the menu on desktop")
  verify(
    fromMenu.accept === "destructive:Leave",
    "a destructive menu option gets the destructive accept button",
  )
  await page.keyboard.press("Escape")
  await page.waitForFunction((selector) => !document.querySelector(selector).open, sheet)
  verify(true, "the anchored sheet closes on Escape")

  return checks
}
