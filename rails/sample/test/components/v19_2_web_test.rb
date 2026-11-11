require "test_helper"

# v0.19.2 · as últimas caixas genéricas que o minhas-compras e o minhas-viagens desenhavam à mão (pares
# do Flutter): botão sólido e empilhado sobre o gradiente, card de foto com subtítulo/crédito/escolhido,
# monograma de loja, e o CSS da faixa e do contorno no card, do selo sólido e em mono, dos passos
# numerados, do ponto, do recado e do vidro escuro.
class V192WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  include ComponentesUi::Helpers

  test "ButtonComponent: sólido e empilhado sobre o gradiente; padrão sem as classes novas" do
    render_inline(Ss::ButtonComponent.new(label: "Voo", icon: "paper-airplane", variant: :on_grad, solid: true, stacked: true, href: "/para-onde?o=voo"))
    assert_selector "a.ss-btn.is-on-grad.is-solid.is-stacked[href='/para-onde?o=voo'] svg.ss-icon + span", text: "Voo"
    refute_selector "svg.ss-icon.is-xs"
    render_inline(Ss::ButtonComponent.new(label: "Sair", variant: :on_grad))
    assert_selector "button.ss-btn.is-on-grad:not(.is-solid):not(.is-stacked)", text: "Sair"
    # solid: só vale no :on_grad; stacked: não vale na ficha nem no item de menu.
    render_inline(Ss::ButtonComponent.new(label: "Ok", solid: true, stacked: true))
    assert_selector "button.ss-btn-primary.is-stacked:not(.is-solid)"
    render_inline(Ss::ButtonComponent.new(label: "Hoje", variant: :chip, stacked: true))
    assert_selector "button.ss-chip:not(.is-stacked)"
  end

  test "PhotoCardComponent: subtítulo, crédito com link para a foto e escolhido" do
    render_inline(Ss::PhotoCardComponent.new(src: "/f.jpg", title: "Praia do Rosa", subtitle: "Imbituba, SC",
                                             credit: "Foto: Fulano · CC BY 4.0", credit_url: "https://commons.example/f", selected: true))
    assert_selector "figure.ss-card.ss-photo.has-subtitle.is-selected[aria-current=true]"
    assert_selector "figcaption.ss-photo-cap .ss-photo-text .ss-photo-title", text: "Praia do Rosa"
    assert_selector ".ss-photo-text .ss-photo-subtitle", text: "Imbituba, SC"
    assert_selector "a.ss-photo-credit[href='https://commons.example/f'][target=_blank][rel=noopener][title='Abrir a página da foto']", text: "Foto: Fulano · CC BY 4.0"
  end

  test "PhotoCardComponent: crédito vira texto dentro do card-link; sem os novos, igual ao de antes" do
    render_inline(Ss::PhotoCardComponent.new(src: "/f.jpg", title: "Jardim", credit: "Foto: X", credit_url: "/c", url: "/p"))
    assert_selector "a.ss-photo[href='/p'] span.ss-photo-credit", text: "Foto: X"
    refute_selector "a.ss-photo a"
    render_inline(Ss::PhotoCardComponent.new(src: "/f.jpg", title: "Varanda", badge: "Ligada"))
    assert_selector "figure.ss-photo:not(.has-subtitle):not(.is-selected) figcaption > .ss-photo-title + .ss-photo-badge"
    refute_selector ".ss-photo-credit"
    refute_selector "[aria-current]"
  end

  test "PhotoCardComponent: título do crédito em inglês e espanhol" do
    I18n.with_locale(:en) { render_inline(Ss::PhotoCardComponent.new(credit: "Photo: X", credit_url: "/c")) }
    assert_selector "a.ss-photo-credit[title='Open the photo page']"
    I18n.with_locale(:es) { render_inline(Ss::PhotoCardComponent.new(credit: "Foto: X", credit_url: "/c")) }
    assert_selector "a.ss-photo-credit[title='Abrir la página de la foto']"
  end

  test "ss_monogram: cor de dado validada, círculo e rótulo" do
    html = ss_monogram("Ali", color: "#E43225", size: 32, label: "AliExpress")
    assert_includes html, %(class="ss-monogram")
    assert_includes html, "--s:32px;--ss-mono:#E43225;--ss-mono-scale:.34"
    assert_includes html, %(aria-label="AliExpress">Ali</span>)
    refute_includes ss_monogram("S", color: "url(x)", circle: true), "--ss-mono:"
    assert_includes ss_monogram("S", circle: true), "ss-monogram is-circle"
  end

  test "CSS da v0.19.2 no engine: card, selo, passos, ponto, monograma, recado, vidro e foto" do
    css = CSS.join("v19_2_web.css").read
    [".ss-card.has-stripe::before", "var(--ss-card-stripe, var(--accent))", ".ss-card.has-outline", "var(--ss-card-outline",
     ".ss-btn.is-on-grad.is-solid", ".ss-btn.is-stacked", ".ss-badge.is-solid", ".ss-badge.ss-badge-accent.is-solid",
     ".ss-badge.is-mono", "var(--font-mono)", ".ss-prose ol.is-steps", "counter(ss-step)", ".ss-dot", ".ss-dot.is-ring",
     ".ss-monogram", "var(--ss-mono, var(--accent-solid))", ".ss-quote", ".ss-quote cite::before", ".ss-glass.is-dark",
     ".ss-photo-subtitle", ".ss-photo-credit", ".ss-photo.is-selected::after"].each { |k| assert_includes css, k }
    assert_includes CSS.join("engine.css").read, %(@import "./v19_2_web.css";)
    # Sem cor da paleta do Tailwind nem hex de marca: só token, branco e preto para escurecer.
    refute_match(/#(?!fff\b|000\b)\h{3,8}\b/, css)
  end

  test "textos novos nos três idiomas" do
    { "pt-BR": "Abrir a página da foto", en: "Open the photo page", es: "Abrir la página de la foto" }.each do |loc, txt|
      assert_equal txt, I18n.t("componentes_ui.photo_card.source", locale: loc)
    end
  end
end
