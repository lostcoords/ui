import AppHeader from "lostcoords/ui/controllers/lc_app_header_controller"
import CharCounter from "lostcoords/ui/controllers/lc_char_counter_controller"
import CodeBlock from "lostcoords/ui/controllers/lc_code_block_controller"
import Collapsible from "lostcoords/ui/controllers/lc_collapsible_controller"
import Copy from "lostcoords/ui/controllers/lc_copy_controller"
import Dialog from "lostcoords/ui/controllers/lc_dialog_controller"
import Dock from "lostcoords/ui/controllers/lc_dock_controller"
import EmojiPicker from "lostcoords/ui/controllers/lc_emoji_picker_controller"
import Kbd from "lostcoords/ui/controllers/lc_kbd_controller"
import Menu from "lostcoords/ui/controllers/lc_menu_controller"
import Nav from "lostcoords/ui/controllers/lc_nav_controller"
import Popover from "lostcoords/ui/controllers/lc_popover_controller"
import ScrollKeeper from "lostcoords/ui/controllers/lc_scroll_keeper_controller"
import Search from "lostcoords/ui/controllers/lc_search_controller"
import Selection from "lostcoords/ui/controllers/lc_selection_controller"
import Sheet from "lostcoords/ui/controllers/lc_sheet_controller"
import Shortcut from "lostcoords/ui/controllers/lc_shortcut_controller"
import Sidebar from "lostcoords/ui/controllers/lc_sidebar_controller"
import Tabs from "lostcoords/ui/controllers/lc_tabs_controller"
import Toast from "lostcoords/ui/controllers/lc_toast_controller"
import ToastRegion from "lostcoords/ui/controllers/lc_toast_region_controller"
import Toc from "lostcoords/ui/controllers/lc_toc_controller"
import Toggle from "lostcoords/ui/controllers/lc_toggle_controller"
import Tooltip from "lostcoords/ui/controllers/lc_tooltip_controller"

const controllers = {
  "lc-app-header": AppHeader,
  "lc-char-counter": CharCounter,
  "lc-collapsible": Collapsible,
  "lc-code-block": CodeBlock,
  "lc-copy": Copy,
  "lc-dialog": Dialog,
  "lc-dock": Dock,
  "lc-emoji-picker": EmojiPicker,
  "lc-kbd": Kbd,
  "lc-menu": Menu,
  "lc-nav": Nav,
  "lc-popover": Popover,
  "lc-scroll-keeper": ScrollKeeper,
  "lc-search": Search,
  "lc-selection": Selection,
  "lc-sheet": Sheet,
  "lc-shortcut": Shortcut,
  "lc-sidebar": Sidebar,
  "lc-tabs": Tabs,
  "lc-toc": Toc,
  "lc-toast": Toast,
  "lc-toast-region": ToastRegion,
  "lc-toggle": Toggle,
  "lc-tooltip": Tooltip,
}
const registrations = new WeakMap()

export function registerControllers(application, { only = Object.keys(controllers) } = {}) {
  if (!Array.isArray(only)) throw new TypeError("only must be an array of controller identifiers")
  for (const identifier of only) {
    if (!Object.hasOwn(controllers, identifier)) {
      throw new Error(`Unknown lostcoords-ui controller: ${identifier}`)
    }
  }
  let registered = registrations.get(application)
  if (!registered) {
    registered = new Set()
    registrations.set(application, registered)
  }
  for (const identifier of only) {
    if (registered.has(identifier)) continue
    application.register(identifier, controllers[identifier])
    registered.add(identifier)
  }
}
