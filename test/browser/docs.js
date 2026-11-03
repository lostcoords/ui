async function _verifyDocs(page) {
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  for (const path of [
    "/",
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
          section.querySelector(":scope > header > .ui-heading-section"),
        )
        return {
          overflow: document.documentElement.scrollWidth > innerWidth,
          gap: getComputedStyle(stack).rowGap,
          title: [heading.fontSize, heading.lineHeight],
          sections: sections.map((section) => [
            getComputedStyle(section).rowGap,
            getComputedStyle(section.lastElementChild).rowGap,
          ]),
        }
      })
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
      root.style.setProperty("--ui-space-section", "40px")
      root.style.setProperty("--ui-space-heading", "18px")
      root.style.setProperty("--ui-space-content", "24px")
      const stack = document.querySelector("#main header").parentElement
      const section = [...document.querySelectorAll("#main section")].find((element) =>
        element.querySelector(":scope > header > .ui-heading-section"),
      )
      const result = [getComputedStyle(stack).rowGap]
      if (section)
        result.push(
          getComputedStyle(section).rowGap,
          getComputedStyle(section.lastElementChild).rowGap,
        )
      for (const name of ["section", "heading", "content"])
        root.style.removeProperty(`--ui-space-${name}`)
      return result
    })
    verify(
      adjusted[0] === "40px" && (adjusted.length === 1 || adjusted.slice(1).join() === "18px,24px"),
      `${path}: spacing overrides reach the actual docs`,
    )
  }
  await page.goto(`${origin}/theming.html`)
  await page.setViewportSize({ width: 1440, height: 1000 })
  return checks
}
