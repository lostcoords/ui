async function _verifyTheming(page, defaultCss, customCss) {
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const origin = await page.evaluate(() => location.origin)
  await page.goto(`${origin}/theming.html`)
  await page.locator("h1").waitFor()
  const cardPage = await (
    await page.request.get(`${origin}/components/card.html`, { ignoreHTTPSErrors: true })
  ).text()
  const buttonPage = await (
    await page.request.get(`${origin}/components/button.html`, { ignoreHTTPSErrors: true })
  ).text()
  const preview = await page.evaluate(
    ({ cardPage, buttonPage }) => {
      const parser = new DOMParser()
      const card = parser
        .parseFromString(cardPage, "text/html")
        .querySelector("#example-0 [data-example-preview]").firstElementChild
      const button = parser
        .parseFromString(buttonPage, "text/html")
        .querySelector("#example-0 [data-example-preview] button")
      card.dataset.defaultCard = ""
      card.append(button)
      return card.outerHTML
    },
    { cardPage, buttonPage },
  )
  for (const width of [1440, 390, 320]) {
    await page.setViewportSize({ width, height: 1000 })
    verify(
      await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth),
      `${width}px: guide and expanded variable reference fit the viewport`,
    )
  }

  await page.setContent(
    `<!doctype html><html lang="en"><head></head><body>${preview}</body></html>`,
  )
  await page.addStyleTag({ content: defaultCss })
  await page.addStyleTag({ content: "* { transition: none !important; }" })
  const values = () =>
    page.evaluate(() => {
      const button = document.querySelector("button")
      const root = getComputedStyle(document.documentElement)
      const style = getComputedStyle(button)
      return {
        background: getComputedStyle(document.body).backgroundColor,
        primary: style.backgroundColor,
        font: style.fontFamily,
        radius: getComputedStyle(document.querySelector("[data-default-card]")).borderRadius,
        shadow: root.getPropertyValue("--lc-shadow").trim(),
        duration: root.getPropertyValue("--lc-sheet-duration").trim(),
      }
    })

  const defaults = {}
  for (const theme of ["light", "dark"]) {
    await page.evaluate((value) => {
      document.documentElement.dataset.theme = value
    }, theme)
    defaults[theme] = await values()
    verify(
      defaults[theme].primary !== "rgba(0, 0, 0, 0)",
      `${theme}: primary button has a default color`,
    )
    verify(defaults[theme].shadow.length > 0, `${theme}: surfaces have a default shadow value`)
    verify(defaults[theme].duration === "500ms", `${theme}: sheet motion has a default duration`)
    verify(
      defaults[theme].font.includes("system-ui"),
      `${theme}: system font needs no font download`,
    )
  }
  verify(
    defaults.light.background !== defaults.dark.background,
    "Dark mode changes the default page palette",
  )
  verify(
    defaults.light.primary !== defaults.dark.primary,
    "Dark mode changes the default action palette",
  )

  await page.addStyleTag({ content: customCss })
  for (const theme of ["light", "dark"]) {
    await page.evaluate((value) => {
      document.documentElement.dataset.theme = value
    }, theme)
    const custom = await values()
    verify(
      custom.primary !== defaults[theme].primary,
      `${theme}: the guide's color overrides restyle primary actions`,
    )
    verify(custom.radius === "16px", `${theme}: the guide's radius override restyles cards`)
    verify(
      custom.shadow !== defaults[theme].shadow,
      `${theme}: the guide's shadow override changes surface shadows`,
    )
    verify(custom.font.includes("Inter"), `${theme}: the guide's font override reaches components`)
  }
  await page.goto(`${origin}/theming.html`)
  await page.setViewportSize({ width: 1440, height: 1000 })
  return checks
}
