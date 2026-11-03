import CodeBlock from "lostcoords/ui/controllers/lc_code_block_controller"
import Collapsible from "lostcoords/ui/controllers/lc_collapsible_controller"
import ConfirmDialog from "lostcoords/ui/controllers/lc_confirm_dialog_controller"
import Copy from "lostcoords/ui/controllers/lc_copy_controller"
import Dialog from "lostcoords/ui/controllers/lc_dialog_controller"
import EmojiPicker from "lostcoords/ui/controllers/lc_emoji_picker_controller"
import Menu from "lostcoords/ui/controllers/lc_menu_controller"
import Popover from "lostcoords/ui/controllers/lc_popover_controller"
import Selection from "lostcoords/ui/controllers/lc_selection_controller"
import Sheet from "lostcoords/ui/controllers/lc_sheet_controller"
import Tabs from "lostcoords/ui/controllers/lc_tabs_controller"
import Toast from "lostcoords/ui/controllers/lc_toast_controller"
import Toggle from "lostcoords/ui/controllers/lc_toggle_controller"
import Tooltip from "lostcoords/ui/controllers/lc_tooltip_controller"

const controllers = {
  "lc-confirm-dialog": ConfirmDialog,
  "lc-collapsible": Collapsible,
  "lc-code-block": CodeBlock,
  "lc-copy": Copy,
  "lc-dialog": Dialog,
  "lc-emoji-picker": EmojiPicker,
  "lc-menu": Menu,
  "lc-popover": Popover,
  "lc-selection": Selection,
  "lc-sheet": Sheet,
  "lc-tabs": Tabs,
  "lc-toast": Toast,
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
