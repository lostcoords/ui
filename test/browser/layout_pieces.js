async function _verifyLayoutPieces(page) {
  page.setDefaultTimeout(10000)
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const visit = async (component) => {
    await page.goto(`${origin}/components/${component}.html`)
    await page.locator('[data-controller~="showcase"]').waitFor()
  }
  const indicatorOnCurrent = (bar) =>
    page.waitForFunction((selector) => {
      const nav = document.querySelector(selector)
      const indicator = nav.querySelector("[data-slot=nav-indicator]").getBoundingClientRect()
      const current = nav.querySelector("[aria-current=page]").getBoundingClientRect()
      return (
        nav.hasAttribute("data-indicator") &&
        ["left", "top", "width", "height"].every(
          (side) => Math.abs(indicator[side] - current[side]) < 1,
        )
      )
    }, bar)

  await visit("nav_list")
  const row = 'nav[data-slot=nav-list][data-layout="row"]'
  const dock = 'nav[data-slot=nav-list][data-layout="dock"]'
  await indicatorOnCurrent(row)
  verify(true, "the indicator covers the current link once placed")
  await page.waitForFunction(
    (selector) =>
      getComputedStyle(document.querySelector(`${selector} [aria-current=page]`))
        .backgroundColor === "rgba(0, 0, 0, 0)",
    row,
  )
  verify(true, "with the indicator placed the current link drops its own fill")

  await page.locator(`${row} a[href="#activity"]`).click()
  verify(
    (await page.locator(`${row} a[href="#activity"]`).getAttribute("aria-current")) === "page",
    "clicking a link makes it current",
  )
  await indicatorOnCurrent(row)
  verify(true, "the indicator slides to the clicked link")

  await page.evaluate(() => {
    document.documentElement.dir = "rtl"
  })
  await page.locator(`${row} a[href="#files"]`).click()
  await indicatorOnCurrent(row)
  verify(true, "the indicator follows the current link right to left")
  await page.evaluate(() => {
    document.documentElement.dir = "ltr"
  })

  const dockLayout = await page.evaluate((selector) => {
    const link = document.querySelector(`${selector} a`)
    const icon = link.querySelector("svg").getBoundingClientRect()
    const label = link.querySelector("span").getBoundingClientRect()
    const widths = [...document.querySelectorAll(`${selector} a`)].map(
      (a) => a.getBoundingClientRect().width,
    )
    return {
      stacked: icon.bottom <= label.top + 1,
      height: link.getBoundingClientRect().height,
      equal: Math.max(...widths) - Math.min(...widths) < 1,
    }
  }, dock)
  verify(dockLayout.stacked, "the dock stacks each icon above its label")
  verify(dockLayout.equal, "dock cells share the width")
  verify(dockLayout.height >= 44, "dock links are at least 44px tall")

  await visit("collapsible")
  const chevron = page.locator(
    "details[data-slot=collapsible]:has([data-slot=collapsible-indicator])",
  )
  const rotation = () =>
    chevron.evaluate((details) => {
      const icon = details.querySelector("[data-slot=collapsible-indicator]")
      return getComputedStyle(icon).rotate
    })
  verify(["none", "0deg"].includes(await rotation()), "a closed chevron points down")
  verify(
    (await chevron.evaluate((details) => getComputedStyle(details).backgroundColor)) ===
      "rgba(0, 0, 0, 0)",
    "card: false drops the card surface",
  )
  await chevron.locator("summary").click()
  await page.waitForFunction(
    () =>
      getComputedStyle(document.querySelector("details[open] [data-slot=collapsible-indicator]"))
        .rotate === "180deg",
  )
  verify(true, "an open chevron turns over")
  const summaryHeight = await chevron.evaluate(
    (details) => details.querySelector("summary").getBoundingClientRect().height,
  )
  verify(summaryHeight >= 40, "a chevron summary keeps a control-sized hit target")
  const buttonSummary = await page
    .locator("details[data-slot=collapsible] summary[class*=rounded-pill]")
    .evaluate((summary) => ({ display: getComputedStyle(summary).display }))
  verify(buttonSummary.display === "inline-flex", "a button summary takes the button's layout")

  await visit("toast")
  const region = page.locator('[data-slot=toast-region][data-placement="bottom-center"]')
  const show = async () => {
    await region.evaluate((element) => element.replaceChildren())
    await page.getByRole("button", { name: "Add expense" }).click()
    await region.locator("[data-slot=toast]").waitFor()
    await page.waitForFunction(() =>
      document.querySelector('[data-placement="bottom-center"]')?.matches(":popover-open"),
    )
    return region.evaluate((element) => {
      const box = element.getBoundingClientRect()
      return {
        centre: box.left + box.width / 2,
        top: box.top,
        bottom: box.bottom,
        width: innerWidth,
        height: innerHeight,
        open: element.matches(":popover-open"),
      }
    })
  }
  const desktop = await show()
  verify(desktop.open, "a placed region still opens in the top layer")
  verify(Math.abs(desktop.centre - desktop.width / 2) < 2, "bottom_center centres the region")
  verify(desktop.height - desktop.bottom < 40, "bottom_center sits at the bottom")
  await page.setViewportSize({ width: 390, height: 800 })
  const phone = await show()
  verify(Math.abs(phone.centre - phone.width / 2) < 2, "mobile top_center centres the region")
  verify(phone.top < 40, "mobile_placement moves the region to the top below sm")
  await region.evaluate((element) => element.style.setProperty("--lc-toast-offset-top", "80px"))
  const belowHeader = await show()
  verify(Math.abs(belowHeader.top - 80) < 2, "--lc-toast-offset-top moves only the top edge")
  await region.evaluate((element) => element.style.removeProperty("--lc-toast-offset-top"))
  await page.setViewportSize({ width: 1440, height: 900 })

  await visit("list_group")
  const rows = await page.evaluate(() => {
    const list = [...document.querySelectorAll("[data-slot=list-row]")]
    const radius = (row, corner) => parseFloat(getComputedStyle(row)[corner])
    return {
      gaps: list
        .slice(1)
        .map(
          (row, index) =>
            row.getBoundingClientRect().top - list[index].getBoundingClientRect().bottom,
        ),
      firstTop: radius(list[0], "borderTopLeftRadius"),
      firstBottom: radius(list[0], "borderBottomLeftRadius"),
      middle: radius(list[1], "borderTopLeftRadius") + radius(list[1], "borderBottomLeftRadius"),
      lastBottom: radius(list.at(-1), "borderBottomLeftRadius"),
    }
  })
  verify(
    rows.gaps.every((gap) => Math.abs(gap - 2) < 0.5),
    "rows sit 2px apart",
  )
  verify(rows.firstTop > 0 && rows.firstBottom === 0, "only the first row's top corners round")
  verify(rows.middle === 0, "middle rows are square")
  verify(rows.lastBottom > 0, "the last row's bottom corners round")

  const surfaces = await page.evaluate(() => {
    const root = document.documentElement
    root.style.setProperty("--card-secondary", "rgb(1, 2, 3)")
    root.style.setProperty("--card-input", "rgb(4, 5, 6)")
    const button = document.querySelector("[data-slot=list-row] [data-slot=button]")
    button.style.transition = "none"
    const result = { button: getComputedStyle(button).backgroundColor }
    root.style.removeProperty("--card-secondary")
    root.style.removeProperty("--card-input")
    result.reset = getComputedStyle(button).backgroundColor
    return result
  })
  verify(surfaces.button === "rgb(1, 2, 3)", "secondary buttons in rows follow --card-secondary")
  verify(surfaces.reset !== "rgb(1, 2, 3)", "without an override they keep --secondary")

  await visit("card")
  const field = await page.evaluate(() => {
    const root = document.documentElement
    root.style.setProperty("--card-input", "rgb(4, 5, 6)")
    const inCard = document.querySelector(".lc-card input")
    inCard.style.transition = "none"
    const result = getComputedStyle(inCard).backgroundColor
    root.style.removeProperty("--card-input")
    return result
  })
  verify(field === "rgb(4, 5, 6)", "fields in cards follow --card-input")

  const edges = await page.evaluate(() => {
    const card = document.createElement("div")
    card.className = "lc-card"
    card.style.transition = "none"
    document.body.append(card)
    const edge = () => getComputedStyle(card).borderTopColor
    const plain = edge()
    card.innerHTML = '<div data-slot="menu"><button data-tone="destructive">Remove</button></div>'
    const menu = edge()
    card.innerHTML = '<button data-tone="destructive">Delete</button>'
    const own = edge()
    card.remove()
    return { plain, menu, own }
  })
  verify(edges.menu === edges.plain, "a destructive option in a card's closed menu leaves the edge alone")
  verify(edges.own !== edges.plain, "a destructive control in the card tints its edge")

  return checks
}
