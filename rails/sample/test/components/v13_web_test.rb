require "test_helper"

# v0.13 · o que os painéis do minha-automacao pediram (pares do SsSection, SsSectionHeader,
# SsMasonry, SsAsideLayout, SsMosaicTile, SsPhotoCard e SsBrand.fromColors).
class V13WebTest < ComponentTest
  include ComponentesUi::Helpers

  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  SVG = %(<svg viewBox="0 0 24 24"><path d="M0 0h24v24"/></svg>).freeze

  test "seção: versalete com ícone, tag e ação" do
    render_inline(Ss::SectionComponent.new(title: "Sala", icon: SVG, heading: :h3)) { |s| s.with_action { "Ver tudo" } }
    assert_selector ".ss-section-row > h3.ss-section .ss-section-ico[aria-hidden=true] svg"
    assert_selector "h3.ss-section .ss-section-text", text: "Sala"
    assert_selector ".ss-section-row > .ss-section-action", text: "Ver tudo"
    render_inline(Ss::SectionComponent.new(title: "Só texto", heading: :script))
    assert_selector "h2.ss-section", text: "Só texto"
    assert_no_selector ".ss-section-ico, .ss-section-action"
  end

  test "cabeçalho de bloco: título, explicação, ícone e ação" do
    render_inline(Ss::SectionHeaderComponent.new(title: "Andar de cima", subtitle: "3 cômodos", icon: SVG)) { |h| h.with_action { "Editar" } }
    assert_selector ".ss-section-head .ss-section-head-ico svg"
    assert_selector "h2.ss-section-head-title", text: "Andar de cima"
    assert_selector "p.ss-section-head-sub", text: "3 cômodos"
    assert_selector ".ss-section-head-action", text: "Editar"
    render_inline(Ss::SectionHeaderComponent.new(title: "Só"))
    assert_no_selector ".ss-section-head-sub, .ss-section-head-ico, .ss-section-head-action"
  end

  test "mosaico em colunas e coluna lateral" do
    render_inline(Ss::MasonryComponent.new(max: 2, css: "mt-5")) { "<div class='ss-card'>a</div>".html_safe }
    assert_selector ".ss-masonry.is-max-2.mt-5 > .ss-card", text: "a"
    render_inline(Ss::MasonryComponent.new) { "x" }
    assert_selector ".ss-masonry:not([class*=is-max])"
    render_inline(Ss::AsideLayoutComponent.new(label: "Resumo")) do |l|
      l.with_main { "principal" }
      l.with_aside { "lado" }
    end
    assert_selector ".ss-aside-layout > .ss-aside-layout-main", text: "principal"
    assert_selector ".ss-aside-layout > aside.ss-aside-layout-side[aria-label=Resumo]", text: "lado"
    render_inline(Ss::AsideLayoutComponent.new) { |l| l.with_main { "só" } }
    assert_no_selector "aside"
    css = CSS.join("v13_web.css").read
    ["break-inside: avoid", ".ss-masonry > .contents > *", "position: sticky"].each { assert_includes css, _1 }
    assert_includes CSS.join("engine.css").read, '@import "./v13_web.css";'
  end

  test "bloco do mosaico: link, variante, foto e pílulas" do
    render_inline(Ss::MosaicTileComponent.new(title: "Sala", icon: SVG, url: "/a/1", variant: 7, link_data: { turbo_frame: "_top" },
                                              facts: [{ label: "2 ligados", icon: SVG }, "87 W"]))
    a = page.find("a.ss-mosaic[href='/a/1']")
    assert_equal "2", a["data-variant"]
    assert_equal "_top", a["data-turbo-frame"]
    assert_selector "a.ss-mosaic .ss-mosaic-ico svg"
    assert_selector ".ss-mosaic-title", text: "Sala"
    assert_selector ".ss-mosaic-facts .ss-mosaic-fact", count: 2
    assert_selector ".ss-mosaic-fact svg"
    render_inline(Ss::MosaicTileComponent.new(title: "Jardim", caption: "Calmo", image_url: "/fotos/j.jpg"))
    div = page.find("div.ss-mosaic.has-photo")
    assert_includes div["style"], "--photo: url(/fotos/j.jpg)"
    assert_selector ".ss-mosaic-caption", text: "Calmo"
    render_inline(Ss::MosaicTileComponent.new(title: "X", image_url: "javascript:alert(1)"))
    assert_no_selector ".has-photo"
  end

  test "bloco do mosaico: pílula com tom, dica e link próprio (link esticado)" do
    html = render_inline(Ss::MosaicTileComponent.new(title: "Sala", url: "/a/1", facts: [{ label: "2 ligados" }, "87 W"])).to_html
    assert_equal '<a class="ss-mosaic" data-variant="0" href="/a/1"><span class="ss-mosaic-title">Sala</span>' \
                 '<span class="ss-mosaic-facts"><span class="ss-mosaic-fact">2 ligados</span><span class="ss-mosaic-fact">87 W</span></span></a>',
                 html.gsub(/<!--.*?-->/, "").strip
    render_inline(Ss::MosaicTileComponent.new(title: "Contas", facts: [{ label: "1 vencida", tone: :danger, title: "Vence hoje" }, { label: "x", tone: "roxo" }]))
    assert_selector "div.ss-mosaic span.ss-mosaic-fact.is-danger[title='Vence hoje']", text: "1 vencida"
    assert_selector "span.ss-mosaic-fact[class='ss-mosaic-fact']", text: "x"
    render_inline(Ss::MosaicTileComponent.new(title: "Z", facts: [{ label: "a", tone: :success }, { label: "b", tone: :warning }, { label: "c", tone: :info }]))
    assert_selector ".ss-mosaic-fact.is-ok", text: "a"
    assert_selector ".ss-mosaic-fact.is-warn", text: "b"
    assert_selector ".ss-mosaic-fact.is-info", text: "c"

    render_inline(Ss::MosaicTileComponent.new(title: "Contas", url: "/contas", variant: 1, link_data: { turbo_frame: "_top" }, css: "mt-2",
                                              facts: [{ label: "12 em dia" },
                                                      { label: "3 atrasadas", tone: "warn", url: "/contas?f=atrasadas", title: "Ver as 3 atrasadas",
                                                        link_data: { turbo_frame: "_top" } }]))
    assert_no_selector "a.ss-mosaic"
    root = page.find("div.ss-mosaic.is-linked.mt-2")
    assert_equal "1", root["data-variant"]
    assert_nil root["data-turbo-frame"]
    link = page.find("div.ss-mosaic > a.ss-mosaic-link[href='/contas']")
    assert_equal "Contas", link["aria-label"]
    assert_equal "_top", link["data-turbo-frame"]
    assert_equal "", link.text
    fact = page.find("a.ss-mosaic-fact.is-warn[href='/contas?f=atrasadas']", text: "3 atrasadas")
    assert_equal "Ver as 3 atrasadas", fact["aria-label"]
    assert_equal "Ver as 3 atrasadas", fact["title"]
    assert_equal "_top", fact["data-turbo-frame"]
    assert_selector "span.ss-mosaic-fact", text: "12 em dia"
    assert_no_selector "a a"

    # Sem url: no bloco, a pílula com link basta (o bloco é um div comum).
    render_inline(Ss::MosaicTileComponent.new(title: "Y", facts: [{ label: "ver", url: "/y" }]))
    assert_selector "div.ss-mosaic:not(.is-linked) a.ss-mosaic-fact[href='/y']"
    assert_no_selector ".ss-mosaic-link"
  end

  test "card de foto: proporção, véu com título e selo, apagado e link" do
    render_inline(Ss::PhotoCardComponent.new(src: "/f.jpg", title: "Varanda", badge: "Ligada", ratio: "4 / 3", dimmed: true))
    fig = page.find("figure.ss-card.ss-photo.is-dimmed")
    assert_includes fig["style"], "aspect-ratio: 4 / 3"
    assert_selector "img[src='/f.jpg'][alt=Varanda][loading=lazy]"
    assert_selector "figcaption.ss-photo-cap .ss-photo-title", text: "Varanda"
    assert_selector ".ss-photo-badge", text: "Ligada"
    render_inline(Ss::PhotoCardComponent.new(src: "/f.jpg", ratio: "1; color: red", url: "/p"))
    a = page.find("a.ss-photo.is-link[href='/p']")
    assert_includes a["style"], "aspect-ratio: 16 / 9"
    assert_no_selector ".ss-photo-cap"
  end

  test "avatar com anel e ponto apagado; marca a partir de duas cores" do
    html = ss_avatar("Ana Souza", status: "muted", ring: true)
    assert_includes html, 'data-status="muted"'
    assert_includes html, "data-ring"
    refute_includes ss_avatar("Ana"), "data-ring"
    css = ss_brand_style("#0284C7", "#14b8a6")
    assert_includes css, "--accent: #0284c7"
    assert_includes css, "--grad: linear-gradient(135deg, #0284c7 0%, #14b8a6 100%)"
    assert_includes css, "--accent-hover: color-mix(in srgb, #0284c7 86%, #000)"
    assert_includes ComponentesUi.brand_css("#0284c7"), "#0284c7 100%"
    assert_nil ComponentesUi.brand_css("red")
    assert_nil ComponentesUi.brand_css("#0284c7", "#12;x")
    v13 = CSS.join("v13_web.css").read
    ['.ss-chip[aria-pressed="true"]', ".ss-chip.is-icon", ".ss-chip-swatch", '.ss-avatar[data-status="muted"]'].each { assert_includes v13, _1 }
  end
  test "texto longo, abertura e árvore que quebra o rótulo" do
    render_inline(Ss::ProseComponent.new(tag: :article)) { "<p>Um</p><ul><li>a</li></ul>".html_safe }
    assert_selector "article.ss-prose p", text: "Um"
    render_inline(Ss::ProseComponent.new(tag: :script)) { "x" }
    assert_selector "div.ss-prose"
    render_inline(Ss::IntroComponent.new(text: "O que esta aba faz."))
    assert_selector "p.ss-intro", text: "O que esta aba faz."
    render_inline(Ss::TreeViewComponent.new(nodes: [{ label: "Um rótulo bem comprido" }], wrap: true))
    assert_selector ".ss-tree.is-wrap .ss-tree-label"
    render_inline(Ss::TreeViewComponent.new(nodes: [{ label: "x" }]))
    assert_no_selector ".is-wrap"
    css = CSS.join("v13_web.css").read
    [".ss-prose a", ".ss-intro", ".ss-tree.is-wrap .ss-tree-label", ".ss-field-group-body"].each { assert_includes css, _1 }
  end
end
