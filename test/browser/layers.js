async function _verifyLayers(page) {
  await page.bringToFront()
  await page.setViewportSize({ width: 1440, height: 900 })
  page.setDefaultTimeout(10000)
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const ready = (identifier) =>
    page.waitForFunction(
      async (identifier) => {
        const { application } = await import("controllers/application")
        const element = document.querySelector(`[data-controller~="${identifier}"]`)
        return element && application.getControllerForElementAndIdentifier(element, identifier)
      },
      identifier,
      { polling: 100 },
    )

  // The sticky header stays above content scrolled under it.
  await page.goto(`${origin}/components/button.html`)
  const covered = await page.evaluate(async () => {
    const header = document.querySelector("header.sticky")
    const code = document.querySelector("pre")
    window.scrollTo(0, code.getBoundingClientRect().top + window.scrollY - 40)
    await new Promise((resolve) => setTimeout(resolve, 100))
    const box = header.getBoundingClientRect()
    const codeBox = code.getBoundingClientRect()
    const x = codeBox.left + 40
    const y = box.top + box.height / 2
    return {
      overlaps: codeBox.top < y && codeBox.bottom > y,
      onTop: header.contains(document.elementFromPoint(x, y)),
      zIndex: getComputedStyle(header).zIndex,
      isolated: getComputedStyle(document.querySelector("main")).isolation,
    }
  })
  verify(covered.overlaps, "a code block scrolls under the sticky header")
  verify(covered.onTop, "the sticky header paints above the code block")
  verify(covered.zIndex === "20", "z-sticky resolves to the sticky layer")
  verify(covered.isolated === "isolate", "the docs main content is isolated")

  // Tooltips open in the top layer, above their trigger.
  await page.goto(`${origin}/components/tooltip.html`)
  await ready("lc-tooltip")
  const trigger = page.locator('#example-0 [data-slot="tooltip"] [aria-describedby]').first()
  await trigger.hover({ force: true })
  await page.waitForFunction(
    () => {
      const tip = document.querySelector('#example-0 [role="tooltip"]')
      return tip?.matches(":popover-open") && getComputedStyle(tip).opacity === "1"
    },
    null,
    { polling: 100 },
  )
  const tooltip = await page.evaluate(() => {
    const tip = document.querySelector('#example-0 [role="tooltip"]')
    const wrapper = tip.closest('[data-slot="tooltip"]')
    const tipBox = tip.getBoundingClientRect()
    const box = wrapper.getBoundingClientRect()
    const side = wrapper.dataset.side
    return {
      placed: side === "bottom" ? tipBox.top >= box.bottom : tipBox.bottom <= box.top,
      centered: Math.abs(tipBox.left + tipBox.width / 2 - (box.left + box.width / 2)) < 2,
      fixed: getComputedStyle(tip).position === "fixed",
      unbordered: getComputedStyle(tip).borderTopWidth === "0px",
    }
  })
  verify(tooltip.placed, "the tooltip sits beside its trigger")
  verify(tooltip.centered, "the tooltip stays centred on its trigger")
  verify(tooltip.fixed, "the open tooltip is pinned in the top layer")
  verify(tooltip.unbordered, "the tooltip drops the popover border")
  await page.keyboard.press("Escape")
  verify(
    await page.evaluate(
      () => !document.querySelector('#example-0 [role="tooltip"]').matches(":popover-open"),
    ),
    "Escape closes the tooltip",
  )
  await page.mouse.move(0, 0)
  await trigger.hover({ force: true })
  await page.waitForFunction(
    () => document.querySelector('#example-0 [role="tooltip"]')?.matches(":popover-open"),
    null,
    {
      polling: 100,
    },
  )
  verify(true, "the tooltip opens again after the pointer leaves")
  await page.mouse.move(0, 0)
  await page.waitForFunction(
    () => !document.querySelector('#example-0 [role="tooltip"]')?.hasAttribute("popover"),
    null,
    {
      polling: 100,
    },
  )
  verify(true, "the closed tooltip returns to its place")

  // Toasts open in the top layer, above a modal dialog opened before them. The modal makes the page
  // outside it inert, which hides the toast from hit testing, so the check reads the painted pixel.
  await page.goto(`${origin}/components/toast.html`)
  await ready("toast-demo")
  const toast = await page.evaluate(async () => {
    const region = document.querySelector('[data-slot="toast-region"]')
    const closedBefore = !region.matches(":popover-open")
    const dialog = document.createElement("dialog")
    dialog.id = "layers-cover"
    dialog.style.cssText =
      "inset: 0; margin: 0; width: 100vw; height: 100vh; max-width: none; max-height: none; background: rgb(0 0 255)"
    document.body.append(dialog)
    dialog.showModal()
    const { application } = await import("controllers/application")
    const button = region.parentElement.querySelector('[data-controller="toast-demo"]')
    application.getControllerForElementAndIdentifier(button, "toast-demo").show()
    await new Promise((resolve) => setTimeout(resolve, 400))
    const box = region.querySelector('[data-slot="toast"]').getBoundingClientRect()
    return {
      closedBefore,
      insideModal: dialog.contains(region),
      open: region.matches(":popover-open"),
      corner: box.right > window.innerWidth - 80 && box.bottom > window.innerHeight - 120,
      point: { x: Math.round(box.left + 12), y: Math.round(box.top + box.height / 2) },
    }
  })
  const pixel = await page.screenshot({ clip: { ...toast.point, width: 1, height: 1 } })
  const painted = await page.evaluate(async (data) => {
    const image = new Image()
    image.src = `data:image/png;base64,${data}`
    await image.decode()
    const canvas = document.createElement("canvas")
    canvas.width = canvas.height = 1
    const context = canvas.getContext("2d")
    context.drawImage(image, 0, 0)
    const [red, green, blue] = context.getImageData(0, 0, 1, 1).data
    // Closing and removing the modal in one task, as a Turbo render does, must not take the region.
    const dialog = document.getElementById("layers-cover")
    dialog.close()
    dialog.remove()
    await new Promise((resolve) => setTimeout(resolve, 100))
    const region = document.querySelector('[data-slot="toast-region"]')
    const returned = Boolean(region) && !region.closest("dialog") && region.childElementCount === 1
    region?.querySelector('[data-slot="toast"]')?.remove()
    await new Promise((resolve) => setTimeout(resolve, 50))
    return {
      coveredByDialog: blue > 200 && red < 80 && green < 80,
      returned,
      closedAfter: Boolean(region) && !region.matches(":popover-open"),
    }
  }, pixel.toString("base64"))
  verify(toast.closedBefore, "an empty toast region stays closed")
  verify(toast.open, "a toast opens the region in the top layer")
  verify(toast.insideModal, "the region moves inside an open modal, so its toasts stay interactive")
  verify(!painted.coveredByDialog, "the toast paints above a modal dialog")
  verify(painted.returned, "the region returns to the page with its toasts when the modal goes")
  verify(toast.corner, "the toast region sits in the bottom corner")
  verify(painted.closedAfter, "the region closes when its last toast leaves")

  return checks
}
