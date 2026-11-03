import { Controller } from "@hotwired/stimulus"
import { registerDialog } from "lostcoords/ui/helpers/dialog"
import { prefersReducedMotion } from "lostcoords/ui/helpers/viewport"

export default class extends Controller {
  static targets = [
    "dialog",
    "trigger",
    "input",
    "bar",
    "results",
    "result",
    "group",
    "empty",
    "clear",
    "summary",
    "shortcut",
    "selectionTitle",
    "selectionDetail",
    "selectionStatus",
  ]

  connect() {
    this.animations = []
    this.onShortcut = (event) => {
      if (event.isComposing || !(event.metaKey || event.ctrlKey) || event.key.toLowerCase() !== "k")
        return
      if (document.querySelector("dialog[open]") && !this.dialogTarget.open) return
      event.preventDefault()
      this.open()
    }
    document.addEventListener("keydown", this.onShortcut)
    this.shortcutTarget.textContent = /Mac|iPhone|iPad/.test(navigator.platform) ? "⌘ K" : "Ctrl K"
  }

  disconnect() {
    document.removeEventListener("keydown", this.onShortcut)
    this.returnFocus = null
    this.reset()
  }

  open() {
    if (this.closing) return
    if (this.dialogTarget.open) return this.inputTarget.focus()
    this.returnFocus =
      document.activeElement === document.body ? this.triggerTarget : document.activeElement
    this.filter()
    this.dialogTarget.showModal()
    this.unregisterDialog = registerDialog(this.dialogTarget, { close: () => this.close() })
    this.inputTarget.focus({ preventScroll: true })
    this.animate()
  }

  close() {
    if (!this.dialogTarget.open || this.closing) return
    this.closing = true
    this.animate({ reverse: true })
    Promise.allSettled(this.animations.map((animation) => animation.finished)).then(() =>
      this.reset(),
    )
  }

  reset() {
    this.animations.forEach((animation) => animation.cancel())
    this.animations = []
    this.dialogTarget.close()
    this.unregisterDialog?.()
    this.unregisterDialog = null
    this.closing = false
  }

  closed() {
    this.reset()
    this.returnFocus?.focus({ preventScroll: true })
    this.returnFocus = null
  }

  dismiss(event) {
    if (event.target.hasAttribute("data-search-dismiss")) this.close()
  }

  clear() {
    this.inputTarget.value = ""
    this.filter()
    this.inputTarget.focus()
  }

  filter(event) {
    if (event?.isComposing) return
    const query = this.inputTarget.value.normalize("NFKC").trim().toLowerCase()
    const words = query.split(/\s+/).filter(Boolean)
    let count = 0
    for (const result of this.resultTargets) {
      result.hidden = !words.every((word) => result.dataset.search.includes(word))
      if (!result.hidden) count++
    }
    for (const group of this.groupTargets) {
      group.hidden = !group.querySelector("[data-blocks-search-target=result]:not([hidden])")
    }
    this.clearTarget.hidden = !this.inputTarget.value
    this.emptyTarget.hidden = count > 0
    this.summaryTarget.textContent = query
      ? `${count} ${count === 1 ? "result" : "results"} for “${this.inputTarget.value.trim()}”`
      : "Start with something recent"
  }

  navigate(event) {
    if (event.isComposing || event.keyCode === 229) return
    const results = this.resultTargets.filter((result) => !result.hidden)
    const items = [this.inputTarget, ...results]
    const index = items.indexOf(document.activeElement)
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const step = event.key === "ArrowDown" ? 1 : -1
      items[Math.min(Math.max(index + step, 0), items.length - 1)].focus()
    } else if (event.key === "Enter" && document.activeElement === this.inputTarget) {
      event.preventDefault()
      results[0]?.click()
    }
  }

  select(event) {
    this.showSelection(event.currentTarget.dataset)
    this.close()
  }

  explore(event) {
    this.showSelection(event.currentTarget.dataset)
  }

  showSelection({ title, detail }) {
    this.selectionTitleTarget.textContent = title
    this.selectionDetailTarget.textContent = detail
    this.selectionStatusTarget.textContent = `Opened ${title}.`
  }

  animate({ reverse = false } = {}) {
    this.animations.forEach((animation) => animation.cancel())
    this.animations = []
    if (prefersReducedMotion()) return
    const from = this.triggerTarget.getBoundingClientRect()
    const to = this.barTarget.getBoundingClientRect()
    const insetY = Math.max((to.height - from.height) / 2, 0)
    const shiftY = from.top + from.height / 2 - (to.top + to.height / 2)
    const timing = {
      duration: reverse ? 200 : 360,
      easing: "cubic-bezier(0.16, 1, 0.3, 1)",
      direction: reverse ? "reverse" : "normal",
      fill: "both",
    }
    this.animations = [
      this.barTarget.animate(
        [
          {
            clipPath: `inset(${insetY}px ${to.right - from.right}px ${insetY}px ${from.left - to.left}px round 999px)`,
            translate: `0 ${shiftY}px`,
          },
          { clipPath: "inset(-1rem round 999px)", translate: "0 0" },
        ],
        timing,
      ),
      this.resultsTarget.animate(
        [
          { opacity: 0, translate: "0 -0.5rem" },
          { opacity: 1, translate: "0 0" },
        ],
        timing,
      ),
    ]
  }
}
