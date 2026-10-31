require "componentes_ui/version"
require "rails/engine"
require "componentes_ui/helpers"

module ComponentesUi
  # O tailwindcss-rails acha app/assets/tailwind/componentes_ui/engine.css e gera
  # app/assets/builds/tailwind/componentes_ui.css no app. Os helpers (ss_amount,
  # ss_sparkline, ss_rings, ss_avatar) entram em todas as views.
  class Engine < ::Rails::Engine
    engine_name "componentes_ui"

    initializer "componentes_ui.helpers" do
      ActiveSupport.on_load(:action_view) { include ComponentesUi::Helpers }
    end
  end
end
