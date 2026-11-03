import { Controller } from "@hotwired/stimulus"

const THEME_KEY = "lostcoords-ui:theme"

export default class extends Controller {
  static targets = ["theme", "token"]

  connect() {
    this.onStorage = (event) => event.key === THEME_KEY && this.applyTheme(event.newValue)
    window.addEventListener("storage", this.onStorage)
    this.media = matchMedia("(prefers-color-scheme: dark)")
    this.onSystemTheme = () => this.applyTheme(localStorage.getItem(THEME_KEY))
    this.media.addEventListener("change", this.onSystemTheme)
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
