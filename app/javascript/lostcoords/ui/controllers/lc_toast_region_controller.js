import { Controller } from "@hotwired/stimulus"
import { topModalElement } from "lostcoords/ui/helpers/dismiss_stack"
import { hideTopLayer, showTopLayer, supportsTopLayer } from "lostcoords/ui/helpers/top_layer"

// Shows the region in the top layer while it holds toasts, so no sticky header,
// sheet or dialog paints over them. Each new toast re-opens the region, which
// moves it above anything opened since. A modal dialog makes the rest of the
// page inert, so while one is open the region moves inside it, keeping toasts
// clickable and announced, and moves back when it closes. Without the Popover
// API the region stays fixed at --lc-z-toast.
const homes = new WeakMap()

export default class extends Controller {
  connect() {
    if (!supportsTopLayer()) return

    this.observer = new MutationObserver((records) => {
      if (records.some((record) => record.addedNodes.length > 0)) this.raise()
      else if (this.element.childElementCount === 0) this.lower()
    })
    this.observer.observe(this.element, { childList: true })
    if (this.element.childElementCount > 0) this.raise()
  }

  // A modal removed right after closing (before its close event) takes the
  // region with it; put the region back in the page.
  disconnect() {
    this.observer?.disconnect()
    hideTopLayer(this.element)
    if (!this.element.isConnected) this.goHome()
  }

  raise() {
    const modal = topModalElement()
    if (modal && !modal.contains(this.element)) return this.moveInto(modal)

    hideTopLayer(this.element)
    showTopLayer(this.element)
  }

  lower() {
    hideTopLayer(this.element)
    this.goHome()
  }

  // Moving the region reconnects this controller, which raises it again.
  moveInto(modal) {
    if (!homes.has(this.element))
      homes.set(this.element, { parent: this.element.parentNode, next: this.element.nextSibling })
    const region = this.element
    modal.addEventListener("close", () => this.goHome(region), { once: true })
    modal.append(region)
  }

  goHome(region = this.element) {
    const home = homes.get(region)
    if (!home?.parent.isConnected) return

    homes.delete(region)
    home.parent.insertBefore(region, home.next?.parentNode === home.parent ? home.next : null)
  }
}
