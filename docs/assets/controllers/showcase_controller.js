import { Controller } from "@hotwired/stimulus"

const THEME_KEY = "lostcoords-ui:theme"

export default class extends Controller {
  static targets = ["theme", "width", "desktop", "phone", "frame", "token", "toast", "toasts"]

  connect() {
    this.framed = document.documentElement.hasAttribute("data-frame")
    this.onStorage = (event) => event.key === THEME_KEY && this.applyTheme(event.newValue)
    window.addEventListener("storage", this.onStorage)
    this.applyTheme(localStorage.getItem(THEME_KEY))

    if (this.framed) this.openFromQuery()
    else this.frameTargets.filter((frame) => frame.checkVisibility()).forEach(load)
  }

  disconnect() {
    window.removeEventListener("storage", this.onStorage)
  }

  setTheme({ params: { theme } }) {
    localStorage.setItem(THEME_KEY, theme)
    this.applyTheme(theme)
  }

  applyTheme(theme) {
    const dark = theme === "dark"
    if (dark) document.documentElement.dataset.theme = "dark"
    else delete document.documentElement.dataset.theme
    for (const button of this.themeTargets) {
      button.setAttribute(
        "aria-pressed",
        String((button.dataset.showcaseThemeParam === "dark") === dark),
      )
    }
    this.readTokens()
  }

  setWidth({ params: { width } }) {
    const phone = width === "phone"
    this.desktopTarget.hidden = phone
    this.phoneTarget.hidden = !phone
    if (phone) this.phoneTarget.querySelectorAll("iframe").forEach(load)
    for (const button of this.widthTargets) {
      button.setAttribute("aria-pressed", String(button.dataset.showcaseWidthParam === width))
    }
  }

  press({ currentTarget }) {
    currentTarget.setAttribute(
      "aria-pressed",
      String(currentTarget.getAttribute("aria-pressed") !== "true"),
    )
  }

  select({ currentTarget }) {
    for (const tab of currentTarget.closest("[role=tablist]").querySelectorAll("[role=tab]")) {
      tab.setAttribute("aria-selected", String(tab === currentTarget))
    }
  }

  choose({ currentTarget }) {
    for (const button of currentTarget.closest("[role=group]").querySelectorAll("button")) {
      button.setAttribute("aria-pressed", String(button === currentTarget))
    }
  }

  toast() {
    this.toastsTarget.append(this.toastTarget.content.cloneNode(true))
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

  openFromQuery() {
    const id = new URLSearchParams(location.search).get("open")
    if (id) document.getElementById(id)?.showModal()
  }
}

function load(frame) {
  if (!frame.getAttribute("src")) frame.src = frame.dataset.showcaseSrc
}
