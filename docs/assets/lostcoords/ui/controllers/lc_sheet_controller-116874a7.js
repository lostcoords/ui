import { Controller } from "@hotwired/stimulus"
import { holdDocumentScroll } from "lostcoords/ui/helpers/dismiss_stack"
import { SHEET_TIMING, sheetDuration } from "lostcoords/ui/helpers/sheet_motion"
import { isSheetViewport, prefersReducedMotion, TEXT_ENTRY } from "lostcoords/ui/helpers/viewport"

const PROJECTION_MS = 180
const MEDIUM_FRACTION = 0.5
const PAGE_SCALE_LOSS = 0.06
const NO_DRAG = "input[type=range], [data-lc-sheet-no-drag]"
const HANDLE = "[data-lc-sheet-target~='handle']"
const GRABBER_ZONE = 28
const KEYBOARD_FREE = 0.5

export default class extends Controller {
  static targets = ["handle"]
  static values = { detents: { type: String, default: "fit" } }

  connect() {
    this.onTouchStart = this.onTouchStart.bind(this)
    this.onTouchMove = this.onTouchMove.bind(this)
    this.onTouchEnd = this.onTouchEnd.bind(this)
    this.onPointerDown = this.onPointerDown.bind(this)
    this.onPointerMove = this.onPointerMove.bind(this)
    this.onPointerUp = this.onPointerUp.bind(this)

    this.element.addEventListener("touchstart", this.onTouchStart, { passive: true })
    this.element.addEventListener("touchmove", this.onTouchMove, { passive: false })
    this.element.addEventListener("touchend", this.onTouchEnd)
    this.element.addEventListener("touchcancel", this.onTouchEnd)
    this.element.addEventListener("pointerdown", this.onPointerDown)

    if (this.isDialog) {
      this.observer = new MutationObserver(() =>
        this.element.open ? this.present() : this.closed(),
      )
      this.observer.observe(this.element, { attributes: true, attributeFilter: ["open"] })
      if (this.element.open) this.present()
    } else {
      this.observer = new MutationObserver(() => this.element.hidden || this.pinFloor())
      this.observer.observe(this.element, { attributes: true, attributeFilter: ["hidden"] })
    }
  }

  disconnect() {
    this.observer?.disconnect()
    this.element.removeEventListener("touchstart", this.onTouchStart)
    this.element.removeEventListener("touchmove", this.onTouchMove)
    this.element.removeEventListener("touchend", this.onTouchEnd)
    this.element.removeEventListener("touchcancel", this.onTouchEnd)
    this.element.removeEventListener("pointerdown", this.onPointerDown)
    this.stopMouseTracking()
    clearTimeout(this.settleTimer)
    clearTimeout(this.transitionTimer)
    this.releasePage()
    this.resetSurface()
  }

  present() {
    clearTimeout(this.settleTimer)
    if (!this.isSheet) return
    this.resetSurface()
    this.pinFloor()
    const detents = this.detents()
    this.detent = detents[0]
    if (detents.length > 1 || this.detent.large)
      this.element.style.blockSize = `${this.detent.height}px`
    this.setLargeness(this.detent.large ? 1 : 0)
    if (this.detent.large) this.animatePage(1)
  }

  // The keyboard rises over the sheet. Safari and in-app browsers shrink the
  // page under it, which would drag a bottom-pinned sheet up and squash it, so
  // the sheet is placed from the top at the height the screen had when it
  // opened (see --lc-sheet-floor in the CSS).
  pinFloor() {
    if (this.isSheet) this.element.style.setProperty("--lc-sheet-floor", `${window.innerHeight}px`)
  }

  closed() {
    this.gesture = null
    if (this.ownsPage) this.animatePage(0)
    this.later(() => {
      this.releasePage()
      this.resetSurface()
    })
  }

  // Touch: decide on the first move whether the gesture is the sheet's or the
  // scroller's. A touchmove that isn't cancelled at once lets native scrolling
  // start, and that can't be taken back.
  onTouchStart(event) {
    this.gesture = null
    if (!this.isSheet || event.touches.length !== 1 || event.target.closest(NO_DRAG)) return
    const touch = event.touches[0]
    this.begin(touch.clientX, touch.clientY, event.timeStamp, this.scrollerFor(event.target))
  }

  onTouchMove(event) {
    const gesture = this.gesture
    if (!gesture) return
    const touch = event.touches[0]

    if (!gesture.dragging) {
      const dx = touch.clientX - gesture.startX
      const dy = touch.clientY - gesture.startY
      if (dx === 0 && dy === 0) return
      if (!this.claims(dx, dy, gesture.scroller)) {
        this.gesture = null
        return
      }
      this.startDrag(touch.clientY)
    }

    event.preventDefault()
    this.track(touch.clientY, event.timeStamp)
  }

  onTouchEnd(event) {
    if (this.gesture?.dragging) this.release()
    else if (this.gesture && event?.type === "touchend") this.focusInPlace(event)
    this.gesture = null
  }

  // The keyboard rises over the sheet; nothing moves to make room for it. But
  // Safari scrolls the page to "reveal" a tapped field even when the keyboard
  // won't cover it, dragging the sheet up and back. A field in the top half,
  // which no keyboard reaches, is focused while shifted off-screen so there is
  // nothing to reveal (react-aria's usePreventScroll trick). Lower fields keep
  // the native reveal: moving is better than typing blind.
  focusInPlace(event) {
    const field = event.target.closest?.(TEXT_ENTRY)
    if (!event.cancelable || !field || field === document.activeElement) return
    if (field.getBoundingClientRect().bottom > window.innerHeight * KEYBOARD_FREE) return

    event.preventDefault()
    const transform = field.style.transform
    field.style.transform = "translateY(-2000px)"
    field.focus()
    requestAnimationFrame(() => (field.style.transform = transform))
  }

  onPointerDown(event) {
    if (!this.isSheet || event.pointerType !== "mouse" || event.button !== 0) return
    const fromTop = event.clientY - this.element.getBoundingClientRect().top
    if (!event.target.closest(HANDLE) && fromTop > GRABBER_ZONE) return

    this.begin(event.clientX, event.clientY, event.timeStamp, null)
    this.startDrag(event.clientY)
    window.addEventListener("pointermove", this.onPointerMove)
    window.addEventListener("pointerup", this.onPointerUp)
    window.addEventListener("pointercancel", this.onPointerUp)
  }

  onPointerMove(event) {
    if (this.gesture?.dragging) this.track(event.clientY, event.timeStamp)
  }

  onPointerUp() {
    this.stopMouseTracking()
    this.onTouchEnd()
  }

  stopMouseTracking() {
    window.removeEventListener("pointermove", this.onPointerMove)
    window.removeEventListener("pointerup", this.onPointerUp)
    window.removeEventListener("pointercancel", this.onPointerUp)
  }

  begin(x, y, time, scroller) {
    this.gesture = {
      startX: x,
      startY: y,
      lastY: y,
      lastT: time,
      velocity: 0,
      scroller,
      dragging: false,
    }
  }

  claims(dx, dy, scroller) {
    if (Math.abs(dx) > Math.abs(dy)) return false
    if (!scroller) return true
    if (dy > 0) return scroller.scrollTop <= 0
    const detents = this.detents()
    return this.visibleHeight() < detents.at(-1).height - 1
  }

  startDrag(y) {
    clearTimeout(this.settleTimer)
    const gesture = this.gesture
    gesture.dragging = true
    gesture.anchorY = y
    gesture.detents = this.detents()
    gesture.startVisible = this.visibleHeight()
    this.element.style.transition = "none"
    this.element.style.willChange = "transform"
    this.pageTransition("0s")

    const field = document.activeElement
    if (this.element.contains(field) && field.matches("input, textarea, select")) field.blur()
  }

  track(y, time) {
    const gesture = this.gesture
    const dt = time - gesture.lastT
    if (dt > 0) gesture.velocity = (y - gesture.lastY) / dt
    gesture.lastY = y
    gesture.lastT = time

    this.show(
      this.rubberBand(gesture.startVisible - (y - gesture.anchorY), gesture.detents),
      gesture.detents,
    )
  }

  release() {
    const { detents, velocity } = this.gesture
    const projected = this.visibleHeight() - velocity * PROJECTION_MS

    if (velocity >= 0 && projected < detents[0].height * 0.6) return this.dismiss()

    const target = detents.reduce((best, detent) =>
      Math.abs(detent.height - projected) < Math.abs(best.height - projected) ? detent : best,
    )
    this.settle(target, detents)
  }

  settle(detent, detents = this.detents()) {
    this.detent = detent
    this.transition()
    this.pageTransition()
    this.show(detent.height, detents)
  }

  dismiss() {
    if (this.isDialog) return this.dismissDialog()

    this.transition()
    this.element.style.transform = `translateY(${this.element.getBoundingClientRect().height + 48}px)`
    this.later(() => {
      this.dispatch("dismiss", { bubbles: false })
      requestAnimationFrame(() => this.resetSurface())
    })
  }

  dismissDialog() {
    const cancel = new Event("cancel", { cancelable: true })
    this.element.dispatchEvent(cancel)
    if (!cancel.defaultPrevented) this.element.close()

    if (this.element.open) return this.settle(this.detent || this.detents()[0])

    this.transition()
    this.element.style.transform = ""
  }

  detents() {
    const names = this.detentsValue.split(/\s+/)
    const large = this.largeHeight
    const fit = Math.min(this.fitHeight(), large)
    const medium = Math.round(window.innerHeight * MEDIUM_FRACTION)

    if (!names.includes("large")) return [{ height: fit, large: false }]
    if (!names.includes("medium")) return [{ height: large, large: true }]
    if (fit <= medium) return [{ height: fit, large: false }]
    return [
      { height: medium, large: false },
      { height: large, large: true },
    ]
  }

  // Between detents the sheet resizes, so a pinned footer stays on screen;
  // below the smallest it slides down whole; past the largest it stretches
  // against resistance — the UIKit rubber band.
  show(visible, detents) {
    const smallest = detents[0].height
    const largest = detents.at(-1).height
    const resizes = detents.length > 1 || detents[0].large
    const style = this.element.style

    if (visible < smallest) {
      style.transform = `translateY(${smallest - visible}px)`
      if (resizes) style.blockSize = `${smallest}px`
    } else {
      style.transform = ""
      if (resizes || visible > largest) style.blockSize = `${visible}px`
    }

    if (!detents.some((detent) => detent.large)) return
    const clamp = (n) => Math.max(0, Math.min(1, n))
    if (detents.length > 1) {
      const p = clamp((visible - smallest) / (largest - smallest))
      this.setLargeness(p)
      this.setPage(p)
    } else {
      this.setPage(clamp(visible / largest))
    }
  }

  rubberBand(wanted, detents) {
    const largest = detents.at(-1).height
    if (wanted <= largest) return wanted
    const room = window.innerHeight - largest + 24
    return largest + room * (1 - 1 / ((wanted - largest) / room + 1))
  }

  // The sheet's height less however far it is slid down off its resting place.
  visibleHeight() {
    const transform = getComputedStyle(this.element).transform
    const slid = transform === "none" ? 0 : new DOMMatrixReadOnly(transform).m42
    return this.element.getBoundingClientRect().height - slid
  }

  // Only a settle's inline transition animates block-size, so only that one is
  // paused. Touching the transition as the sheet opens would cancel its
  // @starting-style slide-up and it would pop into place.
  fitHeight() {
    const style = this.element.style
    const saved = [style.blockSize, style.transition]
    if (saved[1]) style.transition = "none"
    style.blockSize = "auto"
    const height = this.element.getBoundingClientRect().height
    ;[style.blockSize, style.transition] = saved
    return height
  }

  get largeHeight() {
    return parseFloat(getComputedStyle(this.element).maxBlockSize) || window.innerHeight
  }

  setLargeness(p) {
    this.element.style.setProperty("--lc-sheet-p", p.toFixed(3))
  }

  setPage(p) {
    const root = document.documentElement
    if (!this.ownsPage) {
      if (p <= 0) return
      this.releaseScroll = holdDocumentScroll()
      const lockedTop = -parseFloat(document.body.style.top || "0")
      root.style.setProperty("--lc-sheet-page-origin", `${window.scrollY + lockedTop}px`)
      root.dataset.lcSheetPage = ""
      this.ownsPage = true
    }
    root.style.setProperty("--lc-sheet-page-p", p.toFixed(3))
    root.style.setProperty("--lc-sheet-page-scale", (1 - PAGE_SCALE_LOSS * p).toFixed(4))
  }

  animatePage(p) {
    this.pageTransition()
    if (p > 0 && !this.ownsPage) {
      this.setPage(0.001)
      requestAnimationFrame(() => requestAnimationFrame(() => this.setPage(p)))
    } else {
      this.setPage(p)
    }
  }

  releasePage() {
    if (!this.ownsPage) return
    this.ownsPage = false
    const root = document.documentElement
    delete root.dataset.lcSheetPage
    for (const name of ["p", "scale", "origin", "transition"])
      root.style.removeProperty(`--lc-sheet-page-${name}`)
    this.releaseScroll()
  }

  pageTransition(value = prefersReducedMotion() ? "0s" : SHEET_TIMING) {
    if (this.ownsPage || value !== "0s")
      document.documentElement.style.setProperty("--lc-sheet-page-transition", value)
  }

  transition() {
    const timing = prefersReducedMotion() ? "0s" : SHEET_TIMING
    const discrete = this.isDialog
      ? `, display ${timing} allow-discrete, overlay ${timing} allow-discrete`
      : ""
    this.element.style.transition = `transform ${timing}, block-size ${timing}${discrete}`
    clearTimeout(this.transitionTimer)
    this.transitionTimer = setTimeout(() => {
      this.element.style.transition = ""
      this.element.style.willChange = ""
    }, sheetDuration())
  }

  later(callback) {
    clearTimeout(this.settleTimer)
    this.settleTimer = setTimeout(callback, sheetDuration())
  }

  resetSurface() {
    const style = this.element.style
    style.transition = ""
    style.transform = ""
    style.willChange = ""
    style.blockSize = ""
    style.removeProperty("--lc-sheet-p")
    style.removeProperty("--lc-sheet-floor")
  }

  scrollerFor(target) {
    for (let node = target; node; node = node.parentElement) {
      if (
        node.scrollHeight > node.clientHeight + 1 &&
        /auto|scroll/.test(getComputedStyle(node).overflowY)
      )
        return node
      if (node === this.element) return null
    }
    return null
  }

  get isDialog() {
    return this.element instanceof HTMLDialogElement
  }

  get isSheet() {
    return isSheetViewport()
  }
}
