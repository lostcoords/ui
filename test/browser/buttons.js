async function _verifyButtons(page) {
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (ok, label) => {
    if (!ok) throw new Error(label)
    checks.push(label)
  }

  await page.goto(`${origin}/components/button.html`)
  await page.waitForFunction(() => {
    const application = window.Stimulus
    if (!application) return false
    return [...document.querySelectorAll("[data-controller]")].every((element) =>
      element.dataset.controller
        .split(/\s+/)
        .every((name) => application.getControllerForElementAndIdentifier(element, name)),
    )
  })
  const preview = (text) => page.locator("[data-example-preview]").filter({ hasText: text }).first()

  const tones = await preview("Remove member").evaluate((stage) => {
    const canvas = document.createElement("canvas")
    canvas.width = canvas.height = 1
    const ctx = canvas.getContext("2d")
    const rgb = (css) => {
      ctx.clearRect(0, 0, 1, 1)
      ctx.fillStyle = css
      ctx.fillRect(0, 0, 1, 1)
      return [...ctx.getImageData(0, 0, 1, 1).data]
    }
    const luminance = (c) =>
      c
        .slice(0, 3)
        .map((n) => n / 255)
        .map((n) => (n <= 0.04045 ? n / 12.92 : ((n + 0.055) / 1.055) ** 2.4))
        .reduce((sum, n, i) => sum + n * [0.2126, 0.7152, 0.0722][i], 0)
    const contrast = (a, b) => {
      const x = [luminance(a), luminance(b)].sort((p, q) => p - q)
      return (x[1] + 0.05) / (x[0] + 0.05)
    }
    const root = document.documentElement
    const previous = {
      theme: root.getAttribute("data-theme"),
      palette: root.getAttribute("data-palette"),
    }
    const results = {}
    root.removeAttribute("data-palette")
    stage.style.backgroundColor = "var(--background)"
    for (const theme of ["light", "dark"]) {
      root.dataset.theme = theme
      for (const button of stage.querySelectorAll("button"))
        for (const animation of button.getAnimations()) animation.finish()
      const page = rgb(getComputedStyle(stage).backgroundColor)
      const [ghost, outline, secondary, solid] = stage.querySelectorAll("button")
      results[theme] = {
        ghostRest: getComputedStyle(ghost).backgroundColor,
        ghostInk: contrast(rgb(getComputedStyle(ghost).color), page),
        outlineInk: contrast(rgb(getComputedStyle(outline).color), page),
        secondaryInk: contrast(
          rgb(getComputedStyle(secondary).color),
          rgb(getComputedStyle(secondary).backgroundColor),
        ),
        solidInk: contrast(
          rgb(getComputedStyle(solid).color),
          rgb(getComputedStyle(solid).backgroundColor),
        ),
      }
    }
    stage.style.backgroundColor = ""
    for (const [name, value] of Object.entries(previous)) {
      if (value) root.setAttribute(`data-${name}`, value)
      else root.removeAttribute(`data-${name}`)
    }
    return results
  })
  for (const theme of ["light", "dark"]) {
    const t = tones[theme]
    verify(
      t.ghostRest === "rgba(0, 0, 0, 0)",
      `a destructive ghost stays transparent at rest (${theme})`,
    )
    verify(
      Math.min(t.ghostInk, t.outlineInk, t.secondaryInk, t.solidInk) >= 4.5,
      `destructive tones keep AA ink in ${theme}: ${JSON.stringify(t)}`,
    )
  }

  const select = await preview("All members").evaluate((stage) => {
    const trigger = stage.querySelector("[data-slot=select-trigger]")
    const box = trigger.getBoundingClientRect()
    const label = trigger.querySelector("span").getBoundingClientRect()
    const chevron = trigger.querySelector("[data-icon=inline-end]").getBoundingClientRect()
    return {
      height: box.height,
      labelInset: label.left - box.left,
      chevronInset: box.right - chevron.right,
      fontSize: getComputedStyle(trigger).fontSize,
    }
  })
  verify(
    select.labelInset < 20,
    `the select trigger label starts at the inline start (${select.labelInset}px)`,
  )
  verify(
    select.chevronInset < 16,
    `the select trigger chevron sits at the inline end (${select.chevronInset}px)`,
  )
  verify(select.fontSize === "16px", "the select trigger keeps field text at 16px")

  const selectTrigger = preview("All members").locator("[data-slot=select-trigger]")
  await selectTrigger.click()
  verify(
    (await selectTrigger.getAttribute("aria-expanded")) === "true",
    "the select trigger opens its menu",
  )
  await page.keyboard.press("Escape")

  const split = preview("Add expense")
  const geometry = await split.evaluate((stage) => {
    const [action, toggle] = stage.querySelectorAll("button")
    const a = action.getBoundingClientRect()
    const t = toggle.getBoundingClientRect()
    const style = getComputedStyle(toggle)
    return {
      sameHeight: Math.abs(a.height - t.height) < 0.5,
      joined: Math.abs(t.left - a.right) < 0.5,
      square: Math.abs(t.width - t.height) < 0.5,
      divider: style.borderInlineStartWidth,
      outerRadius: parseFloat(getComputedStyle(action).borderStartStartRadius),
      innerRadius: parseFloat(getComputedStyle(action).borderStartEndRadius),
    }
  })
  verify(geometry.sameHeight && geometry.joined, "the split action and toggle form one joined pill")
  verify(geometry.square, "the split toggle is a square hit target")
  verify(geometry.divider === "1px", "the split toggle draws a divider on its inline start")
  verify(
    geometry.outerRadius > 0 && geometry.innerRadius === 0,
    "only the pill's outer corners are rounded",
  )

  const toggle = split.locator("button[aria-haspopup=menu]")
  const restFill = await toggle.evaluate((el) => getComputedStyle(el).backgroundColor)
  await toggle.click()
  verify((await toggle.getAttribute("aria-expanded")) === "true", "the split toggle opens its menu")
  await page.mouse.move(0, 0)
  const openFill = await toggle.evaluate((el) => getComputedStyle(el).backgroundColor)
  verify(openFill !== restFill, "the open split toggle keeps its pressed fill")
  await page.keyboard.press("Escape")

  const variants = await preview("Export").evaluate((stage) =>
    [...stage.querySelectorAll("[data-slot=split-button]")].map((group) => {
      const [action, toggle] = group.querySelectorAll("button")
      const a = action.getBoundingClientRect()
      const t = toggle.getBoundingClientRect()
      return (
        Math.abs(a.height - t.height) < 0.5 &&
        Math.abs(t.left - a.right) < 0.5 &&
        Math.abs(t.width - t.height) < 0.5
      )
    }),
  )
  verify(
    variants.length === 3 && variants.every(Boolean),
    "split buttons join for secondary, outline and ghost at every size",
  )

  const swap = await preview("New entry").evaluate((stage) => {
    const [closed, open] = stage.querySelectorAll("button")
    const shown = (button, slot) =>
      getComputedStyle(button.querySelector(`[data-slot=${slot}]`)).display !== "none" &&
      button.querySelector(`[data-slot=${slot}]`).getBoundingClientRect().width > 1
    return {
      closedLabel: shown(closed, "button-label"),
      closedIcon: shown(closed, "button-expanded-icon"),
      openLabel: shown(open, "button-label"),
      openIcon: shown(open, "button-expanded-icon"),
      openName: open.textContent.trim(),
    }
  })
  verify(
    swap.closedLabel &&
      !swap.closedIcon &&
      !swap.openLabel &&
      swap.openIcon &&
      swap.openName === "New entry",
    `an expanded button swaps its label for the icon and keeps its name: ${JSON.stringify(swap)}`,
  )

  return checks
}
