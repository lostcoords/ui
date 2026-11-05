import { Controller } from "@hotwired/stimulus"
import { navigate } from "lostcoords/ui/helpers/roving_focus"

const REACH = 5

export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.selected = Math.max(0, this.linkTargets.indexOf(document.activeElement))
    this.resizeObserver = new ResizeObserver(() => this.select(this.selected))
    this.resizeObserver.observe(this.element)
    this.followPointer = this.followPointer.bind(this)
    document.addEventListener("scroll", this.followPointer, { capture: true, passive: true })
  }

  disconnect() {
    this.resizeObserver.disconnect()
    document.removeEventListener("scroll", this.followPointer, { capture: true })
    cancelAnimationFrame(this.frame)
  }

  track({ clientX, clientY, pointerType }) {
    this.pointer = pointerType === "mouse" ? { x: clientX, y: clientY } : null
  }

  // Scrolling moves rows under a still cursor without a pointermove, so the
  // selection would lag until the browser sends one after the scroll settles.
  followPointer() {
    if (!this.pointer || this.frame) return

    this.frame = requestAnimationFrame(() => {
      this.frame = null
      if (!this.pointer) return
      const link = document.elementFromPoint(this.pointer.x, this.pointer.y)?.closest("a")
      const index = this.linkTargets.indexOf(link)
      if (index >= 0 && index !== this.selected) this.select(index)
    })
  }

  activate({ currentTarget }) {
    if (currentTarget.dataset.distance === "0") return

    this.select(this.linkTargets.indexOf(currentTarget))
  }

  // Up and Down follow alphabetical order down each column and on into the
  // next; Left and Right cross to the nearest row of the other column; typing
  // a letter jumps to the next component that starts with it.
  navigate(event) {
    this.pointer = null
    const link = navigate(event, this.linkTargets, {
      orientation: "grid",
      flow: "column",
      typeahead: true,
      label: (item) =>
        item.querySelector(".component-picker__title").textContent.trim().toLocaleLowerCase(),
    })
    if (link) this.select(this.linkTargets.indexOf(link))
  }

  select(index) {
    this.selected = index
    const target = this.linkTargets[index]
    for (const links of this.columns()) {
      const origin = links.indexOf(target)
      for (const [row, link] of links.entries()) {
        const distance = origin < 0 ? REACH : Math.min(Math.abs(row - origin), REACH)
        link.dataset.distance = String(distance)
      }
    }
  }

  // Links grouped by rendered column, in document order. The links never
  // move, only their contents do, so their offsets describe the layout.
  columns() {
    const columns = new Map()
    for (const link of this.linkTargets) {
      const left = link.offsetLeft
      columns.set(left, [...(columns.get(left) ?? []), link])
    }
    return [...columns.entries()].sort(([a], [b]) => a - b).map(([, links]) => links)
  }
}
