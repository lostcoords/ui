import { Controller } from "@hotwired/stimulus"
import { navigate } from "lostcoords/ui/helpers/roving_focus"

export default class extends Controller {
  static targets = ["option", "input"]
  static values = { value: String }

  connect() {
    const selected = this.options.find((option) =>
      this.hasValueValue
        ? option.dataset.value === this.valueValue
        : option.getAttribute("aria-checked") === "true",
    )
    this.initialOption = selected || this.options[0]
    this.apply(this.initialOption)
    this.form = this.element.closest("form")
    this.onReset = () => queueMicrotask(() => this.apply(this.initialOption))
    this.form?.addEventListener("reset", this.onReset)
  }

  disconnect() {
    this.form?.removeEventListener("reset", this.onReset)
  }

  select(event) {
    const option = event.target.closest('[data-lc-selection-target~="option"]')
    if (!this.options.includes(option)) return
    this.apply(option)
    this.changed(option)
  }

  // All four arrows move and select, wrapping at the ends; Left and Right
  // follow the text direction.
  navigate(event) {
    const option = navigate(event, this.optionTargets, { orientation: "both", wrap: true })
    if (!option) return

    this.apply(option)
    this.changed(option)
  }

  apply(selected) {
    for (const option of this.optionTargets) {
      option.setAttribute("aria-checked", String(option === selected))
      option.tabIndex = option === selected ? 0 : -1
    }
    if (this.hasInputTarget) this.inputTarget.value = selected?.dataset.value || ""
  }

  changed(option) {
    if (this.hasInputTarget) {
      this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
    this.dispatch("change", { detail: { value: option.dataset.value } })
  }

  get options() {
    return this.optionTargets.filter((option) => !option.disabled)
  }
}
