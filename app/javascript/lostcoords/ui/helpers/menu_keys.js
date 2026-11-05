import { navigableItems, navigate } from "lostcoords/ui/helpers/roving_focus"

const ITEMS = '[role^="menuitem"]'

export function menuItems(menu) {
  return navigableItems(menu.querySelectorAll(ITEMS))
}

export function focusFirstMenuItem(menu) {
  menuItems(menu)[0]?.focus()
}

export function focusLastMenuItem(menu) {
  menuItems(menu).at(-1)?.focus()
}

// The ARIA menu pattern: arrows move between items and wrap, Home/End jump,
// typing a letter jumps to the next item that starts with it, and Space
// activates a link item as Enter does.
export function navigateMenu(event, menu, { orientation = "vertical" } = {}) {
  if (event.key === " " && event.target.matches(`a${ITEMS}`)) {
    event.preventDefault()
    event.target.click()
    return
  }

  navigate(event, menuItems(menu), { orientation, wrap: true, typeahead: true })
}
