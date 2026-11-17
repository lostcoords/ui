// Movement the library draws itself stops under prefers-reduced-motion, with or without the
// document reset in base.css: panels and dialogs fade in place and cards stay put on hover.
async function _verifyReducedMotion(page) {
  page.setDefaultTimeout(10000)
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  // A closed panel has no box, and without one its transform reads "none"; give it one to read its
  // pose, with no transition from the pose it was last read in.
  const pose = (selector, property = "transform") =>
    page.$eval(
      selector,
      (node, name) => {
        const { display, transition } = node.style
        node.style.transition = "none"
        if (getComputedStyle(node).display === "none") node.style.display = "block"
        const value = getComputedStyle(node)[name]
        Object.assign(node.style, { display, transition })
        return value
      },
      property,
    )

  await page.goto(`${origin}/components/menu.html`)
  verify(
    (await pose("main [data-slot=menu]:not([data-open])")) !== "none",
    "A closed menu waits in its exit pose",
  )
  await page.emulateMedia({ reducedMotion: "reduce" })
  verify(
    (await pose("main [data-slot=menu]:not([data-open])")) === "none",
    "Reduced motion leaves a closed menu in place",
  )
  await page.waitForFunction(() =>
    [...document.querySelectorAll('[data-controller~="lc-menu"]')].every((element) =>
      window.Stimulus?.getControllerForElementAndIdentifier(element, "lc-menu"),
    ),
  )
  await page.locator('main [data-lc-menu-target~="trigger"]').first().click()
  await page.waitForSelector("main [data-slot=menu][data-open]")
  verify(
    (await pose("main [data-slot=menu][data-open]", "opacity")) === "1",
    "The menu still opens",
  )
  await page.keyboard.press("Escape")

  await page.goto(`${origin}/components/dialog.html`)
  verify(
    (await pose("main dialog.lc-dialog:not([open])")) === "none",
    "Reduced motion leaves a closed dialog in place",
  )
  await page.emulateMedia({ reducedMotion: "no-preference" })
  verify(
    (await pose("main dialog.lc-dialog:not([open])")) !== "none",
    "A closed dialog waits in its exit pose otherwise",
  )

  await page.goto(`${origin}/components/card.html`)
  const card = page.locator("main a[data-slot=card]").first()
  await card.hover()
  verify(
    (await card.evaluate((node) => getComputedStyle(node).translate)) !== "none",
    "A linked card lifts on hover",
  )
  await page.mouse.move(0, 0)
  await page.emulateMedia({ reducedMotion: "reduce" })
  await card.hover()
  verify(
    (await card.evaluate((node) => getComputedStyle(node).translate)) === "none",
    "Reduced motion keeps a hovered card where it is",
  )
  return checks
}
