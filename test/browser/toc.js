async function _verifyToc(page) {
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const toc = "[data-slot=docs-shell-contents] [data-slot=toc]"
  const current = () =>
    page.$$eval(`${toc} [aria-current=location]`, (links) => links.map((link) => link.hash))
  const settle = () => page.waitForTimeout(250)

  await page.setViewportSize({ width: 1440, height: 900 })
  await page.goto(`${origin}/components/avatar.html`)
  await page.waitForFunction(() =>
    window.Stimulus.controllers.some(({ identifier }) => identifier === "lc-toc"),
  )
  verify((await current()).length === 0, "At the top of the page no section is current")

  await page.goto(`${origin}/components/avatar.html#example-1`)
  await settle()
  verify((await current()).join() === "#example-1", "Opening a link to a section marks it current")

  const landed = await page.$eval("#example-1", (section) => {
    const header = document.querySelector("[data-slot=app-header]").getBoundingClientRect()
    return section.getBoundingClientRect().top >= header.bottom - 16
  })
  verify(landed, "An anchored section lands below the sticky header")

  await page.click(`${toc} a[href="#usage"]`)
  await settle()
  verify((await current()).join() === "#usage", "Clicking a contents link marks it current")

  await page.$eval("#examples", (section) => section.scrollIntoView())
  await page.mouse.wheel(0, 20)
  await settle()
  verify((await current()).join() === "#examples", "Scrolling past a section marks it current")

  const indicator = await page.$eval(toc, (nav) => {
    const bar = nav.querySelector("[data-slot=toc-indicator]").getBoundingClientRect()
    const link = nav.querySelector("[aria-current=location]").getBoundingClientRect()
    return Math.abs(bar.top - link.top) < 1 && Math.abs(bar.height - link.height) < 1
  })
  verify(indicator, "The indicator covers the current link")

  await page.click(`${toc} a[href="#api"]`)
  await settle()
  verify((await current()).join() === "#api", "A section near the end stays current once clicked")

  await page.evaluate(() => scrollTo(0, document.documentElement.scrollHeight))
  await settle()
  verify((await current()).length === 1, "At the end of the page one section is current")

  for (const id of ["usage", "examples", "example-2", "api"]) {
    const href = await page.$eval(`#${id}`, (target) =>
      (target.matches("h1, h2, h3, h4") ? target : target.querySelector("h2, h3"))
        .querySelector("a[data-slot=heading-anchor]")
        ?.getAttribute("href"),
    )
    verify(href === `#${id}`, `The #${id} heading links to itself`)
  }

  await page.hover("#usage h2 a")
  await settle()
  const mark = await page.$eval("#usage h2 a", (link) => getComputedStyle(link, "::after").opacity)
  verify(mark === "1", "Hovering a heading shows its # mark")

  await page.setViewportSize({ width: 390, height: 844 })
  await page.goto(`${origin}/blocks/mobile_navigation/preview.html`)
  await page.waitForFunction(() =>
    window.Stimulus.controllers.some(({ identifier }) => identifier === "lc-dock"),
  )
  const dock = await page.$eval("[data-slot=dock] nav", (nav) => {
    const box = nav.getBoundingClientRect()
    return (
      getComputedStyle(nav).position === "fixed" &&
      box.bottom <= innerHeight &&
      box.top > innerHeight / 2
    )
  })
  verify(dock, "The dock sits fixed at the bottom of a phone screen")

  await page.click('[data-slot=dock] a[href="#notes"]')
  await settle()
  verify(
    (await page.$eval("#notes", (panel) => !panel.hidden)) &&
      (await page.getAttribute('[data-slot=dock] a[href="#notes"]', "aria-current")) === "page",
    "A dock link marks itself current",
  )

  await page.click("[data-slot=dock-menu-trigger]")
  await page.waitForSelector(".lc-dock__actions[data-open]", { state: "attached" })
  await page.getByRole("menuitem", { name: "Add a note" }).click()
  await settle()
  verify(
    (await page.$$eval(".lc-dock__actions[data-open]", (open) => open.length)) === 0 &&
      (await page.textContent("[data-blocks-mobile-navigation-target=status]")).includes(
        "A new thought added",
      ),
    "A dock action runs and closes the menu",
  )
  return checks
}
