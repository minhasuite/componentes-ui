# Controllers Stimulus da gem: o app chama
#   eagerLoadControllersFrom("componentes_ui/controllers", application)
# e cada arquivo ss_x_controller.js vira data-controller="ss-x".
pin_all_from ComponentesUi::Engine.root.join("app/javascript/componentes_ui/controllers"),
  under: "componentes_ui/controllers", to: "componentes_ui/controllers"
