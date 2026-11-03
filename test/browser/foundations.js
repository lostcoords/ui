async function _verifyFoundations(page) {
  const origin = await page.evaluate(() => location.origin)
  await page.goto(`${origin}/components/foundations.html`)
  await page.locator("#example-0 .ui-heading-page").waitFor()
  const checks = []
  const verify = (condition, message) => {
    if (!condition) throw new Error(message)
    checks.push(message)
  }

  for (const width of [1440, 390, 320]) {
    await page.setViewportSize({ width, height: 1000 })
    for (const theme of ["light", "dark"]) {
      await page.evaluate((value) => {
        document.documentElement.dataset.theme = value
      }, theme)
      const result = await page.evaluate(() => {
        const style = (selector) => getComputedStyle(document.querySelector(selector))
        const preview = document.querySelector("#example-2 [data-example-preview]")
        const stack = preview.firstElementChild
        const section = stack.firstElementChild
        const content = section.lastElementChild
        const roles = [
          ...document.querySelectorAll(
            "#example-0 [data-example-preview] .ui-heading, #example-0 [data-example-preview] .ui-text",
          ),
        ]
        const prose = document.querySelector("#example-4 .ui-prose")
        const paragraphs = [...prose.querySelectorAll(":scope > p")]
        const probe = document.createElement("span")
        probe.style.color = "var(--ink-2)"
        document.body.append(probe)
        const bodyColor = getComputedStyle(probe).color
        probe.remove()
        return {
          overflow: document.documentElement.scrollWidth > innerWidth,
          roles: roles.map((element) => {
            const computed = getComputedStyle(element)
            return [
              computed.fontSize,
              computed.lineHeight,
              computed.marginBlockStart,
              computed.marginBlockEnd,
            ]
          }),
          gaps: [stack, section, content].map((element) => getComputedStyle(element).rowGap),
          headerHeight: section.firstElementChild.getBoundingClientRect().height,
          prose: [getComputedStyle(prose).fontSize, getComputedStyle(prose).lineHeight],
          paragraphGap: getComputedStyle(paragraphs[1]).marginBlockStart,
          proseColor: getComputedStyle(paragraphs[0]).color,
          bodyColor,
          japaneseTracking: style("#example-1 [data-example-preview] .ui-heading").letterSpacing,
          japaneseReadingTracking: style("#example-5 .ui-prose h2").letterSpacing,
          buttonSize: style("#example-4 .not-prose button").fontSize,
        }
      })
      const label = `${width}px ${theme}`
      verify(!result.overflow, `${label}: page fits the viewport`)
      verify(
        JSON.stringify(result.roles) ===
          JSON.stringify([
            ["30px", "36px", "0px", "0px"],
            ["20px", "24px", "0px", "0px"],
            ["18px", "24px", "0px", "0px"],
            ["16px", "24px", "0px", "0px"],
            ["14px", "20px", "0px", "0px"],
            ["12px", "16px", "0px", "0px"],
          ]),
        `${label}: text roles pair size and leading without external margins`,
      )
      verify(result.gaps.join() === "32px,12px,16px", `${label}: section rhythm is 32/12/16px`)
      verify(result.headerHeight >= 44, `${label}: section heading accommodates a control`)
      verify(
        result.prose.join() === "16px,28px" && result.paragraphGap === "20px",
        `${label}: reading rhythm is 16/28px with 20px flow`,
      )
      verify(
        result.proseColor === result.bodyColor,
        `${label}: prose follows the host colour tokens`,
      )
      verify(
        ["normal", "0px"].includes(result.japaneseTracking) &&
          ["normal", "0px"].includes(result.japaneseReadingTracking),
        `${label}: Japanese headings keep natural tracking`,
      )
      verify(result.buttonSize === "16px", `${label}: embedded controls opt out of prose`)
    }
  }

  await page.goto(`${origin}/components/field.html`)
  const fields = await page.evaluate(() => {
    const field = document.querySelector("[data-example-preview] .ui-field")
    const label = field.querySelector("label")
    const fieldset = document.createElement("fieldset")
    fieldset.className = `${field.className} m-0 border-0 p-0`
    const legend = document.createElement("legend")
    legend.className = label.className
    legend.textContent = "Currency"
    const control = field.querySelector("input").cloneNode()
    control.removeAttribute("id")
    fieldset.append(legend, control)
    field.parentElement.append(fieldset)
    const result = {
      gap: getComputedStyle(field).rowGap,
      margins: [getComputedStyle(field).marginBottom, getComputedStyle(label).marginBottom],
      legendGap: control.getBoundingClientRect().top - legend.getBoundingClientRect().bottom,
    }
    fieldset.remove()
    return result
  })
  verify(
    fields.gap === "8px" && fields.margins.join() === "0px,0px",
    "Fields own internal gaps and leave sibling spacing to their parent",
  )
  verify(fields.legendGap === 8, "Native fieldsets keep 8px between their legend and controls")

  await page.goto(`${origin}/components/foundations.html`)
  const overrides = await page.evaluate(() => {
    const stack = document.querySelector("#example-2 [data-example-preview]").firstElementChild
    stack.style.setProperty("--ui-space-section", "40px")
    const heading = document.querySelector("#example-0 .ui-heading-page")
    heading.style.setProperty("--ui-heading-page-size", "32px")
    const result = [getComputedStyle(stack).rowGap, getComputedStyle(heading).fontSize]
    stack.style.removeProperty("--ui-space-section")
    heading.style.removeProperty("--ui-heading-page-size")
    return result
  })
  verify(overrides.join() === "40px,32px", "Host custom properties adjust spacing and text roles")
  return checks
}
