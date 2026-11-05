import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
import { application } from "controllers/application"

// Each controller, the library's included, downloads when its data-controller first appears.
lazyLoadControllersFrom("controllers", application)
