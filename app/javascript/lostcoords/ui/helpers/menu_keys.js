const ITEMS = '[role^="menuitem"]:not([disabled]):not([aria-disabled="true"])'

function items(menu) {
  return [...menu.querySelectorAll(ITEMS)].filter((item) => item.getClientRects().length > 0)
}

export function focusFirstMenuItem(menu) {
  items(menu)[0]?.focus()
}

// The ARIA menu pattern: arrows move between items and wrap, Home/End jump.
export function navigateMenu(event, menu) {
  const list = items(menu)
  if (list.length === 0) return

  const index = list.indexOf(document.activeElement)
  const next = {
    ArrowDown: (index + 1) % list.length,
    ArrowUp: (index - 1 + list.length) % list.length,
    Home: 0,
    End: list.length - 1,
  }[event.key]
  if (next === undefined) return

  event.preventDefault()
  list[next].focus()
}
