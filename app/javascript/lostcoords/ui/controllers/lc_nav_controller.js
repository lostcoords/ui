import { Controller } from "@hotwired/stimulus"

// Each visit renders a new nav, so the indicator's last spot is kept per nav
// label and the new one slides from there to its current link.
const spots = new Map()

export default class extends Controller {
  static targets = ["indicator", "link"]

  connect() {
    this.key = this.element.getAttribute("aria-label")
    this.initialLink = this.currentLink
    this.restore = () => this.select({ currentTarget: this.initialLink }, { animate: false })
    document.addEventListener("turbo:before-cache", this.restore)

    // The observer reports once on observe, after the first placement below.
    let observed = false
    this.observer = new ResizeObserver(() => {
      if (observed) this.place({ animate: false })
      observed = true
    })
    this.observer.observe(this.element)

    const previous = spots.get(this.key)
    if (previous) this.move(previous, { animate: false })
    this.frame = requestAnimationFrame(() => this.place({ animate: Boolean(previous) }))
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
    this.observer.disconnect()
    document.removeEventListener("turbo:before-cache", this.restore)
  }

  select(event, { animate = true } = {}) {
    if (event.button > 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return

    for (const link of this.linkTargets) {
      if (link === event.currentTarget) link.setAttribute("aria-current", "page")
      else link.removeAttribute("aria-current")
    }
    this.place({ animate })
  }

  get currentLink() {
    return this.linkTargets.find((link) => link.getAttribute("aria-current") === "page")
  }

  place({ animate }) {
    const link = this.currentLink
    if (!link?.offsetParent) {
      this.element.removeAttribute("data-indicator")
      return
    }

    const rtl = getComputedStyle(this.element).direction === "rtl"
    const spot = {
      x: rtl ? link.offsetLeft + link.offsetWidth - this.element.clientWidth : link.offsetLeft,
      y: link.offsetTop,
      width: link.offsetWidth,
      height: link.offsetHeight,
    }
    spots.set(this.key, spot)
    this.move(spot, { animate })
  }

  move({ x, y, width, height }, { animate }) {
    const style = this.indicatorTarget.style
    style.transition = animate ? "" : "none"
    style.translate = `${x}px ${y}px`
    style.width = `${width}px`
    style.height = `${height}px`
    this.element.toggleAttribute("data-indicator", true)
    if (!animate) {
      this.indicatorTarget.offsetWidth
      style.transition = ""
    }
  }
}
