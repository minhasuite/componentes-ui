module Ss
  # Entrar com o Google (v0.19, par do SsGoogleButton): o botão de contorno com o "G" de quatro cores
  # (as cores são da marca Google, ficam aqui e não no produto) que faz o POST para o OmniAuth.
  #
  #   render Ss::GoogleButtonComponent.new(href: user_google_oauth2_omniauth_authorize_path)
  #   render Ss::GoogleButtonComponent.new(href: …, label: "Cadastrar com o Google")
  #
  # label: padrão "Entrar com o Google" (componentes_ui.google.sign_in). method: :post (padrão; o
  # omniauth-rails_csrf_protection exige POST com o token); :get vira link. Sem Turbo (data-turbo=false),
  # porque o OmniAuth redireciona para fora. Ocupa a largura toda.
  #
  # v0.20: mode: :gis usa o Google Identity Services (o botão oficial do Google num iframe, sem o OmniAuth):
  #   render Ss::GoogleButtonComponent.new(mode: :gis, client_id: ENV["GOOGLE_CLIENT_ID"], login_uri: auth_google_url)
  #   render Ss::GoogleButtonComponent.new(mode: :gis, client_id: …, callback: "entrarComGoogle")  (função JS global)
  # Gera o g_id_onload + g_id_signin (data-client_id, data-login_uri ou data-callback) e carrega o
  # https://accounts.google.com/gsi/client (script: false se o layout já carrega; com nonce do CSP). O POST do
  # login_uri traz credential e g_csrf_token (confira os dois no servidor). Visual da gem por fora: pílula,
  # largura do contêiner (width:, padrão 400, o máximo do Google), texto no idioma da página (locale:),
  # theme: :outline (padrão) ou :filled_black/:filled_blue; text: :signin_with (padrão), :signup_with,
  # :continue_with. one_tap: true mostra também o One Tap. O desenho dentro do iframe é do Google.
  class GoogleButtonComponent < BaseComponent
    GIS_SRC = "https://accounts.google.com/gsi/client".freeze
    G = '<svg viewBox="0 0 24 24" class="ss-google-g" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false">' \
        '<path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/>' \
        '<path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>' \
        '<path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>' \
        '<path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>'.freeze

    def initialize(href: nil, label: nil, method: :post, mode: :redirect, client_id: nil, login_uri: nil, callback: nil,
                   theme: :outline, text: :signin_with, width: 400, locale: nil, one_tap: false, script: true, **rest)
      super(**rest)
      @href, @method = href, method.to_s.downcase
      @label = label || ss_t("google.sign_in", default: "Entrar com o Google")
      @gis = mode.to_s == "gis"
      @client_id, @login_uri, @callback, @theme, @text, @width = client_id, login_uri, callback, theme, text, width
      @locale, @one_tap, @script = locale, one_tap, script
      raise ArgumentError, "GoogleButtonComponent: href: required (or mode: :gis with client_id:)" if !@gis && @href.blank?
      raise ArgumentError, "GoogleButtonComponent(mode: :gis): client_id: and login_uri: or callback: required" if @gis && (@client_id.blank? || (@login_uri.blank? && @callback.blank?))
    end

    def call
      return gis if @gis

      body = safe_join([G.html_safe, tag.span(@label)])
      css = classes("ss-btn", "ss-btn-outline", "ss-google-btn")
      return link_to(@href, **root_attrs(class: css, data: { turbo: false })) { body } if @method == "get"

      button_to(@href, **root_attrs(class: css, data: { turbo: false }), method: @method.to_sym,
                                                                       form: { class: "ss-google-form", data: { turbo: false } }) { body }
    end

    private

    # Os data-* do GIS têm sublinhado (data-client_id): montados à mão, sem o dasherize do Rails.
    def gis
      onload = { "id" => "g_id_onload", "data-client_id" => @client_id, "data-login_uri" => @login_uri.presence,
                 "data-callback" => @callback.presence, "data-auto_prompt" => @one_tap.to_s, "data-itp_support" => "true",
                 "data-context" => (@text.to_s == "signup_with" ? "signup" : "signin") }.compact
      signin = { "class" => "g_id_signin", "data-type" => "standard", "data-shape" => "pill", "data-size" => "large",
                 "data-theme" => @theme.to_s, "data-text" => @text.to_s, "data-logo_alignment" => "center",
                 "data-width" => @width.to_i.clamp(200, 400).to_s, "data-locale" => (@locale || I18n.locale).to_s }
      tag.div(**root_attrs(class: classes("ss-google-gis"), "aria-label": @label, role: "group")) do
        safe_join([
          (tag.script(src: GIS_SRC, async: true, defer: true, nonce: (content_security_policy_nonce rescue nil)) if @script),
          tag.div(**onload.transform_keys(&:to_sym)),
          tag.div(**signin.transform_keys(&:to_sym))
        ].compact)
      end
    end
  end
end
