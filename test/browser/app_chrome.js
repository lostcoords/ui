async function _verifyAppChrome(page) {
  const origin = await page.evaluate(() => location.origin)
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }
  const ready = (identifier) =>
    page.waitForFunction(
      (name) => window.Stimulus?.controllers.some(({ identifier }) => identifier === name),
      identifier,
    )

  await page.setViewportSize({ width: 1440, height: 900 })
  await page.goto(`${origin}/components/sidebar.html`)
  await ready("lc-sidebar")
  const sidebar = "#example-0 [data-slot=sidebar]"
  const toggle = `${sidebar} [data-slot=sidebar-toggle]`
  const state = () =>
    page.$eval(sidebar, (aside) => {
      const button = aside.querySelector("[data-slot=sidebar-toggle]")
      const label = aside.querySelector("[data-slot=nav-link] > span").getBoundingClientRect()
      return {
        width: aside.getBoundingClientRect().width,
        collapsed: aside.hasAttribute("data-collapsed"),
        expanded: button.getAttribute("aria-expanded"),
        label: button.getAttribute("aria-label"),
        title: button.getAttribute("title"),
        labelWidth: label.width,
        account: getComputedStyle(aside.querySelector("[data-slot=sidebar-account-text]")).position,
      }
    })

  let current = await state()
  verify(
    current.width > 200 && current.labelWidth > 1,
    "The sidebar starts expanded with visible labels",
  )

  await page.click(toggle)
  current = await state()
  verify(current.collapsed && current.width < 80, "The toggle folds the sidebar to a rail")
  verify(
    current.labelWidth <= 1 && current.account === "absolute",
    "On the rail, link labels and the account name stay for screen readers only",
  )
  verify(
    current.expanded === "false" &&
      current.label === "Expand sidebar" &&
      current.title === "Expand sidebar",
    "The toggle's label, title and aria-expanded follow the rail",
  )
  const cookie = await page.evaluate(() => document.cookie)
  verify(cookie.includes("docs_sidebar=collapsed"), "The choice is kept in the named cookie")

  const centered = await page.$eval(
    `${sidebar} [aria-current=page]`,
    (link) => getComputedStyle(link).justifyContent,
  )
  verify(centered === "center", "On the rail, links center their icons")

  const bar = await page.$eval(`${sidebar} [aria-current=page]`, (link) => {
    const mark = getComputedStyle(link, "::before")
    return mark.content !== "none" && mark.position === "absolute"
  })
  verify(bar, "The current link carries an indicator bar")

  await page.click(toggle)
  current = await state()
  verify(
    !current.collapsed && current.width > 200 && current.label === "Collapse sidebar",
    "The toggle expands the sidebar again",
  )
  verify(
    (await page.evaluate(() => document.cookie)).includes("docs_sidebar=expanded"),
    "Expanding is remembered too",
  )

  await page.click(`${sidebar} [data-slot=sidebar-account-trigger]`)
  await page.waitForSelector(`${sidebar} [role=menu][data-open]`, { state: "attached" })
  verify(
    (await page.getAttribute(`${sidebar} [data-slot=sidebar-account-trigger]`, "aria-expanded")) ===
      "true",
    "The account row opens its menu",
  )
  await page.keyboard.press("Escape")

  await page.setViewportSize({ width: 1100, height: 900 })
  await page.goto(`${origin}/components/sidebar.html`)
  await ready("lc-sidebar")
  await page.evaluate(() => {
    const aside = document.querySelector("#example-0 [data-slot=sidebar]")
    aside.removeAttribute("data-expanded")
    aside.removeAttribute("data-collapsed")
    aside.dataset.railBelow = "xl"
  })
  verify(
    (await page.$eval(sidebar, (aside) => aside.getBoundingClientRect().width)) < 80,
    "Below its breakpoint the sidebar is a rail unless expanded",
  )

  await page.setViewportSize({ width: 1440, height: 900 })
  await page.goto(`${origin}/components/char_counter.html`)
  await ready("lc-char-counter")
  const field = "#example-0 textarea"
  const counter = "#example-0 [data-slot=char-counter]"
  const ring = () =>
    page.$eval(counter, (element) => ({
      hidden: element.hidden,
      state: element.dataset.state,
      remaining: element.querySelector("[data-slot=char-counter-remaining]").textContent,
      label: element.getAttribute("aria-label"),
    }))

  await page.fill(field, "")
  verify((await ring()).hidden, "An empty field hides the counter")

  await page.fill(field, "a".repeat(50))
  let shown = await ring()
  verify(
    !shown.hidden && shown.state === "ok" && shown.remaining === "",
    "Typing shows the ring without a number",
  )
  verify(shown.label === "50 of 100 characters", "The ring names the count and the limit")

  await page.fill(field, "a".repeat(85))
  shown = await ring()
  verify(
    shown.state === "near" && shown.remaining === "15",
    "Near the limit the ring warns with the characters left",
  )

  await page.fill(field, "a".repeat(104))
  shown = await ring()
  verify(
    shown.state === "over" && shown.remaining === "-4",
    "Past the limit the ring shows a negative number",
  )
  const color = await page.$eval(counter, (element) => getComputedStyle(element).color)
  const destructive = await page.evaluate(() => {
    const probe = document.createElement("span")
    probe.className = "text-destructive"
    document.body.append(probe)
    const value = getComputedStyle(probe).color
    probe.remove()
    return value
  })
  verify(color === destructive, "Past the limit the ring takes the destructive tone")

  await page.$eval(counter, (element) => {
    element.addEventListener("composer:count", (event) =>
      window.Stimulus.getControllerForElementAndIdentifier(element, "lc-char-counter").update(
        event,
      ),
    )
    element.dispatchEvent(new CustomEvent("composer:count", { detail: { count: 12 } }))
  })
  shown = await ring()
  verify(
    shown.label === "12 of 100 characters" && shown.state === "ok",
    "A supplied count replaces the field's",
  )

  return checks
}
