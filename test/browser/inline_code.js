async function _verifyInlineCode(page) {
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  for (const path of ["/theming.html", "/components/foundations.html"]) {
    await page.goto(`${origin}${path}`)
    for (const theme of ["light", "dark"]) {
      await page.evaluate((value) => {
        document.documentElement.dataset.theme = value
      }, theme)
      const result = await page.evaluate(() => {
        const reference = [...document.querySelectorAll("#main code")].find(
          (code) => !code.closest("pre"),
        )
        const block = document.querySelector("#main pre code")
        const style = getComputedStyle(reference)
        const blockStyle = getComputedStyle(block)
        return {
          font: style.fontFamily,
          background: style.backgroundColor,
          padding: [style.paddingBlockStart, style.paddingInlineStart],
          radius: style.borderRadius,
          block: [blockStyle.backgroundColor, blockStyle.paddingTop, blockStyle.paddingLeft],
        }
      })
      const label = `${path} ${theme}`
      verify(result.font.includes("mono"), `${label}: inline references use a monospace font`)
      verify(
        result.background !== "rgba(0, 0, 0, 0)",
        `${label}: inline references have a visible background`,
      )
      verify(
        result.padding.every((value) => parseFloat(value) > 0),
        `${label}: inline references have padding`,
      )
      verify(parseFloat(result.radius) > 0, `${label}: inline references have rounded corners`)
      verify(
        result.block.join() === "rgba(0, 0, 0, 0),0px,0px",
        `${label}: code blocks keep their existing treatment`,
      )
    }
  }
  await page.goto(`${origin}/components/foundations.html`)
  const prose = await page.evaluate(() => {
    const paragraph = document.querySelector(".ui-prose p")
    const code = document.createElement("code")
    code.textContent = "--paper"
    paragraph.append(code)
    const style = getComputedStyle(code)
    const result = {
      background: style.backgroundColor,
      padding: parseFloat(style.paddingLeft),
      markers: [
        getComputedStyle(code, "::before").content,
        getComputedStyle(code, "::after").content,
      ],
    }
    code.remove()
    return result
  })
  verify(
    prose.background !== "rgba(0, 0, 0, 0)" && prose.padding > 0,
    "Reading content uses the same inline code treatment",
  )
  verify(
    prose.markers.every((value) => value === "none" || value === "normal"),
    "Reading content adds no decorative backticks",
  )
  await page.goto(`${origin}/theming.html`)
  for (const width of [1440, 390, 320]) {
    await page.setViewportSize({ width, height: 1000 })
    verify(
      await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth),
      `${width}px: inline paths and variables fit the page`,
    )
  }
  return checks
}
