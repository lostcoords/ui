import { Controller } from "@hotwired/stimulus"

const PALETTE_KEY = "lostcoords-ui:palette"
const THEME_KEY = "lostcoords-ui:theme"

export default class extends Controller {
  static targets = [
    "theme",
    "token",
    "palette",
    "paletteStatus",
    "tokenFilter",
    "tokenCount",
    "filterableToken",
  ]

  connect() {
    this.onStorage = (event) => {
      if (event.key === THEME_KEY || event.key === null) this.applyTheme(event.newValue)
      if (event.key === PALETTE_KEY || event.key === null) this.applyPalette(event.newValue)
    }
    window.addEventListener("storage", this.onStorage)
    this.media = matchMedia("(prefers-color-scheme: dark)")
    this.onSystemTheme = () => this.applyTheme(localStorage.getItem(THEME_KEY))
    this.media.addEventListener("change", this.onSystemTheme)
    this.applyPalette(localStorage.getItem(PALETTE_KEY))
    this.onSystemTheme()
  }

  disconnect() {
    window.removeEventListener("storage", this.onStorage)
    this.media.removeEventListener("change", this.onSystemTheme)
  }

  preventExampleSubmit(event) {
    if (event.target.closest("[data-example-preview]") && event.target.method !== "dialog")
      event.preventDefault()
  }

  toggleTheme() {
    const theme = document.documentElement.dataset.theme === "dark" ? "light" : "dark"
    localStorage.setItem(THEME_KEY, theme)
    this.applyTheme(theme)
  }

  choosePalette({ detail: { id } }) {
    localStorage.setItem(PALETTE_KEY, id)
    const selected = this.applyPalette(id)
    this.paletteStatusTarget.textContent = `${selected.dataset.paletteName} palette applied.`
  }

  applyPalette(value) {
    const selected =
      this.paletteTargets.find((choice) => choice.value === value) || this.paletteTargets[0]
    if (selected.value === "original") delete document.documentElement.dataset.palette
    else document.documentElement.dataset.palette = selected.value
    for (const choice of this.paletteTargets)
      choice.setAttribute("aria-current", String(choice === selected))
    document
      .getElementById("palette-picker-trigger")
      .setAttribute("aria-label", `Color palette: ${selected.dataset.paletteName}`)
    this.readTokens()
    return selected
  }

  save(event) {
    event.preventDefault()
    event.currentTarget.querySelector("[data-save-status]").hidden = false
  }

  applyTheme(theme) {
    const dark = theme === "dark" || (!theme && this.media.matches)
    if (dark) document.documentElement.dataset.theme = "dark"
    else delete document.documentElement.dataset.theme
    for (const button of this.themeTargets) {
      button.setAttribute("aria-pressed", String(dark))
      button.setAttribute("aria-label", dark ? "Switch to light theme" : "Switch to dark theme")
    }
    this.readTokens()
  }

  readTokens() {
    const style = getComputedStyle(document.documentElement)
    for (const row of this.tokenTargets) {
      const value = style.getPropertyValue(row.dataset.token).trim()
      const swatch = row.querySelector("[data-token-swatch]")
      row.querySelector("[data-token-value]").textContent = value || "Not set"
      swatch.hidden = !CSS.supports("color", value)
      swatch.style.setProperty("--swatch", value)
    }
    this.filterTokens()
  }

  filterTokens() {
    if (!this.hasTokenFilterTarget) return

    const query = this.tokenFilterTarget.value.trim().toLowerCase()
    let visible = 0
    for (const row of this.filterableTokenTargets) {
      row.hidden = !row.textContent.toLowerCase().includes(query)
      if (!row.hidden) visible += 1
    }
    for (const group of this.element.querySelectorAll("#foundation-token-table tbody")) {
      const heading = group.querySelector(
        ":scope > tr:not([data-showcase-target~='filterableToken'])",
      )
      const rows = [...group.querySelectorAll("[data-showcase-target~='filterableToken']")]
      const hasMatches = rows.some((row) => !row.hidden)
      if (heading) heading.hidden = !hasMatches
    }
    this.tokenCountTarget.textContent = `${visible} of ${this.filterableTokenTargets.length} tokens`
  }
}
