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
      glass: getComputedStyle(document.querySelector("body > header .header-example__glass"))
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
  } finally {
    await page.setViewportSize({ width: 1440, height: 900 })
  }
  return checks
}
