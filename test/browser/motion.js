async function _verifyMotion(page) {
  await page.bringToFront()
  await page.setViewportSize({ width: 1440, height: 900 })
  page.setDefaultTimeout(10000)
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  await page.goto(`${origin}/components/copy_button.html`)
  await page.waitForFunction(async () => {
    const { application } = await import("controllers/application")
    const element = document.querySelector('#example-0 [data-controller="ui-copy"]')
    return element && application.getControllerForElementAndIdentifier(element, "ui-copy")
  })
  await page.evaluate(() => {
    window.copyTest = { calls: [], mode: "success" }
    window.copyClipboardDescriptor = Object.getOwnPropertyDescriptor(navigator, "clipboard")
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: {
        async writeText(text) {
          window.copyTest.calls.push(text)
          if (window.copyTest.mode === "error") throw new DOMException("Denied", "NotAllowedError")
          if (window.copyTest.mode === "pending") {
            await new Promise((resolve) => {
              window.copyTest.resolve = resolve
            })
          }
        },
      },
    })
  })

  try {
    const root = page.locator('#example-0 [data-controller="ui-copy"]').first()
    const button = root.getByRole("button")
    const state = async (selector, value) => {
      await page.waitForFunction(
        ({ selector, value }) => document.querySelector(selector)?.dataset.state === value,
        { selector, value },
      )
    }
    const selector = '#example-0 [data-controller="ui-copy"]'
    const before = await button.boundingBox()
    await page.evaluate(() => {
      window.copyTest.mode = "pending"
    })
    await button.focus()
    await page.keyboard.press("Enter")
    verify((await root.getAttribute("data-state")) === "idle", "Copy waits for clipboard success")
    verify((await button.getAttribute("aria-busy")) === "true", "Pending copy exposes busy state")
    await button.click()
    verify(
      (await page.evaluate(() => window.copyTest.calls.length)) === 1,
      "Repeated presses do not duplicate a pending clipboard write",
    )
    await page.evaluate(() => window.copyTest.resolve())
    await state(selector, "copied")
    verify(
      (await page.evaluate(() => window.copyTest.calls[0])) === "https://ui.lostcoords.com",
      "The clipboard receives the supplied text",
    )
    verify((await root.getByRole("status").textContent()) === "Copied", "Copy success is announced")
    verify(
      await button.evaluate((node) => document.activeElement === node),
      "Copy feedback preserves keyboard focus",
    )
    const after = await button.boundingBox()
    verify(
      Math.abs(before.width - after.width) < 1,
      "Copy confirmation keeps the button width stable",
    )
    verify(
      await root.locator('[data-copy-state="copied"]').evaluate((node) => {
        const style = getComputedStyle(node)
        return style.visibility === "visible" && style.transitionProperty.includes("opacity")
      }),
      "The check and label share an animated confirmation state",
    )
    await state(selector, "idle")
    verify(
      (await root.getByRole("status").textContent()) === "",
      "Confirmation resets automatically",
    )

    await page.evaluate(() => {
      window.copyTest.mode = "error"
    })
    await button.click()
    await state(selector, "error")
    verify(
      (await root.getByRole("status").textContent()).includes("Could not copy"),
      "Clipboard denial announces failure and manual copying",
    )
    verify(
      Math.abs(before.width - (await button.boundingBox()).width) < 1,
      "The retry label keeps the button width stable",
    )
    await page.evaluate(() => {
      window.copyTest.mode = "success"
    })
    await button.click()
    await state(selector, "copied")
    checks.push("A failed copy can be retried immediately")

    const source = page.locator("#example-1 [data-example-preview]")
    await source.getByRole("textbox").fill("https://example.com/edited?x=1&y=2")
    await source.getByRole("button").click()
    verify(
      (await page.evaluate(() => window.copyTest.calls.at(-1))) ===
        "https://example.com/edited?x=1&y=2",
      "Source copying reads an edited field's current value",
    )
    const iconRoot = page.locator('#example-0 [data-controller="ui-copy"]').nth(2)
    await iconRoot.getByRole("button", { name: "Copy link", exact: true }).click()
    verify(
      (await iconRoot.getByRole("status").textContent()) === "Copied",
      "Icon-only controls provide named actions and announced confirmation",
    )
    verify(
      await page
        .locator('#example-0 [data-controller="ui-copy"]')
        .nth(3)
        .getByRole("button")
        .isDisabled(),
      "Disabled copy controls remain native disabled buttons",
    )

    const docs = page.locator("#usage [data-controller='example']")
    await docs.getByRole("button", { name: /Copy .* usage/ }).click()
    verify(
      (await page.evaluate(() => window.copyTest.calls.at(-1))) ===
        (await docs.locator("pre code").textContent()),
      "Documentation uses the library copy button and copies the exact source",
    )
    await page.evaluate(() => {
      window.copyTest.mode = "error"
    })
    await docs.getByRole("button", { name: /Copy .* usage/ }).click()
    verify(
      (await docs.getAttribute("data-expanded")) !== null,
      "Documentation copying failures enable manual source selection",
    )
  } finally {
    await page.evaluate(() => {
      if (window.copyClipboardDescriptor) {
        Object.defineProperty(navigator, "clipboard", window.copyClipboardDescriptor)
      } else {
        delete navigator.clipboard
      }
      delete window.copyTest
      delete window.copyClipboardDescriptor
    })
  }

  await page.goto(`${origin}/components/motion.html`)
  const movingButton = page.locator("#example-0 [data-example-preview] button").first()
  await movingButton.hover()
  verify(
    await movingButton.evaluate((node) => {
      const style = getComputedStyle(node)
      return style.transitionProperty.includes("translate") && style.transitionDuration === "0.18s"
    }),
    "Button movement uses the shared control timing and transitions translate",
  )
  await movingButton.evaluate((node) => {
    node.parentElement.style.setProperty("--ui-motion-control", "75ms")
  })
  verify(
    (await movingButton.evaluate((node) => getComputedStyle(node).transitionDuration)) === "0.075s",
    "Motion timing can be overridden on a container",
  )
  await movingButton.evaluate((node) => {
    node.parentElement.style.removeProperty("--ui-motion-control")
  })
  await page.emulateMedia({ reducedMotion: "reduce" })
  try {
    const button = page.locator("#example-0 [data-example-preview] button").first()
    await button.hover()
    verify(
      await button.evaluate((node) => {
        const style = getComputedStyle(node)
        return style.translate === "none" && parseFloat(style.transitionDuration) < 0.001
      }),
      "Reduced motion removes button lift and shortens transitions",
    )
    const icon = page.getByRole("button", { name: "Add item", exact: true })
    await icon.hover()
    await page.mouse.down()
    try {
      verify(
        await icon.evaluate((node) => getComputedStyle(node).scale === "none"),
        "Reduced motion removes press scaling",
      )
    } finally {
      await page.mouse.up()
    }
    verify(
      await page
        .locator("#example-1 [data-copy-state='copied']")
        .first()
        .evaluate((node) => {
          const style = getComputedStyle(node)
          return style.transform === "none" && parseFloat(style.transitionDuration) < 0.001
        }),
      "Reduced motion removes label and icon movement",
    )
  } finally {
    await page.emulateMedia({ reducedMotion: "no-preference" })
  }

  for (const width of [390, 1440]) {
    await page.setViewportSize({ width, height: 900 })
    verify(
      await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth),
      `Motion examples fit at ${width}px`,
    )
  }
  return checks
}
