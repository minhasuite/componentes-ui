require "componentes_ui/version"
require "componentes_ui/paletas"
require "rails/engine"
require "view_component"
require "componentes_ui/helpers"
require "componentes_ui/form_builder"
require "componentes_ui/form_helpers"

module ComponentesUi
  # Configuração da gem (v0.10). No app, num initializer:
  #   ComponentesUi.configure { |c| c.currency = "EUR"; c.locale = :"pt-BR" }
  # - currency: moeda ISO 4217 dos helpers de dinheiro (ss_money), do
  #   Ss::MoneyInputComponent, do CountUp (format: :money) e do DataTable (format: :money).
  # - locale: idioma dos números e do dinheiro; nil segue o I18n.locale da página.
  # - density (v0.11): densidade padrão do produto, "compact", "standard" (padrão) ou
  #   "comfortable". Sai no <html> por ss_density_attrs; o usuário troca pelo
  #   Ss::DensityPickerComponent (guardado no navegador, chave ss-density).
  Config = Struct.new(:currency, :locale, :density, keyword_init: true)

  # Densidades na ordem do seletor (o mesmo SsDensity.values do Flutter).
  DENSITIES = %w[compact standard comfortable].freeze

  def self.config = @config ||= Config.new(currency: "BRL", locale: nil, density: "standard")

  def self.configure = yield(config)

  HEX = /\A#\h{6}\z/

  # v0.18: um nome de tom só para a gem toda. "warning" (o do ss_status antigo e de quem vem do
  # Bootstrap) vira "warn" (o de Callout, Note, CardHeader, ProgressRow); "error" vira "danger",
  # "ok" vira "success", "neutral"/"default" viram "muted". O resto passa como veio (símbolo).
  TONE_ALIASES = { warning: :warn, error: :danger, ok: :success, neutral: :muted, default: :muted }.freeze

  def self.tone(value)
    t = value.to_s.strip.downcase.to_sym
    TONE_ALIASES.fetch(t, t)
  end

  # v0.13: variáveis CSS da marca a partir de uma ou duas cores (#rrggbb): o que um tema de
  # usuário, um painel ou um cliente com a própria cor põe no style= de um trecho. Mesmas
  # misturas do SsBrand.fromColors (Flutter). accent2 nulo = a própria accent. Inválida = nil.
  def self.brand_css(accent, accent2 = nil)
    a = accent.to_s.downcase
    b = (accent2.presence || accent).to_s.downcase
    return nil unless a.match?(HEX) && b.match?(HEX)

    ["--accent: #{a}", "--accent-solid: #{a}", "--accent-hover: color-mix(in srgb, #{a} 86%, #000)",
     "--accent2: #{b}", "--accent-soft: color-mix(in srgb, #{a} 14%, var(--surface))",
     "--grad: linear-gradient(135deg, #{a} 0%, #{b} 100%)", "--glow: color-mix(in srgb, #{a} 16%, transparent)",
     "--ring: color-mix(in srgb, #{a} 22%, transparent)"].join("; ")
  end

  # O tailwindcss-rails acha app/assets/tailwind/componentes_ui/engine.css e gera
  # app/assets/builds/tailwind/componentes_ui.css no app. Os helpers (ss_amount,
  # ss_sparkline, ss_rings, ss_avatar, ss_form_with) entram em todas as views.
  #
  # v0.9: componentes de tela em app/components/ss (Ss::*Component, ViewComponent)
  # e controllers Stimulus em app/javascript/componentes_ui/controllers, que o app
  # liga com eagerLoadControllersFrom("componentes_ui/controllers", application).
  class Engine < ::Rails::Engine
    engine_name "componentes_ui"

    # Textos dos componentes em pt-BR, en e es (config/locales/componentes_ui.*.yml),
    # sob a chave componentes_ui.*. O app pode sobrescrever qualquer chave no locale dele
    # (o load_path do app vem depois do da engine). Sem os arquivos, vale o default pt-BR.
    # (A engine já somaria config/locales sozinha; fica explícito para não depender disso.)
    config.i18n.load_path += Dir[File.expand_path("../config/locales/*.yml", __dir__)]

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
