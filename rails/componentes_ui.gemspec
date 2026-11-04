require_relative "lib/componentes_ui/version"

Gem::Specification.new do |spec|
  spec.name = "componentes_ui"
  spec.version = ComponentesUi::VERSION
  spec.authors = ["MinhaSuite"]
  spec.summary = "Design system Lista Clara da MinhaSuite para Rails + Tailwind 4"
  spec.homepage = "https://github.com/minhasuite/componentes-ui"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 3.3"
  spec.files = Dir["app/**/*", "lib/**/*", "config/**/*"]
  spec.add_dependency "railties", ">= 8.0"
  spec.add_dependency "tailwindcss-rails", ">= 4.2"
  # Componentes de tela (Ss::*Component) desde a v0.9.
  spec.add_dependency "view_component", ">= 3.9"
end
