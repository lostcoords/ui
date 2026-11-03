// Floating panels (menus, pickers) open in the browser's top layer so no
// stacking context or overflow clip can paint over them: every <section> is
// its own stacking context, so a z-index alone can never lift a menu above the
// next section, and a menu opened inside a <dialog> must clear the dialog too.
//
// The panel's stylesheet still decides where it sits. The caller makes the
// panel visible in place, liftToTopLayer measures that designed spot relative
// to its trigger, then re-pins it there as a fixed top-layer popover, follows
// the trigger on scroll and resize, and flips above when it would leave the
// viewport. Browsers without the Popover API keep the in-place panel.

const MARGIN = 8
const PLACEMENT = ["position", "inset", "top", "left", "margin", "translate", "inlineSize"]

const lifts = new WeakMap()
const pinned = new WeakSet()

export function liftToTopLayer(panel, trigger) {
  if (typeof panel.showPopover !== "function") return () => {}

  lifts.get(panel)?.()
  if (pinned.has(panel)) reset(panel)

  const anchor = trigger.getBoundingClientRect()
  const placed = panel.getBoundingClientRect()
  const offsetX = placed.left - anchor.left
  const offsetY = placed.top - anchor.top
  const gap = placed.top - anchor.bottom

  panel.setAttribute("popover", "manual")
  panel.showPopover()
  Object.assign(panel.style, {
    position: "fixed",
    inset: "auto",
    margin: "0",
    translate: "none",
    inlineSize: `${placed.width}px`,
  })
  pinned.add(panel)

  let frame = null
  const place = () => {
    frame = null
    const a = trigger.getBoundingClientRect()
    const width = panel.offsetWidth
    const height = panel.offsetHeight
    const { top: minTop, bottom: maxBottom } = visibleBounds(trigger)
    const right = document.documentElement.clientWidth - MARGIN

    let top = a.top + offsetY
    const flipped = a.top - gap - height
    if (top + height > maxBottom - MARGIN && flipped >= minTop + MARGIN) top = flipped
    top = Math.max(minTop + MARGIN, Math.min(top, maxBottom - MARGIN - height))

    panel.style.left = `${Math.max(MARGIN, Math.min(a.left + offsetX, right - width))}px`
    panel.style.top = `${top}px`
  }
  const schedule = () => (frame ??= requestAnimationFrame(place))

  place()
  const resizes = new ResizeObserver(schedule)
  resizes.observe(panel)
  window.addEventListener("scroll", schedule, { capture: true, passive: true })
  window.addEventListener("resize", schedule, { passive: true })

  const release = ({ immediate = false } = {}) => {
    if (lifts.get(panel) !== release) return
    lifts.delete(panel)
    if (frame) cancelAnimationFrame(frame)
    resizes.disconnect()
    window.removeEventListener("scroll", schedule, { capture: true })
    window.removeEventListener("resize", schedule)
    if (immediate) return reset(panel)

    // Keep the pinned spot while the closing transition plays out, then hand
    // the panel back to its stylesheet unless it has been lifted again.
    Promise.allSettled(panel.getAnimations().map((animation) => animation.finished)).then(() => {
      if (!lifts.has(panel)) reset(panel)
    })
    if (panel.matches(":popover-open")) panel.hidePopover()
  }
  lifts.set(panel, release)
  return release
}

function reset(panel) {
  pinned.delete(panel)
  if (panel.matches(":popover-open")) panel.hidePopover()
  panel.removeAttribute("popover")
  for (const property of PLACEMENT) panel.style[property] = ""
}

// Chrome floating over the bottom of the page ([data-top-layer-floor], a phone
// nav) acts as the floor: a panel that would open under it flips or tucks above.
function visibleBounds(trigger) {
  let bottom = window.innerHeight
  const floor = document.querySelector("body > [data-top-layer-floor]")
  if (floor?.offsetParent && !floor.contains(trigger))
    bottom = Math.min(bottom, floor.getBoundingClientRect().top)

  return { top: 0, bottom }
}
