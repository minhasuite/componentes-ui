require "componentes_ui/version"
require "rails/engine"

module ComponentesUi
  # Só existe para o tailwindcss-rails achar app/assets/tailwind/componentes_ui/engine.css
  # e gerar app/assets/builds/tailwind/componentes_ui.css no app.
  class Engine < ::Rails::Engine
    engine_name "componentes_ui"
  end
end
