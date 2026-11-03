import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.sync = this.sync.bind(this)
    if (window.parent !== window) {
      this.parentTheme = new MutationObserver(this.sync)
      this.parentTheme.observe(window.parent.document.documentElement, {
        attributes: true,
        attributeFilter: ["data-theme", "data-palette"],
      })
    }
    this.media = matchMedia("(prefers-color-scheme: dark)")
    this.media.addEventListener("change", this.sync)
    window.addEventListener("storage", this.sync)
    this.sync()
  }

  disconnect() {
    this.parentTheme?.disconnect()
    this.media.removeEventListener("change", this.sync)
    window.removeEventListener("storage", this.sync)
  }

  sync() {
    const root = document.documentElement
    if (window.parent !== window) {
      const parent = window.parent.document.documentElement
      for (const attribute of ["data-theme", "data-palette"]) {
        const value = parent.getAttribute(attribute)
        if (value === null) root.removeAttribute(attribute)
        else root.setAttribute(attribute, value)
      }
      return
    }
    const theme = localStorage.getItem("lostcoords-ui:theme")
    root.toggleAttribute("data-theme", theme === "dark" || (!theme && this.media.matches))
    if (root.hasAttribute("data-theme")) root.dataset.theme = "dark"
    const palette = localStorage.getItem("lostcoords-ui:palette")
    if (palette && palette !== "original") root.dataset.palette = palette
    else delete root.dataset.palette
  }
}
