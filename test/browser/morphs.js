// A Turbo morph matches elements by id. When rows are reordered, it moves a row's id-carrying
// children (a menu's trigger and panel) into the row that takes its place and removes the emptied
// host. Stimulus disconnects that host only afterwards, when its targets are already gone.
async function _verifyMorphs(page) {
  page.setDefaultTimeout(10000)
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const errors = []
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text())
  })
  page.on("pageerror", (error) => errors.push(error.message))
  const noErrors = (message) => {
    const seen = errors.splice(0)
    verify(seen.length === 0, `${message}${seen.length ? `: ${seen[0].slice(0, 400)}` : ""}`)
  }
  const controllersConnected = () =>
    page.waitForFunction(() => {
      const application = window.Stimulus
      if (!application) return false
      return [...document.querySelectorAll("[data-controller]")].every((element) =>
        element.dataset.controller
          .split(/\s+/)
          .every((name) => application.getControllerForElementAndIdentifier(element, name)),
      )
    })
  const settle = () => page.evaluate(() => new Promise((resolve) => setTimeout(resolve, 50)))

  await page.goto(`${origin}/components/menu.html`)
  await controllersConnected()
  await page.evaluate(() => {
    const sample = document.querySelector('[data-controller~="lc-menu"]')
    const id = sample.querySelector('[data-lc-menu-target~="popover"]').id
    const row = (name) =>
      `<li><span>${name}</span>${sample.outerHTML.replaceAll(id, `row-${name}-menu`)}</li>`
    const list = document.createElement("ul")
    list.id = "morph-rows"
    list.innerHTML = ["a", "b", "c"].map(row).join("")
    document.querySelector("main").append(list)
    window.reorderRows = () => {
      const next = document.createElement("ul")
      next.id = "morph-rows"
      next.innerHTML = ["b", "a", "c"].map(row).join("")
      window.Turbo.morphElements(list, next)
    }
  })
  await controllersConnected()
  await page.evaluate(() => window.reorderRows())
  await settle()
  verify(
    (await page.$$eval("#morph-rows [role=menu]", (menus) =>
      menus.map((menu) => menu.id).join(),
    )) === "row-b-menu,row-a-menu,row-c-menu",
    "A morph reorders rows that each hold a menu",
  )
  noErrors("Reordered menus disconnect without an error")

  await page.focus("#row-a-menu-trigger")
  await page.keyboard.press("ArrowDown")
  verify(
    await page.$eval(
      "#row-a-menu",
      (menu) => menu.hasAttribute("data-open") && menu.contains(document.activeElement),
    ),
    "Arrow Down still opens a menu whose trigger a morph moved",
  )
  await page.keyboard.press("ArrowDown")
  verify(
    await page.$eval(
      "#row-a-menu",
      (menu) =>
        [...menu.querySelectorAll("[role^=menuitem]")].indexOf(document.activeElement) === 1,
    ),
    "Arrow keys move through its items",
  )
  await page.keyboard.press("Escape")
  noErrors("The moved menu opens and closes without an error")

  await page.evaluate(() => {
    window.turboVisitMarker = true
  })
  await page.$eval('aside a[href="/components/button"]', (link) => link.click())
  await page.waitForFunction(() => document.title.startsWith("Button"))
  verify(
    await page.evaluate(() => window.turboVisitMarker === true),
    "The next visit goes through Turbo",
  )
  noErrors("Leaving the page after the morph closes no stale panel")

  // A panel hears the page leave only while it is open, and closes before Turbo caches the page.
  await page.goto(`${origin}/components/menu.html`)
  await controllersConnected()
  const opened = page.locator('main [data-lc-menu-target~="trigger"]').first()
  await opened.click()
  verify((await opened.getAttribute("aria-expanded")) === "true", "A menu opens")
  // A click on a link would close the menu as an outside click before the visit starts.
  await page.evaluate(() => window.Turbo.visit("/components/button"))
  await page.waitForFunction(() => document.title.startsWith("Button"))
  await page.goBack()
  await page.waitForFunction(() => document.title.startsWith("Menu"))
  verify(
    await page.evaluate(
      () =>
        !document.querySelector("main [data-open], main :popover-open") &&
        !document.querySelector('main [data-lc-menu-target~="trigger"][aria-expanded="true"]'),
    ),
    "Back restores the page with the menu closed",
  )
  noErrors("An open menu closes for a visit without an error")

  // A nav's indicator is placed by its controller; the server's HTML has neither its place nor
  // the mark of the link first rendered as current.
  await page.goto(`${origin}/components/nav_list.html`)
  await controllersConnected()
  const nav = 'main [data-controller~="lc-nav"]'
  await page.waitForSelector(`${nav}[data-indicator]`)
  const placed = () =>
    page.$eval(nav, (element) => ({
      shown: element.hasAttribute("data-indicator"),
      at: element.querySelector('[data-lc-nav-target~="indicator"]').style.translate,
      initial: element.querySelectorAll("[data-lc-nav-initial]").length,
    }))
  const before = await placed()
  await page.$eval(nav, (element) => {
    const server = element.cloneNode(true)
    server.removeAttribute("data-indicator")
    server.querySelector('[data-lc-nav-target~="indicator"]').removeAttribute("style")
    for (const link of server.querySelectorAll("[data-lc-nav-initial]"))
      link.removeAttribute("data-lc-nav-initial")
    window.Turbo.morphElements(element, server)
  })
  await settle()
  const after = await placed()
  verify(
    before.shown &&
      before.at &&
      before.initial === 1 &&
      JSON.stringify(after) === JSON.stringify(before),
    "A morph against server HTML keeps a nav's indicator where it is and its first link marked",
  )

  // The same teardown for every controller the docs show: a host emptied before it is removed.
  const pages = await page.$$eval('aside a[href^="/components/"]', (links) => [
    ...new Set(links.map((link) => link.getAttribute("href"))),
  ])
  let hosts = 0
  for (const path of pages) {
    await page.goto(`${origin}${path}`)
    await controllersConnected()
    hosts += await page.evaluate(() => {
      const found = [...document.querySelectorAll('main [data-controller*="lc-"]')]
      for (const host of found) {
        host.replaceChildren()
        host.remove()
      }
      return found.length
    })
    await settle()
    await page.evaluate(() => document.dispatchEvent(new CustomEvent("turbo:before-cache")))
    noErrors(`${path}: emptied hosts disconnect cleanly`)
  }
  verify(hosts > 50, `${hosts} emptied hosts on ${pages.length} pages disconnected`)
  return checks
}
