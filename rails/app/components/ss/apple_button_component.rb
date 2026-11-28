module Ss
  # Entrar com a Apple (v1.11.0, par do SsAppleButton): o logo da Apple e o texto, no desenho das Human
  # Interface Guidelines: preto (style: :black, padrão), branco (:white, sobre fundo escuro) ou branco com
  # contorno (:outline). As cores preta e branca são as da Apple, não as da paleta do produto. Mesma altura e
  # raio do Ss::GoogleButtonComponent. Só o botão: a entrada (Sign in with Apple JS ou o OmniAuth) é do produto.
  #
  #   render Ss::AppleButtonComponent.new(href: user_apple_omniauth_authorize_path)        # POST, "Continuar com a Apple"
  #   render Ss::AppleButtonComponent.new(href: …, label: :sign_in, style: :outline)        # "Entrar com a Apple"
  #   render Ss::AppleButtonComponent.new(id: "entrar-apple", data: { action: "apple#entrar" })   # botão do JS
  #   render Ss::AppleButtonComponent.new(href: …, compact: true)                           # só o logo, ao lado do G
  #
  # label: :continue (padrão, componentes_ui.apple.continue), :sign_in (componentes_ui.apple.sign_in) ou o
  # texto. method: :post (padrão; o OmniAuth exige POST com o token) ou :get (link). Sem href:, é um
  # <button type=button> para o AppleID.auth.signIn() do Sign in with Apple JS (o produto carrega o script e
  # liga o clique; data: e id: vão no botão). Sem Turbo (data-turbo=false), porque a Apple redireciona para
  # fora. compact: true é o quadrado só com o logo (o nome vai no aria-label e no title). Ocupa a largura toda.
  class AppleButtonComponent < BaseComponent
    STYLES = %i[black white outline].freeze
    # Origem do logo: o ícone "Apple" do Simple Icons (simpleicons.org). v1.14.2: o oficial ("Sign in with Apple
    # Logo", developer.apple.com/design/resources) vem sob a Apple Design Resources License, que proíbe embutir
    # em software, redistribuir e usar fora de sistema da Apple; a gem é pública e roda no web. Ver o README.
    LOGO_PATH = "M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 " \
                "1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 " \
                "1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857" \
                "-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 " \
                "3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 " \
                "1.338.104 2.715-.688 3.559-1.701".freeze
    LOGO = %(<svg viewBox="0 0 24 24" class="ss-apple-logo" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" ) +
           %(focusable="false"><path fill="currentColor" d="#{LOGO_PATH}"/></svg>).freeze

    def initialize(href: nil, label: :continue, style: :black, method: :post, compact: false, **rest)
      super(**rest)
      @href, @method, @compact = href, method.to_s.downcase, compact
      @style = STYLES.include?(style.to_s.to_sym) ? style.to_s.to_sym : :black
      @label = case label.to_s
               when "continue" then ss_t("apple.continue", default: "Continuar com a Apple")
               when "sign_in" then ss_t("apple.sign_in", default: "Entrar com a Apple")
               else label.to_s
               end
    end

    attr_reader :label

    def call
      css = classes("ss-btn", "ss-apple-btn", "is-#{@style}", ("is-compact" if @compact))
      body = safe_join([LOGO.html_safe, (@compact ? nil : tag.span(@label))].compact)
      extra = @compact ? { "aria-label": @label, title: @label } : {}
      return tag.button(**root_attrs(type: "button", class: css, **extra)) { body } if @href.blank?
      return link_to(@href, **root_attrs(class: css, data: { turbo: false }, **extra)) { body } if @method == "get"

      button_to(@href, **root_attrs(class: css, data: { turbo: false }, **extra), method: @method.to_sym,
                                                                                form: { class: "ss-apple-form", data: { turbo: false } }) { body }
    end
  end
end
