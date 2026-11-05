async function _verifyControlSurfaces(page) {
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (ok, label) => {
    if (!ok) throw new Error(label)
    checks.push(label)
  }
  // Reduced motion is reset in finally, so a failure can't leak it into later suites.
  await page.emulateMedia({ reducedMotion: "reduce" })
  try {
    await page.mouse.move(0, 0)
    await page.goto(`${origin}/components/copy_button.html`)
    await page.locator("#example-1 [data-example-preview] input").waitFor()
    const copySurfaces = await page.evaluate(() => {
      const root = document.documentElement
      const previous = {
        theme: root.getAttribute("data-theme"),
        palette: root.getAttribute("data-palette"),
      }
      const stages = [...document.querySelectorAll("[data-example-preview]")]
      const styles = stages.map((e) => e.getAttribute("style"))
      const ghost = stages[0].querySelectorAll("button")[2]
      const canvas = document.createElement("canvas")
      canvas.width = canvas.height = 1
      const ctx = canvas.getContext("2d")
      const color = (css, backdrop, opacity = 1) => {
        ctx.clearRect(0, 0, 1, 1)
        ctx.globalAlpha = 1
        if (backdrop) {
          ctx.fillStyle = backdrop
          ctx.fillRect(0, 0, 1, 1)
        }
        ctx.globalAlpha = opacity
        ctx.fillStyle = css
        ctx.fillRect(0, 0, 1, 1)
        ctx.globalAlpha = 1
        return [...ctx.getImageData(0, 0, 1, 1).data]
      }
      const luminance = (rgb) =>
        rgb
          .slice(0, 3)
          .map((n) => n / 255)
          .map((n) => (n <= 0.04045 ? n / 12.92 : ((n + 0.055) / 1.055) ** 2.4))
          .reduce((sum, n, i) => sum + n * [0.2126, 0.7152, 0.0722][i], 0)
      const contrast = (a, b) => {
        const x = [luminance(a), luminance(b)].sort((a, b) => a - b)
        return (x[1] + 0.05) / (x[0] + 0.05)
      }
      const failures = []
      let minimumText = Number.POSITIVE_INFINITY
      let minimumPlaceholder = Number.POSITIVE_INFINITY
      try {
        root.removeAttribute("data-palette")
        for (const theme of ["light", "dark"]) {
          root.dataset.theme = theme
          for (const surface of ["--background", "--muted", "--accent"]) {
            for (const stage of stages) {
              stage.style.backgroundColor = `var(${surface})`
              for (const animation of stage.getAnimations()) animation.finish()
              const backdrop = getComputedStyle(stage).backgroundColor
              const background = color(backdrop)
              for (const control of stage.querySelectorAll("button,input")) {
                for (const a of control.getAnimations()) a.finish()
                const css = getComputedStyle(control)
                const fill = color(css.backgroundColor, backdrop, Number(css.opacity))
                const difference = Math.max(
                  ...fill.slice(0, 3).map((n, i) => Math.abs(n - background[i])),
                )
                if (control === ghost) {
                  if (color(css.backgroundColor)[3] !== 0)
                    failures.push(`${theme} ${surface}: ghost is filled`)
                } else if (control.disabled) {
                  // Disabled buttons take a faint foreground tint over whatever is behind them.
                  if (color(css.backgroundColor)[3] === 0)
                    failures.push(`${theme} ${surface}: disabled control has no tint`)
                } else if (color(css.backgroundColor)[3] !== 255) {
                  failures.push(`${theme} ${surface}: filled control is transparent`)
                } else if (
                  difference < (control.disabled ? 1 : 8) &&
                  (control.tagName === "INPUT" ||
                    surface === "--background" ||
                    surface === "--muted")
                ) {
                  failures.push(
                    `${theme} ${surface}: ${control.getAttribute("aria-label") || control.tagName} blends into its surface`,
                  )
                }
                if (!control.disabled && control !== ghost)
                  minimumText = Math.min(minimumText, contrast(color(css.color), fill))
                if (control.tagName === "INPUT")
                  minimumPlaceholder = Math.min(
                    minimumPlaceholder,
                    contrast(color(getComputedStyle(control, "::placeholder").color), fill),
                  )
              }
            }
          }
        }
      } finally {
        for (const [name, value] of Object.entries(previous)) {
          if (value === null) root.removeAttribute(`data-${name}`)
          else root.setAttribute(`data-${name}`, value)
        }
        stages.forEach((e, i) => {
          if (styles[i] === null) e.removeAttribute("style")
          else e.setAttribute("style", styles[i])
        })
      }
      return { failures, minimumText, minimumPlaceholder }
    })
    verify(
      copySurfaces.failures.length === 0,
      `Copy controls have opaque fills and remain distinct on pages and cards: ${copySurfaces.failures.join("; ")}`,
    )
    verify(copySurfaces.minimumText >= 4.5, "Copy controls retain readable text in both themes")
    verify(copySurfaces.minimumPlaceholder >= 4.5, "Input placeholders retain readable contrast")

    const copied = await page
      .locator("#example-1 [data-example-preview]")
      .evaluate(async (stage) => {
        const descriptor = Object.getOwnPropertyDescriptor(navigator, "clipboard")
        const values = []
        const input = stage.querySelector("input")
        const original = input.value
        try {
          Object.defineProperty(navigator, "clipboard", {
            configurable: true,
            value: { writeText: async (text) => values.push(text) },
          })
          input.value = "https://example.test/edited"
          stage.querySelector("button").click()
          await new Promise((resolve) => setTimeout(resolve, 0))
          return {
            value: values[0],
            state: stage.querySelector('[data-controller~="lc-copy"]').dataset.state,
          }
        } finally {
          input.value = original
          if (descriptor) Object.defineProperty(navigator, "clipboard", descriptor)
          else delete navigator.clipboard
        }
      })
    verify(
      copied.value === "https://example.test/edited" && copied.state === "copied",
      "Copy still reads the live input and shows success feedback",
    )

    await page.goto(`${origin}/components/button.html`)
    await page.locator("#example-1 [data-example-preview] button").first().waitFor()
    const variants = await page.evaluate(() => {
      const root = document.documentElement
      const previous = {
        theme: root.getAttribute("data-theme"),
        palette: root.getAttribute("data-palette"),
      }
      const stage = document.querySelector("#example-1 [data-example-preview]")
      const canvas = document.createElement("canvas")
      canvas.width = canvas.height = 1
      const ctx = canvas.getContext("2d")
      const rgb = (css) => {
        ctx.clearRect(0, 0, 1, 1)
        ctx.fillStyle = css
        ctx.fillRect(0, 0, 1, 1)
        return [...ctx.getImageData(0, 0, 1, 1).data]
      }
      const luminance = (color) =>
        color
          .slice(0, 3)
          .map((n) => n / 255)
          .map((n) => (n <= 0.04045 ? n / 12.92 : ((n + 0.055) / 1.055) ** 2.4))
          .reduce((sum, n, i) => sum + n * [0.2126, 0.7152, 0.0722][i], 0)
      const failures = []
      try {
        root.removeAttribute("data-palette")
        for (const theme of ["light", "dark"]) {
          root.dataset.theme = theme
          for (const a of stage.getAnimations()) a.finish()
          for (const button of stage.querySelectorAll("button")) {
            for (const a of button.getAnimations()) a.finish()
            const css = getComputedStyle(button)
            let fill = rgb(css.backgroundColor)
            const label = button.textContent.trim()
            if (label === "Ghost" || label === "Outline") {
              if (fill[3] !== 0) failures.push(`${theme}: ${label} is filled`)
              if (
                label === "Outline" &&
                (Number.parseFloat(css.borderTopWidth) < 1 || rgb(css.borderTopColor)[3] === 0)
              )
                failures.push(`${theme}: outline edge is missing`)
              fill = rgb(getComputedStyle(stage).backgroundColor)
            } else if (label === "Glass") {
              const solid =
                matchMedia("(prefers-reduced-transparency: reduce)").matches ||
                !(
                  CSS.supports("backdrop-filter", "blur(1px)") ||
                  CSS.supports("-webkit-backdrop-filter", "blur(1px)")
                )
              if (
                solid
                  ? fill[3] !== 255
                  : fill[3] === 0 ||
                    fill[3] === 255 ||
                    (css.backdropFilter || css.webkitBackdropFilter) === "none"
              )
                failures.push(`${theme}: glass material is missing`)
              ctx.fillStyle = getComputedStyle(stage).backgroundColor
              ctx.fillRect(0, 0, 1, 1)
              ctx.fillStyle = css.backgroundColor
              ctx.fillRect(0, 0, 1, 1)
              fill = [...ctx.getImageData(0, 0, 1, 1).data]
            } else if (fill[3] !== 255) {
              failures.push(`${theme}: ${label} is not filled`)
            }
            if (label !== "Glass" && css.boxShadow !== "none")
              failures.push(`${theme}: ${label} should be flat`)
            const light = [luminance(fill), luminance(rgb(css.color))].sort((a, b) => a - b)
            if ((light[1] + 0.05) / (light[0] + 0.05) < 4.5)
              failures.push(`${theme}: ${label} text contrast`)
          }
        }
      } finally {
        for (const [name, value] of Object.entries(previous)) {
          if (value === null) root.removeAttribute(`data-${name}`)
          else root.setAttribute(`data-${name}`, value)
        }
      }
      return failures
    })
    verify(
      variants.length === 0,
      `Button variants retain their fills, edges, materials and readable labels: ${variants.join("; ")}`,
    )

    const secondaryHoverColors = new Map()
    for (const component of ["button", "icon_button"]) {
      await page.goto(
        `${origin}/components/${component === "icon_button" ? "button" : component}.html`,
      )
      const stage = page
        .locator(
          component === "button"
            ? "#example-1 [data-example-preview]"
            : "#example-11 [data-example-preview]",
        )
        .first()
      const buttons = stage.locator("button")
      const button = component === "button" ? buttons.filter({ hasText: "Ghost" }) : buttons.first()
      await button.waitFor()
      const previous = await stage.evaluate((stage) => ({
        theme: document.documentElement.getAttribute("data-theme"),
        palette: document.documentElement.getAttribute("data-palette"),
        style: stage.getAttribute("style"),
      }))
      try {
        for (const theme of ["light", "dark"]) {
          for (const surface of ["--background", "--muted", "--accent"]) {
            await page.mouse.move(0, 0)
            await stage.evaluate(
              (stage, { theme, surface }) => {
                document.documentElement.dataset.theme = theme
                document.documentElement.removeAttribute("data-palette")
                stage.style.backgroundColor = `var(${surface})`
                for (const a of stage.getAnimations()) a.finish()
                stage.scrollIntoView({ block: "center", behavior: "instant" })
              },
              { theme, surface },
            )
            if (component === "button" && surface === "--background") {
              for (const label of ["Primary", "Delete", "Outline", "Glass", "Secondary"]) {
                const variant = buttons.filter({ hasText: label })
                await page.bringToFront()
                await variant.hover({ force: true })
                const hovered = await variant.evaluate((button) => {
                  getComputedStyle(button).backgroundColor
                  for (const a of button.getAnimations()) a.finish()
                  const css = getComputedStyle(button)
                  const canvas = document.createElement("canvas")
                  canvas.width = canvas.height = 1
                  const ctx = canvas.getContext("2d")
                  const luminance = (color, backdrop) => {
                    ctx.clearRect(0, 0, 1, 1)
                    if (backdrop) {
                      ctx.fillStyle = backdrop
                      ctx.fillRect(0, 0, 1, 1)
                    }
                    ctx.fillStyle = color
                    ctx.fillRect(0, 0, 1, 1)
                    return [...ctx.getImageData(0, 0, 1, 1).data]
                      .slice(0, 3)
                      .map((n) => n / 255)
                      .map((n) => (n <= 0.04045 ? n / 12.92 : ((n + 0.055) / 1.055) ** 2.4))
                      .reduce((sum, n, i) => sum + n * [0.2126, 0.7152, 0.0722][i], 0)
                  }
                  const backdrop = getComputedStyle(
                    button.closest("[data-example-preview]"),
                  ).backgroundColor
                  const light = [
                    luminance(css.color),
                    luminance(css.backgroundColor, backdrop),
                  ].sort((a, b) => a - b)
                  return {
                    background: css.backgroundColor,
                    contrast: (light[1] + 0.05) / (light[0] + 0.05),
                  }
                })
                verify(hovered.contrast >= 4.5, `${theme}: ${label} hover text remains readable`)
                if (label === "Secondary") secondaryHoverColors.set(theme, hovered.background)
              }
              const customHover = await buttons
                .filter({ hasText: "Secondary" })
                .evaluate((button) => {
                  const previous = button.style.getPropertyValue("--lc-button-bg")
                  try {
                    button.style.setProperty("--lc-button-bg", "oklch(85% 0.08 200)")
                    getComputedStyle(button).backgroundColor
                    for (const a of button.getAnimations()) a.finish()
                    return getComputedStyle(button).backgroundColor
                  } finally {
                    if (previous) button.style.setProperty("--lc-button-bg", previous)
                    else button.style.removeProperty("--lc-button-bg")
                  }
                })
              verify(
                customHover !== secondaryHoverColors.get(theme),
                `${theme}: hover follows a custom base color without a separate hover color`,
              )
              await page.mouse.move(0, 0)
            }
            const resting = await button.evaluate((button) => {
              getComputedStyle(button).backgroundColor
              for (const a of button.getAnimations()) a.finish()
              const css = getComputedStyle(button)
              return {
                background: css.backgroundColor,
                width: button.offsetWidth,
                height: button.offsetHeight,
              }
            })
            const box = await button.boundingBox()
            await page.bringToFront()
            await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2)
            const hovered = await button.evaluate((button) => {
              getComputedStyle(button).backgroundColor
              for (const a of button.getAnimations()) a.finish()
              const css = getComputedStyle(button)
              const stage = button.closest("[data-example-preview]")
              const canvas = document.createElement("canvas")
              canvas.width = canvas.height = 1
              const ctx = canvas.getContext("2d")
              const rgb = (color) => {
                ctx.clearRect(0, 0, 1, 1)
                ctx.fillStyle = color
                ctx.fillRect(0, 0, 1, 1)
                return [...ctx.getImageData(0, 0, 1, 1).data]
              }
              const fill = rgb(css.backgroundColor)
              const backdrop = rgb(getComputedStyle(stage).backgroundColor)
              return {
                hovered: button.matches(":hover"),
                background: css.backgroundColor,
                alpha: fill[3],
                difference: Math.max(...fill.slice(0, 3).map((n, i) => Math.abs(n - backdrop[i]))),
                radius: Number.parseFloat(css.borderTopLeftRadius),
                width: button.offsetWidth,
                height: button.offsetHeight,
              }
            })
            verify(
              hovered.background === secondaryHoverColors.get(theme),
              `${component} ghost and secondary buttons share a hover fill: ${theme} ${surface}`,
            )
            verify(
              resting.background === "rgba(0, 0, 0, 0)" &&
                hovered.hovered &&
                hovered.alpha === 255 &&
                hovered.difference >= 8 &&
                hovered.radius > 0 &&
                hovered.width === resting.width &&
                hovered.height === resting.height,
              `${component} ghost is transparent at rest and shows its full rounded shape on hover: ${theme} ${surface}`,
            )
          }
        }
      } finally {
        await page.mouse.move(0, 0)
        await stage.evaluate((stage, previous) => {
          for (const name of ["theme", "palette"]) {
            if (previous[name] === null) document.documentElement.removeAttribute(`data-${name}`)
            else document.documentElement.setAttribute(`data-${name}`, previous[name])
          }
          if (previous.style === null) stage.removeAttribute("style")
          else stage.setAttribute("style", previous.style)
        }, previous)
      }
    }
    return checks
  } finally {
    await page.emulateMedia({ reducedMotion: null })
  }
}
