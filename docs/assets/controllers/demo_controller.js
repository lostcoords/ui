import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toast", "toasts"]

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
}
