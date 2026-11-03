import { Controller } from "@hotwired/stimulus"
import { prefersReducedMotion } from "lostcoords/ui/helpers/viewport"

export default class extends Controller {
  static values = { timeout: { type: Number, default: 4000 } }

  connect() {
    for (const sibling of this.element.parentElement?.children || []) {
      if (sibling === this.element) continue
      this.application.getControllerForElementAndIdentifier(sibling, "lc-toast")?.dismiss()
    }

    this.startedAt = performance.now()
    this.remaining = this.timeoutValue
    this.schedule(this.remaining)

    this.pause = () => this.pauseTimer()
    this.resume = () => this.resumeTimer()

    this.element.addEventListener("mouseenter", this.pause)
    this.element.addEventListener("mouseleave", this.resume)
    this.element.addEventListener("focusin", this.pause)
    this.element.addEventListener("focusout", this.resume)
  }

  disconnect() {
    clearTimeout(this.timer)
    clearTimeout(this.removeTimer)
    this.element.removeEventListener("mouseenter", this.pause)
    this.element.removeEventListener("mouseleave", this.resume)
    this.element.removeEventListener("focusin", this.pause)
    this.element.removeEventListener("focusout", this.resume)
  }

  schedule(ms) {
    if (this.timeoutValue === 0) return
    if (this.timer) clearTimeout(this.timer)
    this.startedAt = performance.now()
    this.timer = setTimeout(() => this.dismiss(), ms)
  }

  pauseTimer() {
    if (!this.timer) return
    clearTimeout(this.timer)
    this.timer = null
    const elapsed = performance.now() - this.startedAt
    this.remaining = Math.max(0, this.remaining - elapsed)
  }

  resumeTimer() {
    if (this.timer) return
    this.schedule(this.remaining)
  }

  dismiss() {
    if (this.element.hasAttribute("data-leaving")) return
    if (this.timer) clearTimeout(this.timer)
    this.element.dataset.leaving = ""

    const reduced = prefersReducedMotion()
    if (reduced) {
      this.element.remove()
      return
    }

    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
    this.removeTimer = setTimeout(() => this.element.isConnected && this.element.remove(), 400)
  }
}
