import { Controller } from "@hotwired/stimulus"

// Marks the link to the section the reader has scrolled to with aria-current="location" and slides
// the indicator to it. A section is current once its top passes its own scroll margin, which is
// where a click on its link puts it.
export default class extends Controller {
  static targets = ["link", "indicator"]

  connect() {
    this.schedule = () => {
      this.frame ||= requestAnimationFrame(() => {
        this.frame = null
        this.update()
      })
    }
    addEventListener("scroll", this.schedule, { passive: true })
    addEventListener("resize", this.schedule, { passive: true })
    this.update({ animate: false })
  }

  disconnect() {
    removeEventListener("scroll", this.schedule)
    removeEventListener("resize", this.schedule)
    cancelAnimationFrame(this.frame)
    this.frame = null
  }

  // The last sections can't scroll up to the top, so at the end of the page the clicked one stays current.
  select(event) {
    this.chosen = event.currentTarget
  }

  update({ animate = true } = {}) {
    const sections = this.linkTargets.flatMap((link) => {
      const target = document.getElementById(decodeURIComponent(link.hash.slice(1)))
      return target ? [{ link, target, top: target.getBoundingClientRect().top }] : []
    })
    let current = null
    for (const section of sections) {
      const margin = Number.parseFloat(getComputedStyle(section.target).scrollMarginTop) || 0
      if (section.top <= margin + 4) current = section.link
    }

    const root = document.scrollingElement ?? document.documentElement
    if (root.scrollTop > 0 && root.scrollTop + innerHeight >= root.scrollHeight - 2) {
      const visible = sections.filter((section) => section.top < innerHeight)
      const chosen = visible.find((section) => section.link === this.chosen)
      current = (chosen ?? visible.at(-1))?.link ?? current
    }
    if (current === this.current && !animate) return this.place(current, { animate })
    if (current === this.current) return

    this.current = current
    for (const link of this.linkTargets) {
      if (link === current) link.setAttribute("aria-current", "location")
      else link.removeAttribute("aria-current")
    }
    this.place(current, { animate })
    this.reveal(current)
  }

  place(link, { animate }) {
    if (!this.hasIndicatorTarget) return

    const style = this.indicatorTarget.style
    style.transition = animate ? "" : "none"
    if (link) {
      style.translate = `0 ${link.offsetTop}px`
      style.height = `${link.offsetHeight}px`
    }
    style.opacity = link ? "1" : "0"
    if (!animate) {
      this.indicatorTarget.offsetWidth
      style.transition = ""
    }
  }

  // Keeps the current link inside a scrolling sidebar without scrolling the page.
  reveal(link) {
    if (!link) return

    let box = this.element.parentElement
    while (box && box !== document.body) {
      const { overflowY } = getComputedStyle(box)
      if ((overflowY === "auto" || overflowY === "scroll") && box.scrollHeight > box.clientHeight)
        break
      box = box.parentElement
    }
    if (!box || box === document.body) return

    const linkBox = link.getBoundingClientRect()
    const frame = box.getBoundingClientRect()
    if (linkBox.top < frame.top) box.scrollTop -= frame.top - linkBox.top
    else if (linkBox.bottom > frame.bottom) box.scrollTop += linkBox.bottom - frame.bottom
  }
}
