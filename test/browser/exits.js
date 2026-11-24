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

  // Closes an overlay in the page and reads it in the same task: it must still be on screen, with
  // its exit transition running. A sampled frame can't prove this on a slow renderer, where a
  // blurred backdrop can stall the first frame past the end of a 200ms fade.
  const exitsInPlace = (selector, close) =>
    page.evaluate(
      ({ selector, close }) => {
        const element = document.querySelector(selector)
        if (close === "dialog") element.close()
        else if (close.startsWith("click ")) document.querySelector(close.slice(6)).click()
        else if (close === "outside")
          document.body.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true }))
        else if (close === "escape")
          document.body.dispatchEvent(
            new KeyboardEvent("keydown", { key: "Escape", bubbles: true }),
          )
        else {
          const host = element.closest(`[data-controller~="${close}"]`)
          window.Stimulus.getControllerForElementAndIdentifier(host, close).close()
        }
        const style = getComputedStyle(element)
        return {
          shown: style.display !== "none" && style.visibility !== "hidden",
          exiting: element
            .getAnimations()
            .some((animation) => ["opacity", "transform"].includes(animation.transitionProperty)),
        }
      },
      { selector, close },
    )

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
    await openSheet()
    const sheetExit = await exitsInPlace(sheet, "dialog")
    verify(sheetExit.shown && sheetExit.exiting, "a phone sheet slides down when closed")
    await pause(700)

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
    const dialogExit = await exitsInPlace(sheet, "dialog")
    verify(dialogExit.shown && dialogExit.exiting, "a desktop dialog fades out when closed")

    await page.goto(`${origin}/components/menu.html`)
    await ready()
    await page.locator('[data-controller~="lc-menu"] button').first().click()
    await pause(400)
    const menuExit = await exitsInPlace('[data-controller~="lc-menu"] [data-open]', "lc-menu")
    verify(menuExit.shown && menuExit.exiting, "a menu fades out when it closes")

    await page.goto(`${origin}/components/tooltip.html`)
    await ready()
    await pause(700)
    await page.mouse.move(2, 2)
    await page.evaluate(() => {
      const host = document.querySelector('[data-controller~="lc-tooltip"]')
      window.Stimulus.getControllerForElementAndIdentifier(host, "lc-tooltip").show({
        type: "mouseenter",
        target: host,
      })
    })
    await pause(700)
    const tooltipExit = await exitsInPlace(
      '[data-controller~="lc-tooltip"] .lc-tooltip__content',
      "lc-tooltip",
    )
    verify(tooltipExit.shown && tooltipExit.exiting, "a tooltip fades out when it closes")

    // A popover the gem rendered as auto: its closes are lc-light-dismiss's, so each plays the exit.
    const filters = '[popover][id$="-filters"]'
    const openFilters = async () => {
      await page.evaluate((s) => document.querySelector(s).showPopover(), filters)
      await pause(600)
    }
    const hidden = () =>
      page.evaluate((s) => !document.querySelector(s).matches(":popover-open"), filters)
    for (const width of [1280, 390]) {
      await page.setViewportSize({ width, height: 844 })
      await page.goto(`${origin}/components/dialog.html`)
      await ready()
      const where = width < 640 ? "phone sheet" : "desktop popover"
      verify(
        await page.evaluate((s) => document.querySelector(s).popover === "manual", filters),
        `a ${where} rendered as auto is manual once its controller connects`,
      )
      for (const [close, how] of [
        [`click ${filters} [popovertargetaction=hide]`, "its Done button"],
        ["outside", "a tap outside"],
        ["escape", "Escape"],
      ]) {
        await openFilters()
        const exit = await exitsInPlace(filters, close)
        await pause(700)
        // From sm up the popover sheet keeps the caller's frame, which doesn't animate.
        const exited = width < 640 ? exit.shown && exit.exiting : true
        verify(
          exited && (await hidden()),
          `a ${where} closes, with its exit, when ${how} closes it`,
        )
      }
    }

    // A native popover in the shared popover shell, as a host's menu is, fades out.
    await page.setViewportSize({ width: 1280, height: 844 })
    await page.evaluate(() => {
      const panel = document.createElement("div")
      panel.id = "exits-shell"
      panel.popover = "auto"
      panel.className = "lc-popover-shell p-inset bg-popover"
      panel.dataset.controller = "lc-light-dismiss"
      panel.innerHTML = '<a href="#exits" data-lc-popover-close>Section</a>'
      document.body.append(panel)
    })
    await pause(300)
    for (const [close, how] of [
      ["click #exits-shell [data-lc-popover-close]", "a link marked data-lc-popover-close"],
      ["outside", "a tap outside"],
      ["escape", "Escape"],
    ]) {
      await page.evaluate(() => document.getElementById("exits-shell").showPopover())
      await pause(400)
      const exit = await exitsInPlace("#exits-shell", close)
      await pause(500)
      const gone = await page.evaluate(
        () => !document.getElementById("exits-shell").matches(":popover-open"),
      )
      verify(exit.shown && exit.exiting && gone, `a shell popover fades out when ${how} closes it`)
    }

    // closeDialog settles once the dialog has left, not when close() returns.
    await page.setViewportSize({ width: 390, height: 844 })
    await page.goto(`${origin}/components/dialog.html`)
    await ready()
    await openSheet()
    const left = await page.evaluate(async (s) => {
      const { closeDialog } = await import("lostcoords/ui/helpers/dialog")
      const dialog = document.querySelector(s)
      await closeDialog(dialog)
      return { open: dialog.open, running: dialog.getAnimations().length }
    }, sheet)
    verify(
      !left.open && left.running === 0,
      "closeDialog settles once the dialog is closed and its exit is over",
    )
  } finally {
    await page.setViewportSize({ width: 1440, height: 900 })
  }

  return checks
}
