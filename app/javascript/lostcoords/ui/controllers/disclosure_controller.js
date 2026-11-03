import { Controller } from "@hotwired/stimulus"
import { prefersReducedMotion } from "helpers/viewport"

// Animates a <details> both ways and keeps what it reveals on screen. Only
// user toggles go through here: programmatic opens (validation) already scroll
// to the field they care about. Durations live in ui/disclosure.css.
export default class extends Controller {
  // Where the panel's height can't ease to `auto` in CSS (Safari), ease the
  // <details> itself between measured heights.
  static easesHeightInCss = CSS.supports("interpolate-size: allow-keywords")

  disconnect() {
    this.stopFollowing()
    this.stopClosing()
  }

  toggle(event) {
    if (event.target.closest("summary")?.parentElement !== this.element) return

    if (this.element.hasAttribute("data-closing")) {
      event.preventDefault()
      this.stopClosing()
    } else if (this.element.open) {
      event.preventDefault()
      this.close()
    } else {
      if (!this.constructor.easesHeightInCss) {
        event.preventDefault()
        this.openWithHeight()
      }
      this.reveal()
    }
  }

  openWithHeight() {
    const from = this.element.offsetHeight
    const duration = this.transitionDurations()[0]
    this.element.open = true
    const animation = this.animateHeight(
      from,
      this.element.offsetHeight,
      duration,
      "--ease-out-expo",
    )
    animation.finished.then(
      () => animation.cancel(),
      () => {},
    )
  }

  // Removing [open] hides the content at once, so play the exit
  // ([data-closing]) while it's still open, then close.
  close() {
    this.stopFollowing()
    this.element.toggleAttribute("data-closing", true)
    const duration = Math.max(...this.transitionDurations())
    if (!this.constructor.easesHeightInCss) {
      this.animateHeight(this.element.offsetHeight, this.closedHeight(), duration, "--ease-out")
    }
    this.closeTimeout = setTimeout(() => {
      this.element.open = false
      this.stopClosing()
    }, duration)
  }

  stopClosing() {
    clearTimeout(this.closeTimeout)
    this.element.removeAttribute("data-closing")
    this.heightAnimation?.cancel()
  }

  animateHeight(from, to, duration, easingProperty) {
    this.heightAnimation?.cancel()
    const easing =
      getComputedStyle(this.element).getPropertyValue(easingProperty).trim() || "ease-out"
    this.heightAnimation = this.element.animate(
      { height: [`${from}px`, `${to}px`], overflow: ["clip", "clip"] },
      { duration, easing, fill: "forwards" },
    )
    return this.heightAnimation
  }

  closedHeight() {
    const style = getComputedStyle(this.element)
    const chrome = ["paddingTop", "paddingBottom", "borderTopWidth", "borderBottomWidth"].reduce(
      (sum, property) => sum + parseFloat(style[property]),
      0,
    )
    return this.element.querySelector(":scope > summary").offsetHeight + chrome
  }

  transitionDurations() {
    return getComputedStyle(this.element, "::details-content")
      .transitionDuration.split(",")
      .map((duration) => parseFloat(duration) * 1000)
  }

  // Opening near the bottom of a scroller grows content off-screen, so the
  // user sees nothing happen. Scroll just enough to show it, never so far that
  // the summary leaves the top.
  reveal() {
    this.stopFollowing()
    // A native toggle applies [open] after this handler; measure next frame.
    requestAnimationFrame(() => {
      if (!this.element.open) return

      const scroller = this.scrollParent()
      const distance = this.distanceToReveal(scroller)
      if (distance <= 0) return

      this.followGrowth(scroller, scroller.scrollTop + distance)
    })
  }

  // The scroller can only go as far as the panel has grown, so a single
  // smooth scroll would stop short. Follow each frame of growth instead; the
  // scroll then rides the panel's own easing.
  followGrowth(scroller, target) {
    const reduceMotion = prefersReducedMotion()
    if (scroller.scrollHeight - scroller.clientHeight >= target) {
      scroller.scrollTo({ top: target, behavior: reduceMotion ? "instant" : "smooth" })
      return
    }

    this.follower = new ResizeObserver(() => {
      const reachable = scroller.scrollHeight - scroller.clientHeight
      scroller.scrollTo({ top: Math.min(reachable, target), behavior: "instant" })
      if (reachable >= target) this.stopFollowing()
    })
    this.follower.observe(this.element)
    this.followTimeout = setTimeout(() => this.stopFollowing(), 800)
  }

  stopFollowing() {
    this.follower?.disconnect()
    this.follower = null
    clearTimeout(this.followTimeout)
  }

  // The content lays out at full size even while its height animates from 0,
  // so its last child already marks where the open panel will end.
  distanceToReveal(scroller) {
    const content = this.element.querySelector(":scope > :last-child")
    const style = getComputedStyle(scroller)
    const view =
      scroller === document.scrollingElement
        ? { top: 0, bottom: window.innerHeight }
        : scroller.getBoundingClientRect()
    const visibleTop = view.top + (parseFloat(style.scrollPaddingBlockStart) || 0)
    const visibleBottom = view.bottom - (parseFloat(style.scrollPaddingBlockEnd) || 0)

    const overflow = content.getBoundingClientRect().bottom + 12 - visibleBottom
    const room = this.element.getBoundingClientRect().top - visibleTop
    return Math.min(overflow, room)
  }

  scrollParent() {
    for (let node = this.element.parentElement; node; node = node.parentElement) {
      if (/(auto|scroll)/.test(getComputedStyle(node).overflowY)) return node
    }
    return document.scrollingElement
  }
}
