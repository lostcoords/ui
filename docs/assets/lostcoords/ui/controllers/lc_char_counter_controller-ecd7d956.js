import { Controller } from "@hotwired/stimulus"

const FIELDS =
  "textarea, input:not([type=hidden], [type=checkbox], [type=radio], [type=submit], [type=button], [type=reset])"

// Fills lc_char_counter's ring from a field's characters, or from a count you supply: set the count value,
// or send an event whose detail.count is the count to update.
export default class extends Controller {
  static targets = ["remaining", "progress"]
  static values = {
    max: Number,
    warn: { type: Number, default: 20 },
    for: String,
    label: String,
    count: Number,
  }

  connect() {
    this.field = this.forValue ? document.getElementById(this.forValue) : this.nearestField()
    this.input = () => this.render()
    this.field?.addEventListener("input", this.input)
    this.render()
  }

  disconnect() {
    this.field?.removeEventListener("input", this.input)
  }

  update({ detail }) {
    this.countValue = detail.count
  }

  countValueChanged() {
    if (this.field !== undefined) this.render()
  }

  get count() {
    if (this.hasCountValue) return this.countValue
    return Array.from(this.field?.value ?? "").length
  }

  render() {
    const count = this.count
    const left = this.maxValue - count
    const circumference = 2 * Math.PI * Number(this.progressTarget.getAttribute("r"))
    this.progressTarget.style.strokeDasharray = `${Math.min(count / this.maxValue, 1) * circumference} ${circumference}`
    this.element.dataset.state = left < 0 ? "over" : left <= this.warnValue ? "near" : "ok"
    this.element.hidden = count === 0
    this.remainingTarget.textContent = left <= this.warnValue ? String(left) : ""
    this.element.setAttribute(
      "aria-label",
      this.labelValue.replace("%{count}", count).replace("%{max}", this.maxValue),
    )
  }

  nearestField() {
    for (let node = this.element.parentElement; node; node = node.parentElement) {
      const field = node.querySelector(FIELDS)
      if (field) return field
    }
    return null
  }
}
