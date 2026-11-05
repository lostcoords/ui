async function _verifyKeyboard(page) {
  await page.bringToFront()
  await page.setViewportSize({ width: 1440, height: 900 })
  page.setDefaultTimeout(10000)
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const visit = async (path) => {
    await page.goto(`${origin}${path}`)
    await page.waitForFunction(async () => {
      const { application } = await import("controllers/application")
      return [...document.querySelectorAll("[data-controller]")].every((element) =>
        element.dataset.controller
          .split(/\s+/)
          .every((name) => application.getControllerForElementAndIdentifier(element, name)),
      )
    })
  }
  const focused = () =>
    page.evaluate(() => {
      const element = document.activeElement
      return element?.getAttribute("aria-label") || element?.textContent.trim() || ""
    })

  // Menu: the ARIA menu button pattern.
  await visit("/components/menu.html")
  const trigger = page.getByRole("button", { name: "Project actions", exact: true })
  await trigger.focus()
  await page.keyboard.press("ArrowDown")
  verify(
    (await trigger.getAttribute("aria-expanded")) === "true" &&
      (await focused()) === "Edit project",
    "Arrow Down on a menu button opens it on the first item",
  )
  await page.keyboard.press("ArrowUp")
  verify(
    (await focused()) === "Archive project",
    "Menu arrows wrap from the first item to the last",
  )
  await page.keyboard.press("Home")
  await page.keyboard.press("d")
  verify(
    (await focused()) === "Duplicate project",
    "Typing a letter jumps to the matching menu item",
  )
  await page.keyboard.press("Escape")
  verify(
    (await trigger.getAttribute("aria-expanded")) === "false" &&
      (await trigger.evaluate((node) => node === document.activeElement)),
    "Escape closes the menu and returns focus to its button",
  )
  await page.keyboard.press("ArrowUp")
  verify(
    (await focused()) === "Archive project",
    "Arrow Up on a menu button opens it on the last item",
  )
  await page.keyboard.press("Home")
  await page.keyboard.press(" ")
  await page.waitForURL(`${origin}/components/input.html`)
  verify(true, "Space activates a link menu item")

  // Tabs: automatic activation along a horizontal list, manual along a vertical one.
  await visit("/components/tabs.html")
  const horizontal = page.locator("#example-0 [role=tab]")
  await horizontal.first().focus()
  await page.keyboard.press("ArrowRight")
  verify(
    (await horizontal.nth(1).getAttribute("aria-selected")) === "true",
    "Arrow Right selects the next horizontal tab",
  )
  await page.keyboard.press("End")
  await page.keyboard.press("ArrowRight")
  verify(
    (await horizontal.first().getAttribute("aria-selected")) === "true",
    "End and Arrow Right wrap to the first tab",
  )
  const vertical = page.locator("#example-1 [role=tab]")
  await vertical.first().focus()
  await page.keyboard.press("ArrowRight")
  verify(
    await vertical.first().evaluate((node) => node === document.activeElement),
    "Vertical tabs ignore Left and Right",
  )
  await page.keyboard.press("ArrowDown")
  verify(
    (await vertical.nth(1).evaluate((node) => node === document.activeElement)) &&
      (await vertical.first().getAttribute("aria-selected")) === "true" &&
      (await vertical.nth(1).getAttribute("tabindex")) === "0",
    "Manual tabs move focus with Arrow Down without selecting",
  )
  await page.keyboard.press("Enter")
  verify(
    (await vertical.nth(1).getAttribute("aria-selected")) === "true" &&
      (await page.locator("#example-1 [role=tabpanel]:visible").textContent()).includes(
        "Email me about mentions",
      ),
    "Enter selects the focused manual tab and shows its panel",
  )

  // Toggle group: one Tab stop, arrows wrap.
  await visit("/components/toggle_group.html")
  const options = page.locator('#example-0 [data-lc-selection-target="option"]')
  await options.first().focus()
  await page.keyboard.press("ArrowLeft")
  verify(
    (await options.last().getAttribute("aria-pressed")) === "true" &&
      (await options.evaluateAll((nodes) => nodes.filter((node) => node.tabIndex === 0).length)) ===
        1,
    "Toggle group arrows wrap and keep one Tab stop",
  )

  // Emoji picker: a grid of options below the search field.
  await visit("/components/emoji.html")
  await page.getByRole("button", { name: "Choose an emoji", exact: true }).focus()
  await page.keyboard.press("Enter")
  const search = page.getByRole("searchbox")
  await search.waitFor()
  await page.waitForFunction(() => document.querySelector("[data-picker-catalog]"))
  verify(
    await search.evaluate((node) => node === document.activeElement),
    "Opening the emoji picker focuses its search",
  )
  await page.keyboard.press("ArrowDown")
  const position = () =>
    page.evaluate(() => {
      const box = document.activeElement.getBoundingClientRect()
      return {
        x: Math.round(box.left),
        y: Math.round(box.top),
        emoji: document.activeElement.dataset.emoji,
      }
    })
  const start = await position()
  verify(Boolean(start.emoji), "Arrow Down moves from the search into the emoji grid")
  await page.keyboard.press("ArrowRight")
  const right = await position()
  verify(
    right.x > start.x && Math.abs(right.y - start.y) <= 1,
    "Arrow Right moves to the next emoji in the row",
  )
  await page.keyboard.press("ArrowDown")
  const below = await position()
  verify(
    below.y > right.y && Math.abs(below.x - right.x) < 4,
    "Arrow Down moves to the emoji below",
  )
  verify(
    (await page.evaluate(
      () =>
        [...document.querySelectorAll(".lc-emoji-picker__body button[data-emoji]")].filter(
          (button) => button.tabIndex === 0,
        ).length,
    )) === 1,
    "The emoji grid is a single Tab stop",
  )
  await page.keyboard.press("ArrowUp")
  await page.keyboard.press("ArrowUp")
  verify(
    await search.evaluate((node) => node === document.activeElement),
    "Arrow Up from the top row returns to the search",
  )
  await page.keyboard.type("pizza")
  await page.keyboard.press("Escape")
  verify(
    (await search.inputValue()) === "" && (await search.isVisible()),
    "Escape clears a search before closing the picker",
  )
  await page.keyboard.type("pizza")
  await page.keyboard.press("Enter")
  verify(
    (await page.locator('input[name="project[emoji]"]').inputValue()) === "🍕",
    "Enter in the search picks the best match",
  )

  await page.getByRole("button", { name: "Choose an emoji", exact: true }).focus()
  await page.keyboard.press("Enter")
  await search.waitFor()
  const tones = page.getByRole("button", { name: "Skin tone", exact: true })
  await tones.focus()
  await page.keyboard.press("Enter")
  verify(
    await page.evaluate(() => document.activeElement?.getAttribute("role") === "menuitemradio"),
    "Opening the tone menu by keyboard focuses a tone",
  )
  await page.keyboard.press("ArrowRight")
  await page.keyboard.press("Escape")
  verify(
    (await tones.getAttribute("aria-expanded")) === "false" &&
      (await tones.evaluate((node) => node === document.activeElement)) &&
      (await search.isVisible()),
    "Escape closes the tone menu before the picker",
  )
  await page.keyboard.press("Escape")
  await search.waitFor({ state: "hidden" })
  verify(true, "The next Escape closes the picker")

  // Shortcuts.
  await visit("/components/kbd.html")
  const filter = page.getByLabel("Filter projects")
  verify((await filter.getAttribute("aria-keyshortcuts")) === "/", "Shortcuts announce their keys")
  verify(
    (await page.locator("#example-0 kbd").allTextContents()).join(",") === "/,Esc",
    "Key hints name their keys",
  )
  await page.locator("body").press("/")
  verify(
    await filter.evaluate((node) => node === document.activeElement),
    "A shortcut focuses its field",
  )
  await page.keyboard.type("a/b")
  verify(
    (await filter.inputValue()) === "a/b",
    "A plain-key shortcut types normally inside a field",
  )
  await page.evaluate(() => {
    document.activeElement.blur()
    const dialog = document.createElement("dialog")
    dialog.id = "shortcut-modal"
    dialog.innerHTML = "<button>Inside</button>"
    document.body.append(dialog)
    dialog.showModal()
  })
  await page.keyboard.press("/")
  verify(
    !(await filter.evaluate((node) => node === document.activeElement)),
    "Shortcuts outside an open modal dialog stay quiet",
  )
  await page.evaluate(() => document.getElementById("shortcut-modal").remove())

  // The component picker's typeahead.
  await visit("/components.html")
  await page.locator(".component-picker__link").first().focus()
  await page.keyboard.press("t")
  const first = await focused()
  await page.keyboard.press("t")
  const second = await focused()
  verify(
    first.includes("Table") && second.includes("Tabs"),
    "Typing a letter repeatedly cycles through the matching components",
  )

  return checks
}
