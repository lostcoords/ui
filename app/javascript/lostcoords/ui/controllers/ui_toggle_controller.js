import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    this.element.setAttribute(
      "aria-pressed",
      String(this.element.getAttribute("aria-pressed") !== "true"),
    )
    this.dispatch("change", {
      detail: { pressed: this.element.getAttribute("aria-pressed") === "true" },
    })
  }
}
