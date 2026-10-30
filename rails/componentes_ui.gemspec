require_relative "lib/componentes_ui/version"

Gem::Specification.new do |spec|
  spec.name = "componentes_ui"
  spec.version = ComponentesUi::VERSION
  spec.authors = ["MinhaSuite"]
  spec.summary = "Design system Lista Clara da MinhaSuite para Rails + Tailwind 4"
  spec.homepage = "https://github.com/minhasuite/componentes-ui"
  spec.license = "Nenhuma (uso interno)"
  spec.required_ruby_version = ">= 3.3"
  spec.files = Dir["app/**/*", "lib/**/*"]
  spec.add_dependency "railties", ">= 8.0"
  spec.add_dependency "tailwindcss-rails", ">= 4.2"
end
