import { Controller } from "@hotwired/stimulus"
import { navigate } from "lostcoords/ui/helpers/roving_focus"

// The ARIA tabs pattern. Arrow keys follow the tab list's aria-orientation, and
// Home and End jump to the ends. With automatic activation, moving focus selects
// the tab; with manual activation, Enter or Space does.
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { activation: { type: String, default: "automatic" } }

  select(event) {
    this.show(event.currentTarget)
  }

  navigate(event) {
    const list = event.currentTarget.closest('[role="tablist"]')
    const tab = navigate(event, this.tabTargets, {
      orientation:
        list?.getAttribute("aria-orientation") === "vertical" ? "vertical" : "horizontal",
      wrap: true,
    })
    if (!tab) return

    if (this.activationValue === "manual") this.focusOnly(tab)
    else this.show(tab)
  }

  focusOnly(tab) {
    for (const candidate of this.tabTargets) candidate.tabIndex = candidate === tab ? 0 : -1
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
