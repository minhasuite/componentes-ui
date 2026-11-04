require "componentes_ui/version"
require "componentes_ui/paletas"
require "rails/engine"
require "view_component"
require "componentes_ui/helpers"
require "componentes_ui/form_builder"
require "componentes_ui/form_helpers"

module ComponentesUi
  # O tailwindcss-rails acha app/assets/tailwind/componentes_ui/engine.css e gera
  # app/assets/builds/tailwind/componentes_ui.css no app. Os helpers (ss_amount,
  # ss_sparkline, ss_rings, ss_avatar, ss_form_with) entram em todas as views.
  #
  # v0.9: componentes de tela em app/components/ss (Ss::*Component, ViewComponent)
  # e controllers Stimulus em app/javascript/componentes_ui/controllers, que o app
  # liga com eagerLoadControllersFrom("componentes_ui/controllers", application).
  class Engine < ::Rails::Engine
    engine_name "componentes_ui"

    initializer "componentes_ui.helpers" do
      ActiveSupport.on_load(:action_view) { include ComponentesUi::Helpers; include ComponentesUi::FormHelpers }
    end

    initializer "componentes_ui.assets" do |app|
      app.config.assets.paths << root.join("app/javascript") if app.config.respond_to?(:assets)
    end

    initializer "componentes_ui.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app/javascript")
      end
    end
  end
end
