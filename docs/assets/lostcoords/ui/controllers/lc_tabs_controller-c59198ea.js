import { Controller } from "@hotwired/stimulus"

// Tabs with automatic activation: arrow keys, Home and End move focus and select.
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    this.show(event.currentTarget)
  }

  navigate(event) {
    const tabs = this.tabTargets.filter((tab) => !tab.disabled)
    const index = tabs.indexOf(event.currentTarget)
    const step = getComputedStyle(this.element).direction === "rtl" ? -1 : 1
    const next = {
      ArrowRight: index + step,
      ArrowLeft: index - step,
      Home: 0,
      End: tabs.length - 1,
    }[event.key]
    if (next === undefined) return

    event.preventDefault()
    const tab = tabs[(next + tabs.length) % tabs.length]
    tab.focus()
    this.show(tab)
  }

  show(tab) {
    for (const candidate of this.tabTargets) {
      const selected = candidate === tab
      candidate.setAttribute("aria-selected", String(selected))
      candidate.tabIndex = selected ? 0 : -1
    }
    const panelId = tab.getAttribute("aria-controls")
    for (const panel of this.panelTargets) panel.hidden = panel.id !== panelId
    this.dispatch("change", { detail: { value: tab.dataset.value } })
  }
}
