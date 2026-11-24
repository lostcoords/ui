import { Controller } from "@hotwired/stimulus"
import { SHEET_TIMING, sheetDuration } from "lostcoords/ui/helpers/sheet_motion"
import { hideTopLayer, supportsTopLayer } from "lostcoords/ui/helpers/top_layer"
import { isSheetViewport, prefersReducedMotion, TEXT_ENTRY } from "lostcoords/ui/helpers/viewport"

const PROJECTION_MS = 180
const MEDIUM_FRACTION = 0.5
const NO_DRAG = "input[type=range], [data-lc-sheet-no-drag]"
const DRAG_ZONE = 28
const KEYBOARD_FREE = 0.5
// A finger held still this long before lifting has no fling left in it.
const STILL_MS = 80
// --lc-ease-sheet, cubic-bezier(0.32, 0.72, 0, 1), starts at 0.72 / 0.32 = 2.25×
// its average speed. Change both together.
const EASE_START = 0.72 / 0.32
const FASTEST_MS = 240
// Safari and Firefox can't transition `overlay`, so a closing <dialog> leaves
// the top layer at once and vanishes mid-slide. There the controller plays the
// exit pose ([data-closing]) first and closes when it ends.
const EXITS_NATIVELY = CSS.supports("overlay", "auto")

export default class extends Controller {
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
    if (this.isDialog && !EXITS_NATIVELY) this.holdClose()

    this.sync = this.sync.bind(this)
    this.shown = false
    this.observer = new MutationObserver(this.sync)
    this.observer.observe(this.element, {
      attributes: true,
      attributeFilter: ["open", "data-open"],
    })
    this.element.addEventListener("toggle", this.sync)
    this.sync()
  }

  sync() {
    const shown = this.isShown
    if (shown === this.shown) return
    this.shown = shown
    shown ? this.present() : this.closed()
  }

  disconnect() {
    this.observer?.disconnect()
    this.element.removeEventListener("toggle", this.sync)
    this.element.removeEventListener("touchstart", this.onTouchStart)
    this.element.removeEventListener("touchmove", this.onTouchMove)
    this.element.removeEventListener("touchend", this.onTouchEnd)
    this.element.removeEventListener("touchcancel", this.onTouchEnd)
    this.element.removeEventListener("pointerdown", this.onPointerDown)
    this.releaseClose()
    this.stopMouseTracking()
    clearTimeout(this.settleTimer)
    clearTimeout(this.transitionTimer)
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
    this.later(() => this.resetSurface())
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
    if (this.gesture?.dragging) this.release(event?.timeStamp ?? performance.now())
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
    if (event.clientY - this.element.getBoundingClientRect().top > DRAG_ZONE) return

    this.begin(event.clientX, event.clientY, event.timeStamp, null)
    this.startDrag(event.clientY)
    window.addEventListener("pointermove", this.onPointerMove)
    window.addEventListener("pointerup", this.onPointerUp)
    window.addEventListener("pointercancel", this.onPointerUp)
  }

  onPointerMove(event) {
    if (this.gesture?.dragging) this.track(event.clientY, event.timeStamp)
  }

  // A mouse drag that ends off the sheet is followed by a click on the
  // <dialog> itself, which reads as a backdrop click and would close it.
  onPointerUp(event) {
    this.stopMouseTracking()
    if (this.gesture && Math.abs(event.clientY - this.gesture.startY) > 4) swallowNextClick()
    if (this.gesture?.dragging) this.release(event.timeStamp)
    this.gesture = null
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

  release(time) {
    const { detents, lastT } = this.gesture
    const velocity = time - lastT > STILL_MS ? 0 : this.gesture.velocity
    const visible = this.visibleHeight()
    const projected = visible - velocity * PROJECTION_MS

    if (velocity >= 0 && projected < detents[0].height * 0.6) {
      this.pace(visible + this.offscreenGap, velocity)
      return this.dismiss()
    }

    const target = detents.reduce((best, detent) =>
      Math.abs(detent.height - projected) < Math.abs(best.height - projected) ? detent : best,
    )
    // A fling away from the target, or a lift in place, gets the full beat.
    const toward = Math.sign(visible - target.height) === Math.sign(velocity)
    this.pace(visible - target.height, toward ? velocity : 0)
    this.settle(target, detents)
  }

  // UIKit hands a released sheet on at the finger's speed. The sheet curve opens
  // at EASE_START times its average speed, so a beat of EASE_START × distance ÷
  // speed carries the fling on without a jolt; a slow lift keeps the full beat.
  pace(distance, velocity) {
    const full = sheetDuration()
    const speed = Math.abs(velocity)
    if (!full || !speed) return this.element.style.removeProperty("--lc-sheet-duration")
    const ms = Math.min(full, Math.max(FASTEST_MS, (EASE_START * Math.abs(distance)) / speed))
    this.element.style.setProperty("--lc-sheet-duration", `${Math.round(ms)}ms`)
  }

  settle(detent, detents = this.detents()) {
    this.detent = detent
    this.transition()
    this.show(detent.height, detents)
  }

  dismiss() {
    if (this.isDialog) return this.dismissDialog()

    this.transition()
    this.element.style.transform = `translateY(${this.element.getBoundingClientRect().height + 48}px)`
    this.later(() => {
      const event = this.dispatch("dismiss", { bubbles: false, cancelable: true })
      if (!event.defaultPrevented) hideTopLayer(this.element)
      requestAnimationFrame(() => this.resetSurface())
    })
  }

  // The cancel may close the dialog, or keep it open (a listener asking to
  // discard changes): then the sheet settles back.
  dismissDialog() {
    this.transition()
    const cancel = new Event("cancel", { cancelable: true })
    this.element.dispatchEvent(cancel)
    if (!cancel.defaultPrevented) this.element.close()

    if (this.element.open && !this.closing) return this.settle(this.detent || this.detents()[0])
    this.element.style.transform = ""
  }

  // Every close() then goes through the exit, whoever calls it, and so does a
  // method=dialog form, which the browser would close at once. A native Escape
  // on a dialog no dismiss stack handles still closes at once.
  holdClose() {
    const close = HTMLDialogElement.prototype.close
    this.closeNow = (value) => close.call(this.element, value)
    this.element.close = (value) => this.closeAfterExit(value)
    this.onDialogSubmit = (event) => {
      const method = event.submitter?.getAttribute("formmethod") || event.target.method
      if (method !== "dialog" || event.target.closest("dialog") !== this.element) return
      event.preventDefault()
      this.element.close(event.submitter?.value)
    }
    this.element.addEventListener("submit", this.onDialogSubmit)
  }

  releaseClose() {
    if (!this.closeNow) return
    delete this.element.close
    this.element.removeEventListener("submit", this.onDialogSubmit)
    clearTimeout(this.exitTimer)
    if (this.closing) this.finishClose()
  }

  closeAfterExit(value) {
    if (!this.element.open || this.closing) return
    this.closing = { value }
    if (value !== undefined) this.element.returnValue = value
    this.element.toggleAttribute("data-closing", true)
    // close fires once the slide ends; lc-sheet:exit tells a caller waiting on the answer now.
    this.dispatch("exit", { bubbles: false })
    this.element.style.transform = ""
    this.exitTimer = setTimeout(() => this.finishClose(), this.exitDuration())
  }

  finishClose() {
    const { value } = this.closing
    this.closing = null
    this.closeNow(value)
    this.element.removeAttribute("data-closing")
  }

  exitDuration() {
    const { transitionDuration, transitionDelay } = getComputedStyle(this.element)
    const ms = (list) =>
      list.split(",").map((time) => parseFloat(time) * (time.trim().endsWith("ms") ? 1 : 1000))
    const delays = ms(transitionDelay)
    return Math.max(
      0,
      ...ms(transitionDuration).map((duration, i) => duration + (delays[i % delays.length] || 0)),
    )
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

  transition() {
    const timing = prefersReducedMotion() ? "0s" : SHEET_TIMING
    this.element.style.transition = `transform ${timing}, block-size ${timing}, display ${timing} allow-discrete, overlay ${timing} allow-discrete`
    clearTimeout(this.transitionTimer)
    this.transitionTimer = setTimeout(() => {
      this.element.style.transition = ""
      this.element.style.willChange = ""
      this.element.style.removeProperty("--lc-sheet-duration")
    }, sheetDuration(this.element))
  }

  later(callback) {
    clearTimeout(this.settleTimer)
    this.settleTimer = setTimeout(callback, sheetDuration(this.element))
  }

  get offscreenGap() {
    return parseFloat(getComputedStyle(document.documentElement).fontSize) * 2
  }

  resetSurface() {
    const style = this.element.style
    style.transition = ""
    style.transform = ""
    style.willChange = ""
    style.blockSize = ""
    style.removeProperty("--lc-sheet-floor")
    style.removeProperty("--lc-sheet-duration")
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

  get isShown() {
    if (this.isDialog) return this.element.open
    return (
      this.element.hasAttribute("data-open") ||
      (supportsTopLayer() && this.element.matches(":popover-open"))
    )
  }

  get isSheet() {
    return isSheetViewport()
  }
}

function swallowNextClick() {
  const swallow = (event) => {
    event.preventDefault()
    event.stopImmediatePropagation()
  }
  window.addEventListener("click", swallow, { capture: true, once: true })
  setTimeout(() => window.removeEventListener("click", swallow, { capture: true }), 0)
}
