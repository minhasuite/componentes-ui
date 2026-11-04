import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
// Controllers da gem componentes_ui (data-controller="ss-*").
eagerLoadControllersFrom("componentes_ui/controllers", application)
