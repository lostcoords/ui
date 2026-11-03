import { Controller } from "@hotwired/stimulus"

const PALETTE_KEY = "lostcoords-ui:palette"
const THEME_KEY = "lostcoords-ui:theme"

export default class extends Controller {
  static targets = ["theme", "token", "palette", "paletteStatus"]

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

  toggleTheme() {
    const theme = document.documentElement.dataset.theme === "dark" ? "light" : "dark"
    localStorage.setItem(THEME_KEY, theme)
    this.applyTheme(theme)
  }

  selectPalette({ target }) {
    localStorage.setItem(PALETTE_KEY, target.value)
    this.applyPalette(target.value)
    this.paletteStatusTarget.textContent = `${target.dataset.paletteName} palette applied.`
  }

  applyPalette(value) {
    const selected =
      this.paletteTargets.find((input) => input.value === value) || this.paletteTargets[0]
    if (selected.value === "original") delete document.documentElement.dataset.palette
    else document.documentElement.dataset.palette = selected.value
    for (const input of this.paletteTargets) input.checked = input === selected
    document
      .getElementById("palette-picker-trigger")
      .setAttribute("aria-label", `Color palette: ${selected.dataset.paletteName}`)
    this.readTokens()
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
      row.querySelector("[data-token-value]").textContent = value || "inlined by @theme inline"
      swatch.hidden = !CSS.supports("color", value)
      swatch.style.setProperty("--swatch", value)
    }
  }
}
