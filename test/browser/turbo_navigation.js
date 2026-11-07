async function _verifyTurboNavigation(page) {
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const sidebar = 'aside[aria-label="Documentation sidebar"]'
  const scrollTop = () => page.$eval(sidebar, (aside) => aside.scrollTop)

  await page.setViewportSize({ width: 1440, height: 700 })
  await page.goto(`${origin}/components/tooltip.html`)
  await page.waitForFunction(() =>
    window.Stimulus.controllers.some(({ identifier }) => identifier === "lc-scroll-keeper"),
  )
  const revealed = await page.$eval(sidebar, (aside) => {
    const frame = aside.getBoundingClientRect()
    const link = aside.querySelector('[aria-current="page"]').getBoundingClientRect()
    return {
      scrollTop: aside.scrollTop,
      inside: link.top >= frame.top && link.bottom <= frame.bottom,
    }
  })
  verify(
    revealed.scrollTop > 0 && revealed.inside,
    "A first visit scrolls the current link into view",
  )
  verify(
    (await page.evaluate(() => scrollY)) === 0,
    "Revealing the current link leaves the page at the top",
  )

  await page.$eval(sidebar, (aside) => {
    aside.scrollTop = 400
  })
  const before = await scrollTop()
  await page.evaluate(() => {
    window.turboVisitMarker = true
  })
  // A locator click would first scroll the link into view, so the link clicks itself.
  await page.$eval(`${sidebar} a[href="/components/button.html"]`, (link) => link.click())
  await page.waitForURL("**/components/button.html")
  await page.waitForFunction(() => document.title.startsWith("Button"))
  verify(
    await page.evaluate(() => window.turboVisitMarker === true),
    "Sidebar links visit through Turbo without a full page load",
  )
  verify(
    Math.abs((await scrollTop()) - before) <= 1,
    "The sidebar keeps its scroll position across a Turbo visit",
  )
  verify(
    (await page.$eval(`${sidebar} [aria-current="page"]`, (a) => a.getAttribute("href"))) ===
      "/components/button.html",
    "The new page marks its own link as current",
  )

  await page.reload()
  verify(
    Math.abs((await scrollTop()) - before) <= 1,
    "The sidebar keeps its scroll position across a reload",
  )

  await page.goBack()
  // Turbo updates the URL before it renders the restored page.
  await page.waitForFunction(() => document.title.startsWith("Tooltip"))
  verify(
    Math.abs((await scrollTop()) - before) <= 1,
    "The sidebar keeps its scroll position when going back",
  )
  verify(
    (await page.$eval(`${sidebar} [aria-current="page"]`, (a) => a.getAttribute("href"))) ===
      "/components/tooltip.html",
    "Going back marks the earlier page's link as current",
  )

  await page.evaluate(() => {
    window.turboVisitMarker = true
  })
  await page.click('header a[href="/installation.html"]')
  await page.waitForURL("**/installation.html")
  const assets = await page.evaluate(() =>
    [...document.head.querySelectorAll('link[rel="stylesheet"]')].map((node) =>
      node.getAttribute("href"),
    ),
  )
  verify(
    assets.every((href) => href.startsWith("/assets/") || href.startsWith("http")) &&
      !assets.some((href) => href.includes("components")),
    "A visit drops the components page stylesheet and keeps root-absolute assets",
  )
  verify(
    await page.evaluate(() => window.turboVisitMarker === true),
    "Header links also visit through Turbo",
  )
  verify(
    (await page.getAttribute('meta[name="turbo-refresh-method"]', "content")) === "morph",
    "Same-page refreshes morph",
  )
  return checks
}
