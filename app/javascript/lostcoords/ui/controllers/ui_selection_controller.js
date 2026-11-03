import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option", "input"]
  static values = { value: String }

  connect() {
    const selected = this.options.find((option) =>
      this.hasValueValue
        ? option.dataset.value === this.valueValue
        : option.getAttribute("aria-pressed") === "true",
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
    const option = event.target.closest('[data-ui-selection-target~="option"]')
    if (!this.options.includes(option)) return
    this.apply(option)
    this.changed(option)
  }

  navigate(event) {
    const current = this.options.indexOf(event.target)
    if (current < 0) return
    const next = {
      ArrowRight: (current + 1) % this.options.length,
      ArrowDown: (current + 1) % this.options.length,
      ArrowLeft: (current - 1 + this.options.length) % this.options.length,
      ArrowUp: (current - 1 + this.options.length) % this.options.length,
      Home: 0,
      End: this.options.length - 1,
    }[event.key]
    if (next === undefined) return
    event.preventDefault()
    const option = this.options[next]
    option.focus()
    this.apply(option)
    this.changed(option)
  }

  apply(selected) {
    for (const option of this.optionTargets) {
      option.setAttribute("aria-pressed", String(option === selected))
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
