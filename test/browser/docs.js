async function _verifyDocs(page) {
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  for (const path of [
    "/installation.html",
    "/theming.html",
    "/components/button.html",
    "/components/foundations.html",
    "/blocks.html",
    "/blocks/application_header.html",
  ]) {
    await page.goto(`${origin}${path}`)
    for (const width of [1440, 390, 320]) {
      await page.setViewportSize({ width, height: 1000 })
      const layout = await page.evaluate(() => {
        const main = document.querySelector("#main")
        const stack = main.querySelector("header").parentElement
        const heading = getComputedStyle(main.querySelector("h1"))
        const sections = [...main.querySelectorAll("section")].filter((section) =>
          section.querySelector(":scope > header > .text-heading"),
        )
        const left = main.previousElementSibling
        const right = main.nextElementSibling
        const hasSidebars =
          left?.tagName === "ASIDE" &&
          right?.tagName === "ASIDE" &&
          left.offsetWidth > 0 &&
          right.offsetWidth > 0
        const gutters = hasSidebars
          ? [
              main.getBoundingClientRect().left -
                left.querySelector("nav").getBoundingClientRect().right,
              right.querySelector("nav").getBoundingClientRect().left -
                main.getBoundingClientRect().right,
            ]
          : null
        return {
          gutters,
          overflow: document.documentElement.scrollWidth > innerWidth,
          gap: getComputedStyle(stack).rowGap,
          title: [heading.fontSize, heading.lineHeight],
          sections: sections.map((section) => [
            getComputedStyle(section).rowGap,
            getComputedStyle(section.lastElementChild).rowGap,
          ]),
        }
      })
      if (layout.gutters)
        verify(
          Math.abs(layout.gutters[0] - layout.gutters[1]) < 1,
          `${path} ${width}px: both navigation gutters match`,
        )
      verify(!layout.overflow, `${path} ${width}px: docs fit the viewport`)
      verify(layout.gap === "32px", `${path} ${width}px: sections share 32px spacing`)
      verify(
        layout.title.join() === "30px,36px",
        `${path} ${width}px: page title uses the shared text role`,
      )
      if (layout.sections.length > 0) {
        verify(
          layout.sections.every(([heading, content]) => heading === "12px" && content === "16px"),
          `${path} ${width}px: sections share 12px heading and 16px content gaps`,
        )
      }
    }
    const adjusted = await page.evaluate(() => {
      const root = document.documentElement
      root.style.setProperty("--lc-density", "1.25")
      const stack = document.querySelector("#main header").parentElement
      const section = [...document.querySelectorAll("#main section")].find((element) =>
        element.querySelector(":scope > header > .text-heading"),
      )
      const result = [getComputedStyle(stack).rowGap]
      if (section)
        result.push(
          getComputedStyle(section).rowGap,
          getComputedStyle(section.lastElementChild).rowGap,
        )
      root.style.removeProperty("--lc-density")
      return result
    })
    verify(
      adjusted[0] === "40px" && (adjusted.length === 1 || adjusted.slice(1).join() === "15px,20px"),
      `${path}: spacing overrides reach the actual docs`,
    )
  }
  await page.goto(`${origin}/theming.html`)
  await page.setViewportSize({ width: 1440, height: 1000 })
  return checks
}
