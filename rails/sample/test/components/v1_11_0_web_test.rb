require "test_helper"

# v1.11.0 "adaptativa": o Ss::AppleButtonComponent (par do SsAppleButton), a linha de entrar com outra conta
# no Ss::AuthLayoutComponent (with_provider, par do SsAuthLayout(providers:)), o ss_platform (par do SsPlatform)
# e os três acertos da v1.10 (fundo do visor sem black, CurvedHeader escuro visível no tema escuro e as ondas do
# PulseAvatar no claro).
class V1110WebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)
  CSS = ROOT.join("app/assets/tailwind/componentes_ui")
  PARIDADE = YAML.load_file(ROOT.join("../paridade.yml"))

  def sem_comentarios(css) = css.gsub(%r{/\*.*?\*/}m, "")

  # ── paridade.yml ────────────────────────────────────────────────────
  test "paridade.yml: o botão da Apple, a linha de entrar e o SsPlatform" do
    assert_equal "Ss::AppleButtonComponent", PARIDADE["pares"]["SsAppleButton"]
    assert_equal "Ss::AuthLayoutComponent", PARIDADE["pares"]["SsAuthProviders"]
    assert_equal "helper:ss_platform", PARIDADE["apis"]["SsPlatform"]
    assert PARIDADE["so_app"].key?("SsPlatformScope")
    assert_equal({}, PARIDADE["divida"])
    assert_equal({}, PARIDADE["divida_app"])
  end

  # ── Botão da Apple ──────────────────────────────────────────────────
  test "padrão: POST sem Turbo, preto, o logo e Continuar com a Apple" do
    render_inline(Ss::AppleButtonComponent.new(href: "/auth/apple"))
    assert_selector "form.ss-apple-form[action='/auth/apple'][method=post][data-turbo=false]"
    assert_selector "button.ss-btn.ss-apple-btn.is-black[data-turbo=false]", text: "Continuar com a Apple"
    assert_selector ".ss-apple-btn svg.ss-apple-logo[aria-hidden=true] path[fill=currentColor]"
    assert_includes page.native.to_html, Ss::AppleButtonComponent::LOGO_PATH
  end

  test "sign_in, contorno, branco e link com GET" do
    render_inline(Ss::AppleButtonComponent.new(href: "/auth/apple", method: :get, label: :sign_in, style: :outline))
    assert_selector "a.ss-apple-btn.is-outline[href='/auth/apple'][data-turbo=false]", text: "Entrar com a Apple"
    render_inline(Ss::AppleButtonComponent.new(href: "/x", style: :white))
    assert_selector ".ss-apple-btn.is-white"
    render_inline(Ss::AppleButtonComponent.new(href: "/x", style: :roxo))
    assert_selector ".ss-apple-btn.is-black", text: "Continuar com a Apple"
  end

  test "sem href: botão do Sign in with Apple JS com id e data; texto livre" do
    render_inline(Ss::AppleButtonComponent.new(id: "apple", data: { action: "apple#entrar" }, label: "Cadastrar com a Apple"))
    assert_selector "button#apple.ss-apple-btn[type=button][data-action='apple#entrar']", text: "Cadastrar com a Apple"
    assert_no_selector "form"
  end

  test "compacto: só o logo, com o nome no aria-label e no title" do
    render_inline(Ss::AppleButtonComponent.new(href: "/x", method: :get, compact: true))
    assert_selector "a.ss-apple-btn.is-compact[aria-label='Continuar com a Apple'][title='Continuar com a Apple'] svg"
    assert_no_selector ".ss-apple-btn span"
  end

  test "idiomas: en e es" do
    I18n.with_locale(:en) do
      render_inline(Ss::AppleButtonComponent.new(href: "/x", label: :sign_in))
      assert_text "Sign in with Apple"
    end
    I18n.with_locale(:es) do
      render_inline(Ss::AppleButtonComponent.new(href: "/x"))
      assert_text "Continuar con Apple"
    end
  end

  test "CSS: importado, só tokens (o preto e o branco da Apple uma vez), foco e reduzir movimento" do
    assert_includes CSS.join("engine.css").read, '@import "./v1110_web.css";'
    css = sem_comentarios(CSS.join("v1110_web.css").read)
    cores = css.scan(/#[0-9a-f]{3,8}\b/i)
    assert_equal %w[#000 #fff], cores, "só o preto e o branco da Apple, nos tokens --ss-apple-*"
    assert_match(/--ss-apple-ink: #000; --ss-apple-paper: #fff;/, css)
    refute_match(/(?<![\w-])\d*\.?\d+m?s\b/, css.gsub(/var\([^)]*\)/, ""), "duração solta (use --ss-dur-*)")
    assert_includes css, ".ss-apple-btn:focus-visible"
    assert_includes css, "prefers-reduced-motion: reduce"
    assert_match(/\.ss-apple-btn \{[^}]*min-height: calc\(var\(--ss-control-h\) \+ \.25rem\)/, css)
  end

  # ── Entrada: with_provider ──────────────────────────────────────────
  test "auth layout: with_provider põe a linha embaixo do formulário; dois ficam lado a lado" do
    render_inline(Ss::AuthLayoutComponent.new(product: "Meu Financeiro", title: "Entrar", variant: :cartaz)) do |c|
      c.with_provider { render_inline_str(Ss::GoogleButtonComponent.new(href: "/g")) }
      c.with_provider { render_inline_str(Ss::AppleButtonComponent.new(href: "/a", compact: true)) }
      "formulário"
    end
    assert_selector ".ss-auth-body .ss-auth-providers.is-row .ss-google-btn"
    assert_selector ".ss-auth-body .ss-auth-providers.is-row .ss-apple-btn.is-compact"
    assert_text "formulário"
  end

  test "auth layout: um provider só ocupa a largura; sem provider, sem a linha" do
    render_inline(Ss::AuthLayoutComponent.new(product: "Meu Gestor", title: "Entrar")) do |c|
      c.with_provider { render_inline_str(Ss::AppleButtonComponent.new(href: "/a")) }
    end
    assert_selector ".ss-auth-providers:not(.is-row) .ss-apple-btn"
    render_inline(Ss::AuthLayoutComponent.new(product: "Meu Gestor", title: "Entrar")) { "x" }
    assert_no_selector ".ss-auth-providers"
  end

  test "CSS: a linha de entrar (grade; .is-row em flex, os compactos sem esticar)" do
    css = sem_comentarios(CSS.join("v1110_web.css").read)
    assert_match(/\.ss-auth-providers \{ display: grid;/, css)
    assert_match(/\.ss-auth-providers\.is-row \{ display: flex;/, css)
  end

  # ── ss_platform ─────────────────────────────────────────────────────
  test "ss_platform pelo User-Agent" do
    h = Class.new { include ComponentesUi::Helpers }.new
    assert_equal :ios, h.ss_platform(user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit")
    assert_equal :ios, h.ss_platform(user_agent: "Mozilla/5.0 (iPad; CPU OS 18_0 like Mac OS X)")
    assert_equal :android, h.ss_platform(user_agent: "Mozilla/5.0 (Linux; Android 15; Pixel 9)")
    assert_equal :mac, h.ss_platform(user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_0)")
    assert_equal :other, h.ss_platform(user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    assert_equal :other, h.ss_platform
    assert h.ss_apple_platform?(user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)")
    refute h.ss_apple_platform?(user_agent: "Mozilla/5.0 (Linux; Android 15)")
  end

  # ── Acertos da v1.10 ────────────────────────────────────────────────
  test "visor de foto: --ss-viewer-bg sem black literal (só tokens)" do
    css = sem_comentarios(CSS.join("v1100_web.css").read)
    linha = css[/--ss-viewer-bg:[^;]+;/]
    assert linha, "sem --ss-viewer-bg"
    refute_match(/\bblack\b/, linha)
    assert_includes linha, "var(--side)"
  end

  test "CurvedHeader tone: :dark levanta do --side com a tinta (visível no escuro)" do
    css = sem_comentarios(CSS.join("v1100_web.css").read)
    assert_match(/\.ss-curved\[data-tone="dark"\] \{ --bg: color-mix\(in srgb, var\(--side\) 82%, var\(--ink\)\); \}/, css)
    render_inline(Ss::CurvedHeaderComponent.new(title: "Início", tone: :dark))
    assert_selector ".ss-curved[data-tone=dark]"
  end

  test "PulseAvatar: onda mais forte e com aro no claro; no escuro, a de antes" do
    css = sem_comentarios(CSS.join("v1100_web.css").read)
    assert_match(/\.ss-pulse-waves i \{[^}]*var\(--k\) var\(--ss-pulse-a, 34%\)[^}]*box-shadow: inset 0 0 0 1\.5px/m, css)
    assert_includes css, '[data-theme="dark"] .ss-pulse { --ss-pulse-a: 22%; --ss-pulse-ring: 0%; }'
  end

  # v1.12.0: Novidades passou à v1.12; a página da v1.11 continua marcada com a versão dela.
  test "vitrine: a página da v1.11 está marcada com a versão dela" do
    assert_includes Rails.root.join("app/views/vitrine/pecas_v1110.html.erb").read.lines.first, "versao: 1.11"
  end

  private

  # O HTML de um componente para devolver dentro de um slot.
  def render_inline_str(component) = vc_test_controller.view_context.render(component)
end
