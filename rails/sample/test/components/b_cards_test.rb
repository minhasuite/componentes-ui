require "test_helper"

class BCardsTest < ComponentTest
  QR = "<svg id='qr'></svg>".html_safe

  test "ingresso e cartão de embarque" do
    render_inline(Ss::TicketCardComponent.new) { |t| t.with_stub { "base" }; "topo" }
    assert_selector ".ss-ticket .ss-ticket-top", text: "topo"
    assert_selector ".ss-ticket .ss-ticket-stub", text: "base"
    c = Ss::BoardingPassComponent.new(from: { code: "GRU", city: "SP" }, to: { code: "SSA", city: "BA" }, progress: 0.5, fields: [["Assento", "24A"]], qr: QR, carrier: "X")
    render_inline(c)
    assert_selector ".ss-pass .ss-pass-code", text: "GRU"
    assert_selector "svg[role=img][aria-label*='50%']"
    assert_selector ".ss-pass-fields dt", text: "Assento"
    assert_selector ".ss-ticket-stub .ss-qr-box svg#qr"
    x, _, angle = c.plane
    assert_in_delta 150.0, x, 0.01
    assert_in_delta 0.0, angle, 0.01 # no topo do arco o avião fica na horizontal
  end

  test "produto, depoimento e planos" do
    render_inline(Ss::ProductCardComponent.new(name: "Costela", price: "R$ 89,90", url: "/p/1", action: { label: "Adicionar", url: "/c", method: :post })) { |c| c.with_image { QR } }
    assert_selector ".ss-product .ss-product-img svg#qr"
    assert_selector ".ss-product a.ss-product-link[href='/p/1']", text: "Costela"
    assert_selector ".ss-product .ss-amount", text: "R$ 89,90"
    assert_selector ".ss-product form[action='/c'] button.ss-product-btn[aria-label='Adicionar: Costela']"

    render_inline(Ss::ReviewCardComponent.new(name: "Carla", text: "Ótimo", rating: 4.5))
    assert_selector ".ss-review .ss-stars[role=img][aria-label='Nota 4,5 de 5']"
    assert_selector ".ss-review .ss-avatar"

    render_inline(Ss::PricingTableComponent.new(plans: [{ name: "Grátis", monthly: "R$ 0,00", features: ["1"] },
                                                       { name: "Pro", monthly: "R$ 19,90", yearly: "R$ 199,00", featured: true, features: ["IA"], cta: { label: "Assinar", url: "/m", yearly_url: "/a" } }]))
    assert_selector ".ss-pricing [role=radiogroup] input[type=radio][value=monthly][checked]"
    assert_selector ".ss-pricing-plan.ss-card-grad.is-featured h3", text: "Pro"
    assert_selector ".ss-pricing-price.is-yearly .ss-amount", text: "R$ 199,00"
    assert_selector "a.ss-pricing-cta.is-monthly[href='/m']"
    assert_selector "a.ss-pricing-cta.is-yearly[href='/a']"
  end

  test "aba de situação, QR, IA, nível e pessoa" do
    render_inline(Ss::StatusTabCardComponent.new(status: "Concluída", tone: :success, title: "Web", progress: 1, people: %w[Ana Bia Caio Duda])) { "<a href='#'>Abrir</a>".html_safe }
    assert_selector ".ss-tabcard[data-tone=success] .ss-tabcard-tab", text: "Concluída"
    assert_selector ".ss-tabcard [role=progressbar][aria-valuenow='100']"
    assert_selector ".ss-tabcard .ss-avatars .more", text: "+1"
    assert_selector ".ss-tabcard details.ss-menu a", text: "Abrir", visible: :all

    render_inline(Ss::QrCardComponent.new(code: "PIX123", amount: "R$ 10,00", expires_at: Time.current + 90)) { QR }
    assert_selector ".ss-qrcard[data-controller=ss-countdown] .ss-qr-box svg#qr"
    assert_selector "[data-controller=ss-copy][data-ss-copy-text-value=PIX123] input[readonly][value=PIX123]"
    assert_selector "[data-ss-countdown-target=clock]", text: /\A01:(29|30)\z/

    render_inline(Ss::AiInsightCardComponent.new(title: "Mercado subiu", sources: [{ label: "42 lançamentos" }], apply: { url: "/m", method: :post }, dismiss: { url: "/i" })) { "Texto" }
    assert_selector ".ss-ai-card .ss-ai-badge", text: "IA"
    assert_selector ".ss-ai-text", text: "Texto"
    assert_selector "details.ss-ai-sources li", text: "42 lançamentos", visible: :all
    assert_selector "form[action='/m'] button", text: "Aplicar"
    assert_selector "a[href='/i']", text: "Ignorar"
    render_inline(Ss::AiInsightCardComponent.new(thinking: true))
    assert_selector ".ss-ai-card.is-thinking[aria-busy=true] .ss-thinking"

    render_inline(Ss::LevelCardComponent.new(points: 4860, level: 3, next_at: 6000, items: [{ label: "Uber", spent: "R$ 8,60", points: 24 }]))
    assert_selector ".ss-level-points b", text: "4.860"
    assert_selector ".ss-level [role=progressbar][aria-valuemax='6000']"
    assert_selector ".ss-level-list td", text: "+24"

    render_inline(Ss::PersonCardComponent.new(name: "Ana Souza", role: "Vendedora", metrics: [["Pedidos", "214"]], team: %w[A B C D E F]))
    assert_selector ".ss-person h3", text: "Ana Souza"
    assert_selector ".ss-person-metrics dd", text: "214"
    assert_selector ".ss-person-team .ss-avatar.more", text: "+2"
  end

  test "acabamento: transição e número que conta" do
    render_inline(Ss::TransitionComponent.new(name: "Produto 1 img", kind: :img)) { "x" }
    assert_selector ".ss-vt.ss-vt-img[style='view-transition-name:produto-1-img']"
    assert_equal "view-transition-name:produto-2-title", Ss::TransitionComponent.style("produto-2-title")
    render_inline(Ss::CountUpComponent.new(value: 48320.5, format: :money))
    assert_selector ".ss-count-up[data-controller=ss-count-up][data-ss-count-up-value-value='48320.5'] .ss-amount", text: "R$\u00A048.320,50"
    assert_selector ".ss-count-up .ss-sr", text: "R$\u00A048.320,50"
    render_inline(Ss::CountUpComponent.new(value: 92.4, format: :percent, decimals: 1))
    assert_selector ".ss-count-up-n", text: "92,4%"
  end
end
