async function _verifySheets(page) {
  await page.bringToFront()
  page.setDefaultTimeout(10000)
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const pause = (ms) => page.evaluate((ms) => new Promise((resolve) => setTimeout(resolve, ms)), ms)

  await page.setViewportSize({ width: 390, height: 844 })
  try {
    // A phone sheet dragged to its large detent pushes the page back, as UIKit's page sheet does.
    await page.goto(`${origin}/components/dialog.html`)
    await page.waitForFunction(
      () => document.querySelector('dialog[data-lc-sheet-detents-value="medium large"]'),
      null,
      { polling: 100 },
    )
    const dialogId = await page.evaluate(
      () => document.querySelector('dialog[data-lc-sheet-detents-value="medium large"]').id,
    )
    await page.evaluate((id) => {
      document.getElementById(id).closest("[data-controller~='lc-dialog']").scrollIntoView()
    }, dialogId)
    await page.locator(`[data-controller~="lc-dialog"]:has(#${dialogId}) > button`).first().click()
    const dialog = page.locator(`#${dialogId}`)
    await page.waitForFunction((id) => document.getElementById(id)?.open, dialogId, {
      polling: 100,
    })
    await pause(700)
    const medium = await page.evaluate(() => ({
      glass: getComputedStyle(document.querySelector("body > header .lc-app-header__glass"))
        .opacity,
      page: document.documentElement.hasAttribute("data-lc-sheet-page"),
      transform: getComputedStyle(document.body).transform,
    }))
    verify(!medium.page && medium.transform === "none", "a medium sheet leaves the page in place")
    verify(
      medium.glass === "1",
      "the scrolled header keeps its glass while the scroll lock pins the page",
    )

    const box = await dialog.boundingBox()
    const x = box.x + box.width / 2
    await page.mouse.move(x, box.y + 12)
    await page.mouse.down()
    for (let y = box.y + 12; y > 30; y -= 40) await page.mouse.move(x, y)
    await page.mouse.move(x, 20)
    await page.mouse.up()
    await pause(900)
    verify(
      await page.evaluate((id) => document.getElementById(id).open, dialogId),
      "a mouse drag that ends above the sheet keeps it open",
    )
    const large = await page.evaluate(() => {
      const root = document.documentElement
      const body = getComputedStyle(document.body)
      const matrix = new DOMMatrixReadOnly(body.transform)
      return {
        page: root.hasAttribute("data-lc-sheet-page"),
        scale: matrix.a,
        backdrop: getComputedStyle(root).backgroundColor,
        clipped: body.clipPath !== "none",
        sheetTop: document.querySelector("dialog[open]").getBoundingClientRect().top,
      }
    })
    verify(large.page, "a sheet at its large detent marks the page behind it")
    verify(large.scale < 1 && large.scale > 0.85, "the page behind a large sheet shrinks back")
    verify(large.backdrop === "rgb(0, 0, 0)", "the page shrinks over black")
    verify(large.clipped, "the page behind a large sheet rounds its corners")
    verify(large.sheetTop < box.y, "dragging the sheet up reaches the large detent")

    await page.keyboard.press("Escape")
    await page.waitForFunction((id) => !document.getElementById(id).open, dialogId, {
      polling: 100,
    })
    await pause(900)
    const after = await page.evaluate(() => ({
      page: document.documentElement.hasAttribute("data-lc-sheet-page"),
      transform: getComputedStyle(document.body).transform,
      variables: [...document.documentElement.style].filter((name) =>
        name.startsWith("--lc-sheet-page"),
      ),
      locked: document.body.dataset.modalScrollLock === "true",
    }))
    verify(!after.page && after.transform === "none", "closing the sheet restores the page")
    verify(after.variables.length === 0, "closing the sheet clears its page variables")
    verify(!after.locked, "closing the sheet releases the scroll lock")

    // A native [popover] with lc_sheet_class is the same phone sheet, and a swipe down hides it.
    const popover = page.locator('[popover].lc-sheet[id$="-filters"]').first()
    const popoverId = await popover.getAttribute("id")
    await page.evaluate((id) => document.getElementById(id).scrollIntoView(), popoverId)
    await page.locator(`button[popovertarget="${popoverId}"]:not([popovertargetaction])`).click()
    await pause(700)
    const opened = await page.evaluate((id) => {
      const sheet = document.getElementById(id)
      const style = getComputedStyle(sheet)
      const rect = sheet.getBoundingClientRect()
      return {
        open: sheet.matches(":popover-open"),
        position: style.position,
        transform: style.transform,
        display: style.display,
        bottomGap: innerHeight - rect.bottom,
        width: rect.width,
        backdrop: getComputedStyle(sheet, "::backdrop").opacity,
        grabber: getComputedStyle(sheet, "::before").content,
        floor: sheet.style.getPropertyValue("--lc-sheet-floor"),
      }
    }, popoverId)
    verify(opened.open && opened.display === "flex", "a popover sheet opens as a flex column")
    verify(
      opened.position === "fixed" && opened.transform === "none",
      "a popover sheet rests in place",
    )
    verify(
      opened.bottomGap >= 0 && opened.bottomGap < 24,
      "a popover sheet sits on the bottom edge",
    )
    verify(opened.width > 390 - 24, "a popover sheet spans the phone's width")
    verify(opened.backdrop === "1", "a popover sheet dims the page behind it")
    verify(opened.grabber === '""', "a popover sheet without a handle draws the grabber")
    verify(opened.floor.endsWith("px"), "lc-sheet pins a popover sheet's floor as it opens")

    const sheetBox = await popover.boundingBox()
    const sx = sheetBox.x + sheetBox.width / 2
    await page.mouse.move(sx, sheetBox.y + 10)
    await page.mouse.down()
    for (let y = sheetBox.y + 10; y < 830; y += 40) await page.mouse.move(sx, y)
    await page.mouse.up()
    await pause(900)
    verify(
      !(await page.evaluate(
        (id) => document.getElementById(id).matches(":popover-open"),
        popoverId,
      )),
      "swiping a popover sheet down hides it",
    )

    // A div the caller shows with [data-open] is a sheet too, and the caller owns its dismissal.
    const panel = await page.evaluate(async () => {
      const sheet = document.createElement("div")
      sheet.className = "lc-sheet"
      sheet.dataset.controller = "lc-sheet"
      sheet.innerHTML =
        '<span data-lc-sheet-target="handle"></span><p style="block-size: 12rem">Panel</p>'
      document.body.append(sheet)
      await new Promise((resolve) => requestAnimationFrame(resolve))
      const closed = getComputedStyle(sheet).display
      sheet.dataset.open = ""
      await new Promise((resolve) => setTimeout(resolve, 700))
      const rect = sheet.getBoundingClientRect()
      return {
        closed,
        display: getComputedStyle(sheet).display,
        transform: getComputedStyle(sheet).transform,
        bottomGap: innerHeight - rect.bottom,
        top: rect.top,
        floor: sheet.style.getPropertyValue("--lc-sheet-floor"),
        grabber: getComputedStyle(sheet, "::before").content,
      }
    })
    verify(panel.closed === "none", "a panel sheet stays out of the layout until [data-open]")
    verify(
      panel.display === "flex" && panel.transform === "none",
      "a panel sheet slides in on [data-open]",
    )
    verify(panel.bottomGap >= 0 && panel.bottomGap < 24, "a panel sheet sits on the bottom edge")
    verify(panel.floor.endsWith("px"), "lc-sheet pins a panel sheet's floor as it opens")
    verify(panel.grabber === "none", "a panel sheet with a handle leaves the grabber to it")

    await page.evaluate(() => {
      const sheet = document.querySelector("body > .lc-sheet")
      sheet.addEventListener("lc-sheet:dismiss", () => (window.panelDismissed = true))
    })
    await page.mouse.move(195, panel.top + 10)
    await page.mouse.down()
    for (let y = panel.top + 10; y < 830; y += 40) await page.mouse.move(195, y)
    await page.mouse.up()
    await pause(900)
    verify(
      await page.evaluate(() => window.panelDismissed),
      "swiping a panel sheet down asks its owner to dismiss it",
    )
    const closing = await page.evaluate(async () => {
      const sheet = document.querySelector("body > .lc-sheet")
      delete sheet.dataset.open
      await new Promise((resolve) => setTimeout(resolve, 700))
      const display = getComputedStyle(sheet).display
      sheet.remove()
      return display
    })
    verify(closing === "none", "a panel sheet leaves the layout once [data-open] goes")
  } finally {
    await page.setViewportSize({ width: 1440, height: 900 })
  }

  // From sm up an anchored sheet is a popover under its trigger; a native popover menu gets the
  // popover shell's enter pose from :popover-open.
  const desktop = await page.evaluate(async () => {
    const frame = () => new Promise((resolve) => requestAnimationFrame(resolve))
    const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms))
    const host = document.createElement("div")
    host.style.cssText = "position: relative; inline-size: 30rem; margin: 2rem"
    host.innerHTML =
      '<button type="button">Currency</button><div class="lc-sheet lc-sheet-anchored" data-controller="lc-sheet"><p>Options</p></div>' +
      '<div popover class="lc-popover-shell" style="--lc-popover-from: scale(0.5)">Menu</div>'
    document.body.prepend(host)
    const [trigger, sheet, menu] = host.children
    await frame()
    const closed = getComputedStyle(sheet).display
    sheet.dataset.open = ""
    await wait(400)
    const style = getComputedStyle(sheet)
    const placed = {
      closed,
      display: style.display,
      position: style.position,
      opacity: style.opacity,
      below: sheet.getBoundingClientRect().top >= trigger.getBoundingClientRect().bottom,
      endAligned:
        Math.abs(sheet.getBoundingClientRect().right - host.getBoundingClientRect().right) < 1,
    }

    menu.showPopover()
    const entering = new DOMMatrixReadOnly(getComputedStyle(menu).transform).a
    await wait(400)
    const settled = getComputedStyle(menu)
    placed.menu = { entering, opacity: settled.opacity, transform: settled.transform }
    menu.hidePopover()
    host.remove()
    return placed
  })
  verify(desktop.closed === "none", "an anchored sheet stays hidden on desktop until [data-open]")
  verify(
    desktop.display === "flex" && desktop.position === "absolute" && desktop.opacity === "1",
    "an anchored sheet opens as a popover on desktop",
  )
  verify(
    desktop.below && desktop.endAligned,
    "an anchored sheet hangs under its trigger, end-aligned",
  )
  verify(desktop.menu.entering < 0.99, "a native popover menu enters from --lc-popover-from")
  verify(
    desktop.menu.opacity === "1" && desktop.menu.transform.startsWith("matrix(1, 0, 0, 1"),
    "a native popover menu settles open on :popover-open",
  )
  return checks
}
