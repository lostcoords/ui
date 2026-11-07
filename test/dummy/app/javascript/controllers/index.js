import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
import { application } from "controllers/application"
import ScrollKeeper from "controllers/lc_scroll_keeper_controller"

// The sidebar's scroll keeper registers up front, so a reload restores the position before the first paint
// rather than after a lazy download.
application.register("lc-scroll-keeper", ScrollKeeper)

// Every other controller, the library's included, downloads when its data-controller first appears.
lazyLoadControllersFrom("controllers", application)
