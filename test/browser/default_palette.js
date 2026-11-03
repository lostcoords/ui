async function _verifyNeutralDefaults(page) {
  const checks = []
  const verify = (condition, label) => {
    if (!condition) throw new Error(label)
    checks.push(label)
  }
  const origin = await page.evaluate(() => location.origin)
  await page.goto(`${origin}/components/button.html`)
  await page.locator("#example-0 [data-example-preview] button").waitFor()
  await page.waitForFunction(() =>
    getComputedStyle(document.documentElement).getPropertyValue("--primary").trim(),
  )

  const results = await page.evaluate(() => {
    const root = document.documentElement
    const previous = {
      theme: root.getAttribute("data-theme"),
      palette: root.getAttribute("data-palette"),
    }
    const canvas = document.createElement("canvas")
    canvas.width = canvas.height = 1
    const ctx = canvas.getContext("2d")
    const rgb = (color) => {
      ctx.clearRect(0, 0, 1, 1)
      ctx.fillStyle = color
      ctx.fillRect(0, 0, 1, 1)
      return [...ctx.getImageData(0, 0, 1, 1).data].slice(0, 3)
    }
    const neutral = (color) => Math.max(...color) - Math.min(...color) <= 1
    const luminance = (color) =>
      color
        .map((n) => n / 255)
        .map((n) => (n <= 0.04045 ? n / 12.92 : ((n + 0.055) / 1.055) ** 2.4))
        .reduce((sum, n, i) => sum + n * [0.2126, 0.7152, 0.0722][i], 0)
    const contrast = (a, b) => {
      const values = [luminance(a), luminance(b)].sort((x, y) => x - y)
      return (values[1] + 0.05) / (values[0] + 0.05)
    }
    const results = []
    try {
      root.removeAttribute("data-palette")
      for (const theme of ["light", "dark"]) {
        root.dataset.theme = theme
        const style = getComputedStyle(root)
        const color = (name) => rgb(style.getPropertyValue(name))
        const tokens = [
          "--background",
          "--muted",
          "--accent",
          "--foreground",
          "--muted-foreground",
          "--input",
          "--lc-input-hover",
          "--secondary",
          "--border",
          "--primary",
        ]
        const buttonElement = document.querySelector("#example-0 [data-example-preview] button")
        for (const animation of buttonElement.getAnimations()) animation.finish()
        const button = getComputedStyle(buttonElement)
        results.push({
          theme,
          canvasBrighterThanCards: luminance(color("--background")) > luminance(color("--muted")),
          neutral: tokens.every((name) => neutral(color(name))),
          buttonNeutral: neutral(rgb(button.backgroundColor)) && neutral(rgb(button.color)),
          buttonContrast: contrast(rgb(button.backgroundColor), rgb(button.color)),
          textContrast: Math.min(
            ...["--foreground", "--muted-foreground"].map((name) =>
              contrast(color(name), color("--muted")),
            ),
          ),
          statusColors: ["--success", "--warning", "--destructive"].every(
            (name) => !neutral(color(name)),
          ),
        })
      }
    } finally {
      for (const [name, value] of Object.entries(previous)) {
        if (value === null) root.removeAttribute(`data-${name}`)
        else root.setAttribute(`data-${name}`, value)
      }
    }
    return results
  })

  for (const result of results) {
    if (result.theme === "light")
      verify(result.canvasBrighterThanCards, "Light mode uses a brighter page than its cards")
    verify(
      result.neutral && result.buttonNeutral,
      `${result.theme}: default surfaces, text and controls are neutral`,
    )
    verify(result.buttonContrast >= 4.5, `${result.theme}: primary action text meets AA contrast`)
    verify(result.textContrast >= 4.5, `${result.theme}: muted text remains readable on cards`)
    verify(result.statusColors, `${result.theme}: status colors remain available`)
  }

  await page.goto(`${origin}/components/avatar.html`)
  await page.locator("[data-example-preview] .lc-avatar").first().waitFor()
  const avatarsHaveColor = await page.evaluate(() => {
    const root = document.documentElement
    const theme = root.getAttribute("data-theme")
    const palette = root.getAttribute("data-palette")
    const canvas = document.createElement("canvas")
    canvas.width = canvas.height = 1
    const ctx = canvas.getContext("2d")
    try {
      root.removeAttribute("data-palette")
      return ["light", "dark"].every((mode) => {
        root.dataset.theme = mode
        return [...document.querySelectorAll("[data-example-preview] .lc-avatar")].some(
          (avatar) => {
            ctx.fillStyle = getComputedStyle(avatar).backgroundColor
            ctx.fillRect(0, 0, 1, 1)
            const rgb = [...ctx.getImageData(0, 0, 1, 1).data].slice(0, 3)
            return Math.max(...rgb) - Math.min(...rgb) > 8
          },
        )
      })
    } finally {
      if (theme === null) root.removeAttribute("data-theme")
      else root.setAttribute("data-theme", theme)
      if (palette === null) root.removeAttribute("data-palette")
      else root.setAttribute("data-palette", palette)
    }
  })
  verify(avatarsHaveColor, "Avatar identities retain color in both themes")
  return checks
}
