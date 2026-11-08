async function _verifyComponentPicker(page) {
  const origin = await page.evaluate(() => location.origin)
  const viewport = page.viewportSize()
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const settleMotion = async () => {
    await page.screenshot()
    await page.waitForTimeout(350)
  }

  await page.goto(`${origin}/components.html`)
  const links = page.locator(".component-picker__link")
  const count = await links.count()
  const sidebarCount = await page
    .locator('aside[aria-label="Documentation sidebar"] ul[aria-label="Components"] a')
    .count()
  verify(
    count > 0 && count === sidebarCount,
    "The picker retains the complete list of component links",
  )

  try {
    const before = await links.evaluateAll((nodes) =>
      nodes.map((node) => {
        const box = node.getBoundingClientRect()
        return [box.top, box.height]
      }),
    )
    const layout = await links.evaluateAll((nodes) => {
      const lefts = [...new Set(nodes.map((node) => node.offsetLeft))].sort((a, b) => a - b)
      const titles = nodes.map((node) => node.querySelector(".component-picker__title").textContent)
      return {
        columns: lefts.map((left) => nodes.filter((node) => node.offsetLeft === left).length),
        sorted: titles.join() === [...titles].sort((a, b) => a.localeCompare(b)).join(),
        firstColumnRight: Math.max(
          ...nodes
            .filter((node) => node.offsetLeft === lefts[0])
            .map((node) => node.getBoundingClientRect().right),
        ),
        secondColumnLeft: Math.min(
          ...nodes
            .filter((node) => node.offsetLeft === lefts[1])
            .map((node) => node.getBoundingClientRect().left),
        ),
      }
    })
    verify(
      layout.columns.length === 2 &&
        layout.columns[0] === Math.ceil(count / 2) &&
        layout.columns[0] + layout.columns[1] === count,
      "Desktop splits the components into two balanced columns",
    )
    verify(layout.sorted, "Components stay alphabetical down the first column, then the second")

    const rows = Math.ceil(count / 2)
    const box = await links.nth(6).boundingBox()
    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2)
    await settleMotion()
    const wave = await links.evaluateAll((nodes, rows) => {
      const motion = (nodes) =>
        nodes.map((node) => {
          const title = node.querySelector(".component-picker__title")
          const matrix = new DOMMatrix(getComputedStyle(title).transform)
          return { scale: matrix.a, shift: matrix.e, right: title.getBoundingClientRect().right }
        })
      return { column: motion(nodes.slice(0, rows)), other: motion(nodes.slice(rows)) }
    }, rows)
    const falls = (key) =>
      [1, 2, 3, 4].every(
        (step) =>
          wave.column[6 - step][key] < wave.column[7 - step][key] &&
          wave.column[6 + step][key] < wave.column[5 + step][key],
      )
    verify(
      falls("scale") && falls("shift"),
      "The wave grows the selected title and tapers through four rows on each side",
    )
    verify(
      wave.column[6].scale - wave.column[5].scale > wave.column[5].scale - wave.column[4].scale,
      "The selected title stays clearly dominant over its neighbors",
    )
    verify(
      wave.column[11].shift === 0 && wave.other.every((row) => row.shift === 0 && row.scale === 1),
      "The wave stays inside the selected column",
    )
    verify(
      wave.column.every((row) => row.right < layout.secondColumnLeft),
      "Animated titles never overlap the second column",
    )
    const after = await links.evaluateAll((nodes) =>
      nodes.map((node) => {
        const box = node.getBoundingClientRect()
        return [box.top, box.height]
      }),
    )
    verify(
      JSON.stringify(before) === JSON.stringify(after),
      "Animation keeps every click target stable",
    )

    await links.nth(4).focus()
    await page.keyboard.press("ArrowDown")
    verify(
      await links
        .nth(5)
        .evaluate((node) => document.activeElement === node && node.dataset.distance === "0"),
      "Arrow Down moves keyboard focus to the next component",
    )
    await page.keyboard.press("ArrowUp")
    verify(
      await links.nth(4).evaluate((node) => document.activeElement === node),
      "Arrow Up moves keyboard focus to the previous component",
    )
    await page.keyboard.press("ArrowRight")
    verify(
      await links
        .nth(4 + rows)
        .evaluate((node) => document.activeElement === node && node.dataset.distance === "0"),
      "Arrow Right moves to the same row in the second column",
    )
    await page.keyboard.press("ArrowRight")
    await page.keyboard.press("ArrowLeft")
    verify(
      await links.nth(4).evaluate((node) => document.activeElement === node),
      "Arrow Left returns to the first column and Arrow Right stops at the last column",
    )
    await links.nth(rows - 1).focus()
    await page.keyboard.press("ArrowRight")
    verify(
      await links.last().evaluate((node) => document.activeElement === node),
      "Arrow Right from a row the shorter column lacks lands on its last component",
    )
    await page.keyboard.press("End")
    await page.keyboard.press("ArrowDown")
    verify(
      await links.last().evaluate((node) => document.activeElement === node),
      "End selects the last component and Arrow Down stays inside the list",
    )
    await page.keyboard.press("Home")
    await page.keyboard.press("ArrowUp")
    verify(
      await links.first().evaluate((node) => document.activeElement === node),
      "Home selects the first component and Arrow Up stays inside the list",
    )

    await page.setViewportSize({ width: 1440, height: 600 })
    await page.evaluate(() => scrollTo(0, 0))
    const target = await links.nth(3).boundingBox()
    await page.mouse.move(target.x + 40, target.y + target.height / 2)
    await page.mouse.wheel(0, target.height * 3)
    await page.waitForFunction(() => scrollY > 0)
    await page.evaluate(
      () => new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve))),
    )
    verify(
      await page.evaluate(
        ({ x, y }) => {
          const link = document.elementFromPoint(x, y).closest(".component-picker__link")
          return link?.dataset.distance === "0"
        },
        { x: target.x + 40, y: target.y + target.height / 2 },
      ),
      "Scrolling under a still pointer moves the selection with it",
    )

    for (const width of [1440, 768, 390, 320]) {
      await page.setViewportSize({ width, height: 900 })
      await page.locator('.component-picker__link[href="/components/description_list"]').focus()
      await page.keyboard.press("ArrowDown")
      await page.keyboard.press("ArrowUp")
      await settleMotion()
      const fits = await page.evaluate(() => {
        const active = document.querySelector('.component-picker__link[data-distance="0"]')
        const title = active.querySelector(".component-picker__title").getBoundingClientRect()
        return document.documentElement.scrollWidth <= innerWidth && title.right <= innerWidth
      })
      verify(fits, `${width}px: the enlarged component fits without horizontal scrolling`)
      const columns = await links.evaluateAll(
        (nodes) => new Set(nodes.map((node) => node.offsetLeft)).size,
      )
      verify(
        columns === (width >= 768 ? 2 : 1),
        `${width}px: the picker shows ${width >= 768 ? "two columns" : "one column"}`,
      )
    }

    await page.emulateMedia({ reducedMotion: "reduce" })
    await links.nth(4).focus()
    await page.keyboard.press("ArrowDown")
    await settleMotion()
    const reduced = await links.nth(5).evaluate((node) => {
      const title = getComputedStyle(node.querySelector(".component-picker__title"))
      const description = getComputedStyle(node.querySelector(".component-picker__description"))
      return (
        title.transform === "none" &&
        parseFloat(title.transitionDuration) <= 0.001 &&
        description.opacity === "1"
      )
    })
    verify(reduced, "Reduced motion keeps the selected description visible without movement")

    await page.keyboard.press("Enter")
    await page.waitForURL(`${origin}/components/button`)
    verify(
      page.url() === `${origin}/components/button`,
      "Enter follows the selected component's native documentation link",
    )
  } finally {
    await page.emulateMedia({ reducedMotion: null })
    if (viewport) await page.setViewportSize(viewport)
    await page.goto(`${origin}/components.html`)
  }
  return checks
}
