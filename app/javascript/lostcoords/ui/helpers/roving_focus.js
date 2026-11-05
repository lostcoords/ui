// Arrow-key navigation shared by every list, toolbar and grid in the library.
//
// orientation:
//   "vertical"   ArrowUp/ArrowDown move through the items in order.
//   "horizontal" ArrowLeft/ArrowRight do, flipped in right-to-left text.
//   "both"       All four arrows do, for toolbars that wrap onto two lines.
//   "grid"       Items laid out in rows (flow: "row") or columns (flow: "column").
//                Arrows along the flow move in order; arrows across it move to
//                the nearest item in the next row or column, by position on screen.
// wrap:      the ends lead back round to the other end. Grids never wrap.
// typeahead: typing a letter moves to the next item whose label starts with it.
//
// navigate() moves focus and returns the item it moved to, or null when the key
// is not one it handles. rove() keeps a single Tab stop on the current item.

const TYPEAHEAD_RESET = 500
const typeaheads = new WeakMap()

export function navigableItems(items) {
  return [...items].filter(
    (item) =>
      !item.disabled &&
      item.getAttribute("aria-disabled") !== "true" &&
      !item.closest("[inert]") &&
      item.getClientRects().length > 0,
  )
}

export function rove(items, current) {
  for (const item of items) item.tabIndex = item === current ? 0 : -1
}

export function navigate(
  event,
  items,
  {
    orientation = "vertical",
    flow = "row",
    wrap = orientation !== "grid",
    typeahead = false,
    label = defaultLabel,
    focus = true,
  } = {},
) {
  if (event.defaultPrevented || event.isComposing || event.altKey || event.metaKey) return null

  const list = navigableItems(items)
  if (list.length === 0) return null

  const index = list.findIndex((item) => item === event.target || item.contains(event.target))
  const editing = isEditable(event.target)
  let target = null

  if (event.key === "Home" || event.key === "End") {
    if (editing) return null
    if (event.ctrlKey && orientation !== "grid") return null
    target = event.key === "Home" ? list[0] : list.at(-1)
  } else if (event.key.startsWith("Arrow")) {
    if (event.ctrlKey) return null
    if (editing && (event.key === "ArrowLeft" || event.key === "ArrowRight")) return null
    target = arrowTarget(event.key, list, index, {
      orientation,
      flow,
      wrap,
      rtl: isRtl(event.target),
    })
  } else if (typeahead && !editing && !event.ctrlKey) {
    target = typeaheadTarget(event.key, list, index, label)
  }

  if (!target) return null
  event.preventDefault()
  if (focus) target.focus()
  return target
}

function arrowTarget(key, list, index, { orientation, flow, wrap, rtl }) {
  const vertical = key === "ArrowUp" || key === "ArrowDown"
  const forward = key === "ArrowDown" || key === (rtl ? "ArrowLeft" : "ArrowRight")

  if (orientation === "vertical" && !vertical) return null
  if (orientation === "horizontal" && vertical) return null
  if (orientation === "grid" && vertical !== (flow === "column")) {
    return index < 0 ? list[0] : nearestAcross(list, list[index], key)
  }

  if (index < 0) return forward ? list[0] : list.at(-1)
  const next = index + (forward ? 1 : -1)
  if (next >= 0 && next < list.length) return list[next]
  if (!wrap) return null
  return list[(next + list.length) % list.length]
}

// The nearest row (or column) in the arrow's direction first, then the item in
// it closest to the current one, so a short last row still has a landing spot.
function nearestAcross(list, from, key) {
  const vertical = key === "ArrowUp" || key === "ArrowDown"
  const sign = key === "ArrowDown" || key === "ArrowRight" ? 1 : -1
  const origin = centre(from.getBoundingClientRect())
  const reach = (vertical ? from.offsetHeight : from.offsetWidth) / 2

  const ahead = []
  for (const item of list) {
    if (item === from) continue
    const point = centre(item.getBoundingClientRect())
    const along = (vertical ? point.y - origin.y : point.x - origin.x) * sign
    if (along < reach) continue
    ahead.push({
      item,
      along,
      across: Math.abs(vertical ? point.x - origin.x : point.y - origin.y),
    })
  }
  if (ahead.length === 0) return null

  const line = Math.min(...ahead.map((candidate) => candidate.along)) + reach
  const sameLine = ahead.filter((candidate) => candidate.along <= line)
  return sameLine.reduce((best, candidate) => (candidate.across < best.across ? candidate : best))
    .item
}

// Repeating one letter cycles through the items that start with it; typing a
// word quickly matches the whole prefix.
function typeaheadTarget(key, list, index, label) {
  if (key.length !== 1) return null

  const state = typeaheads.get(list[0].parentElement) ?? { text: "", timer: null }
  if (key === " " && state.text === "") return null

  clearTimeout(state.timer)
  state.text += key.toLocaleLowerCase()
  state.timer = setTimeout(() => {
    state.text = ""
  }, TYPEAHEAD_RESET)
  typeaheads.set(list[0].parentElement, state)

  const repeated = [...state.text].every((letter) => letter === state.text[0])
  const query = repeated ? state.text[0] : state.text
  const start = repeated ? index + 1 : Math.max(index, 0)
  for (let offset = 0; offset < list.length; offset++) {
    const item = list[(start + offset) % list.length]
    if (label(item).startsWith(query)) return item
  }
  return null
}

function defaultLabel(item) {
  return (item.getAttribute("aria-label") || item.textContent).trim().toLocaleLowerCase()
}

function centre(rect) {
  return { x: rect.left + rect.width / 2, y: rect.top + rect.height / 2 }
}

function isRtl(element) {
  return getComputedStyle(element).direction === "rtl"
}

export function isEditable(element) {
  if (!(element instanceof Element)) return false
  if (element.isContentEditable || element.tagName === "TEXTAREA" || element.tagName === "SELECT")
    return true
  if (element.tagName !== "INPUT") return false
  return ![
    "button",
    "checkbox",
    "radio",
    "range",
    "reset",
    "submit",
    "color",
    "file",
    "image",
  ].includes(element.type)
}
