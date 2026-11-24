// engines: chromium webkit
// Every overlay animates out, in WebKit too, which can't transition `overlay`
// or `display`: a closed dialog, sheet, menu or tooltip used to vanish there in
// the frame it closed. Frames are sampled in the page, so a slow runner can't
// skip the one that matters.
async function _verifyExits(page) {
  page.setDefaultTimeout(10000)
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  // A failed exit check names the frames it saw, since CI's frame pacing differs from a laptop's.
  let sampled = null
  const verify = (condition, message) => {
    if (!condition) {
      const frames = sampled?.map(
        (f) => `${Math.round(f.t)}ms:${f.shown ? f.opacity.toFixed(2) : "-"}`,
      )
      throw new Error(frames ? `${message} (frames ${frames.join(" ")})` : message)
    }
    checks.push(message)
    sampled = null
  }
  const pause = (ms) => page.evaluate((ms) => new Promise((resolve) => setTimeout(resolve, ms)), ms)
  const ready = () => page.waitForFunction(() => window.Stimulus, null, { polling: 100 })

  // Starts sampling an element in the page, runs `action` from here, then returns each frame of
  // the next `ms`: whether it was still painted, its opacity and its top edge.
  const sampleExit = async (selector, action, ms = 400) => {
    const frames = page.evaluate(
      async ({ selector, ms }) => {
        const element = document.querySelector(selector)
        const frames = []
        const start = performance.now()
        while (performance.now() - start < ms) {
          await new Promise(requestAnimationFrame)
          const style = getComputedStyle(element)
          const rect = element.getBoundingClientRect()
          frames.push({
            t: performance.now() - start,
            shown:
              style.display !== "none" &&
              style.visibility !== "hidden" &&
              rect.height > 0 &&
              rect.top < innerHeight,
            opacity: Number(style.opacity),
            top: rect.top,
          })
        }
        return frames
      },
      { selector, ms },
    )
    await action()
    return frames
  }
  // Mid-exit: painted, and partway between the open and closed poses.
  const midway = (frames, moved) => {
    sampled = frames
    return frames.some((frame) => frame.t > 0 && frame.t < 400 && frame.shown && moved(frame))
  }

  try {
    // A phone sheet released halfway down slides on from there.
    await page.setViewportSize({ width: 390, height: 844 })
    await page.goto(`${origin}/components/dialog.html`)
    await ready()
    const sheet = "#example-2-sheet"
    // Each scenario opens the sheet afresh, so one failure can't leave the next without a sheet.
    const openSheet = async () => {
      await page.evaluate((s) => {
        const element = document.querySelector(s)
        if (!element.open) element.showModal()
      }, sheet)
      await pause(700)
      return page.locator(sheet).boundingBox()
    }
    const drag = async (fraction, holdMs) => {
      const box = await openSheet()
      const x = box.x + box.width / 2
      await page.mouse.move(x, box.y + 10)
      await page.mouse.down()
      for (let i = 1; i <= 12; i++) {
        await page.mouse.move(x, box.y + 10 + (box.height * fraction * i) / 12)
        await pause(16)
      }
      await pause(holdMs)
    }

    await drag(0.25, 200)
    await page.mouse.up()
    await pause(700)
    const settled = await page.evaluate((s) => {
      const element = document.querySelector(s)
      return { open: element.open, transform: getComputedStyle(element).transform }
    }, sheet)
    verify(
      settled.open && settled.transform === "none",
      "a sheet dragged a quarter down and held before lifting settles back",
    )

    await drag(0.5, 200)
    const releasedAt = (await page.locator(sheet).boundingBox()).y
    const releaseFrames = await sampleExit(sheet, () => page.mouse.up())
    verify(
      midway(releaseFrames, (frame) => frame.top > releasedAt + 4),
      "a sheet released halfway down slides on from there instead of vanishing",
    )
    await pause(700)
    verify(
      !(await page.evaluate((s) => document.querySelector(s).open, sheet)),
      "the released sheet then closes",
    )

    // close(), as a ✕ or Escape calls it, slides the sheet down.
    const restingTop = (await openSheet()).y
    const closeFrames = await sampleExit(sheet, () =>
      page.evaluate((s) => document.querySelector(s).close(), sheet),
    )
    verify(
      midway(closeFrames, (frame) => frame.top > restingTop + 4),
      "a phone sheet slides down when closed",
    )
    await pause(600)

    // The confirm sheet answers as its exit starts, not after it.
    const confirm = await page.evaluate(async () => {
      const { ask } = await import("lostcoords/ui/helpers/confirm")
      const dialog = document.getElementById("lc-confirm-sheet")
      const answer = ask("Delete?")
      await new Promise((resolve) => setTimeout(resolve, 600))
      const accept = [...dialog.querySelectorAll("[data-slot=confirm-sheet-accept]")].find(
        (button) => !button.hidden,
      )
      const start = performance.now()
      accept.click()
      const confirmed = await answer
      return { confirmed, ms: performance.now() - start }
    })
    verify(confirm.confirmed, "the confirm sheet's accept button answers yes")
    verify(confirm.ms < 100, "the confirm sheet answers as its exit starts")
    await pause(700)

    // Desktop: the dialog, a menu and a tooltip fade out.
    await page.setViewportSize({ width: 1280, height: 844 })
    await page.goto(`${origin}/components/dialog.html`)
    await ready()
    await page.evaluate((s) => document.querySelector(s).showModal(), sheet)
    await pause(500)
    const dialogFrames = await sampleExit(sheet, () =>
      page.evaluate((s) => document.querySelector(s).close(), sheet),
    )
    verify(
      midway(dialogFrames, (frame) => frame.opacity > 0.02 && frame.opacity < 0.98),
      "a desktop dialog fades out when closed",
    )

    await page.goto(`${origin}/components/menu.html`)
    await ready()
    await page.locator('[data-controller~="lc-menu"] button').first().click()
    await pause(400)
    const menuFrames = await sampleExit('[data-controller~="lc-menu"] [data-open]', () =>
      page.keyboard.press("Escape"),
    )
    verify(
      midway(menuFrames, (frame) => frame.opacity > 0.02 && frame.opacity < 0.98),
      "a menu fades out when it closes",
    )

    await page.goto(`${origin}/components/tooltip.html`)
    await ready()
    await page.locator('[data-controller~="lc-tooltip"]').first().hover()
    await pause(700)
    const tooltipFrames = await sampleExit(
      '[data-controller~="lc-tooltip"] .lc-tooltip__content',
      () => page.mouse.move(2, 2),
    )
    verify(
      midway(tooltipFrames, (frame) => frame.opacity > 0.02 && frame.opacity < 0.98),
      "a tooltip fades out when the pointer leaves",
    )
  } finally {
    await page.setViewportSize({ width: 1440, height: 900 })
  }

  return checks
}
