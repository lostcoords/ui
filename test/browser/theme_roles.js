async function _verifyThemeRoles(page) {
  await page.bringToFront()
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const origin = await page.evaluate(() => location.origin)
  await page.goto(`${origin}/components/foundations.html`)
  await page.waitForFunction(() =>
    document.querySelector("#theme-color-table [data-token-value]")?.textContent.trim(),
  )
  verify(
    (await page.locator("#theme-color-table [data-token]").count()) === 22,
    "The everyday reference contains the twenty shadcn color roles and the two card surface roles",
  )
  verify(
    await page.locator("#style-settings").evaluate((element) => !element.closest("details")),
    "Typography, spacing and appearance remain visible without a dropdown",
  )
  const colorNames = await page
    .locator("#theme-color-table [data-token]")
    .evaluateAll((rows) => rows.map((row) => row.dataset.token))
  verify(
    !colorNames.some((name) => /color-|sky|leaf|berry|gold|paper|ink/.test(name)),
    "The everyday reference omits palette names and Tailwind aliases",
  )
  await page.locator("#foundation-token-filter").evaluate((element) => {
    element.value = "shadow"
    element.dispatchEvent(new Event("input", { bubbles: true }))
  })
  verify(
    (await page
      .locator("#foundation-token-table [data-showcase-target~='filterableToken']:visible")
      .count()) === 3,
    "Style settings filter by purpose",
  )
  verify(
    (await page.locator("#theme-color-table [data-token]:visible").count()) === 22,
    "Filtering style settings leaves everyday colors visible",
  )
  await page.locator("#foundation-token-filter").evaluate((element) => {
    element.value = ""
    element.dispatchEvent(new Event("input", { bubbles: true }))
  })

  const sources = {}
  for (const component of ["button", "toggle", "input", "icon_badge"]) {
    sources[component] = await (
      await page.request.get(`${origin}/components/${component}.html`, { ignoreHTTPSErrors: true })
    ).text()
  }
  await page.evaluate((sources) => {
    const fixture = document.createElement("section")
    fixture.id = "theme-role-verification"
    fixture.style.cssText = "padding: 24px; background: var(--background); color: var(--foreground)"
    const selectors = { button: "button", toggle: "button", input: "input", icon_badge: "span" }
    for (const [name, html] of Object.entries(sources)) {
      const doc = new DOMParser().parseFromString(html, "text/html")
      const element = doc.querySelector(
        `${name === "icon_badge" ? "#example-1 " : ""}[data-example-preview] ${selectors[name]}`,
      )
      if (!element) throw new Error(`No rendered ${name} example`)
      const copy = document.importNode(element, true)
      copy.id = `theme-probe-${name}`
      fixture.append(copy)
    }
    const prose = document.createElement("div")
    prose.className = document.querySelector(".lc-prose").className
    prose.innerHTML = '<a id="theme-probe-link" href="#theme-role-verification">A reading link</a>'
    fixture.append(prose)
    for (const role of ["success", "warning", "destructive"]) {
      const badge = document.createElement("span")
      badge.id = `theme-probe-${role}`
      badge.className = `bg-${role}-soft text-${role}`
      badge.textContent = role
      fixture.append(badge)
    }
    const style = document.createElement("style")
    style.textContent =
      "#theme-role-verification * { transition: none !important; animation: none !important; }"
    fixture.append(style)
    document.querySelector("#main").prepend(fixture)
  }, sources)

  const values = () =>
    page.evaluate(() => {
      const style = (name) => getComputedStyle(document.getElementById(`theme-probe-${name}`))
      return {
        button: style("button").backgroundColor,
        buttonText: style("button").color,
        link: style("link").color,
        toggleText: style("toggle").color,
        toggleFill: style("toggle").backgroundColor,
        iconBadge: style("icon_badge").backgroundColor,
        statuses: ["success", "warning", "destructive"].map((role) => [
          style(role).color,
          style(role).backgroundColor,
        ]),
      }
    })

  for (const mode of ["light", "dark"]) {
    await page.evaluate((mode) => {
      document.documentElement.dataset.theme = mode
      document.documentElement.removeAttribute("data-palette")
    }, mode)
    await page.locator("#theme-probe-input").evaluate((element) => element.focus())
    const before = await values()
    await page.locator("#theme-role-verification").evaluate((element) => {
      element.style.setProperty("--primary", "#135ac4")
      element.style.setProperty("--primary-foreground", "#fff")
      element.style.setProperty("--success", "#17683d")
      element.style.setProperty("--warning", "#806000")
      element.style.setProperty("--destructive", "#a82235")
    })
    const after = await values()
    verify(after.button !== before.button, `${mode}: a scoped primary override updates buttons`)
    verify(
      after.button === after.link && after.button === after.toggleText,
      `${mode}: buttons, reading links and selected toggles use the same primary color`,
    )
    verify(
      after.toggleFill !== before.toggleFill && after.iconBadge !== before.iconBadge,
      `${mode}: soft selection and icon badge backgrounds follow a scoped primary override`,
    )
    await page.bringToFront()
    const focus = await page.evaluate(() => {
      const input = document.getElementById("theme-probe-input")
      const fixture = document.getElementById("theme-role-verification")
      input.focus()
      // The ring transitions, so a read right after the change would return its starting value.
      input.style.transition = "none"
      fixture.style.setProperty("--primary", "#135ac4")
      const before = getComputedStyle(input).boxShadow
      fixture.style.setProperty("--primary", "#a82235")
      const after = getComputedStyle(input).boxShadow
      return { before, after, focused: input.matches(":focus") }
    })
    verify(
      focus.focused && focus.after !== focus.before && focus.after !== "none",
      `${mode}: keyboard focus follows a scoped primary override`,
    )
    verify(
      after.statuses.every(
        ([color, fill], index) =>
          color !== before.statuses[index][0] &&
          fill !== before.statuses[index][1] &&
          fill !== "rgba(0, 0, 0, 0)",
      ),
      `${mode}: status text and soft backgrounds follow scoped feedback colors`,
    )
    await page.locator("#theme-role-verification").evaluate((element) => {
      for (const role of ["primary", "primary-foreground", "success", "warning", "destructive"])
        element.style.removeProperty(`--${role}`)
    })
  }
  await page.goto(`${origin}/`)
  for (const width of [1440, 390, 320]) {
    await page.setViewportSize({ width, height: 1000 })
    for (const mode of ["light", "dark"]) {
      await page.evaluate((mode) => {
        document.documentElement.dataset.theme = mode
      }, mode)
      verify(
        await page.evaluate(
          () =>
            document.documentElement.scrollWidth <= innerWidth &&
            document.querySelector("#main").textContent.includes("Invite a teammate") &&
            !document.body.textContent.includes("Invalid tone"),
        ),
        `${width}px ${mode}: the homepage renders and fits the viewport`,
      )
    }
  }
  return checks
}
