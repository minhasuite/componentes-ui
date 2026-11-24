require "test_helper"

# v1.9 · paridade web: os pares Rails das peças que só existiam no Flutter e o paridade.yml (Flutter ↔ Rails).
class V19ParidadeWebWebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)
  CSS = ROOT.join("app/assets/tailwind/componentes_ui")
  JS = ROOT.join("app/javascript/componentes_ui/controllers")
  PARIDADE = YAML.load_file(ROOT.join("../paridade.yml"))

  # ── paridade.yml ────────────────────────────────────────────────────
  def targets(value) = value.is_a?(Hash) ? (value["pendente_v19"] ? [] : Array(value["rails"])) : Array(value)

  def all_targets
    %w[pares apis].flat_map { |s| PARIDADE.fetch(s).values.flat_map { |v| v.is_a?(Hash) ? Array(v["rails"]) : Array(v) } }
  end

  def component_files = Dir[ROOT.join("app/components/ss/*_component.rb")].map { |f| "Ss::#{File.basename(f, "_component.rb").camelize}Component" } - ["Ss::BaseComponent"]

  def css_classes = @css_classes ||= Dir[CSS.join("*.css")].flat_map { |f| File.read(f).scan(/\.ss-[a-z0-9-]+/) }.to_set

  test "paridade.yml: as seções e os motivos das exceções" do
    assert_equal %w[apis divida divida_app pares so_app so_web], PARIDADE.keys.sort
    %w[so_app so_web divida divida_app].each do |s|
      PARIDADE[s].each { |k, motivo| assert motivo.to_s.strip.length > 10, "#{s}.#{k} sem motivo" }
    end
    so_app_and_pair = PARIDADE["so_app"].keys & PARIDADE["pares"].keys
    assert_empty so_app_and_pair, "a mesma peça no par e no só app"
  end

  test "paridade.yml: todo Ss::*Component da gem está registrado (par, só web ou dívida)" do
    registrados = all_targets + PARIDADE["so_web"].keys + PARIDADE["divida_app"].keys
    faltam = component_files - registrados
    assert_empty faltam, "componente sem par no Flutter nem exceção no paridade.yml: #{faltam.join(", ")}"
  end

  test "paridade.yml: todo alvo Rails existe (componente, helper, form, css ou controller)" do
    erros = []
    %w[pares apis].each do |s|
      PARIDADE[s].each do |nome, v|
        targets(v).each do |t|
          ok = case t
               when /\ASs::\w+Component\z/ then t.safe_constantize.is_a?(Class)
               when /\Ahelper:(\w+)\z/ then ComponentesUi::Helpers.method_defined?($1) || ComponentesUi::Helpers.private_method_defined?($1)
               when /\Aform:(\w+)\z/ then ComponentesUi::FormBuilder.method_defined?($1)
               when /\Acss:(\.ss-[a-z0-9-]+)\z/ then css_classes.include?($1)
               when /\Ajs:(ss-[a-z0-9-]+)\z/ then JS.join("#{$1.tr("-", "_")}_controller.js").exist?
               else false
               end
          erros << "#{nome} → #{t}" unless ok
        end
      end
    end
    %w[so_web divida_app].each { |s| PARIDADE[s].each_key { |k| erros << "#{s}: #{k}" unless k.safe_constantize.is_a?(Class) } }
    assert_empty erros, "alvo que não existe no Rails: #{erros.join(", ")}"
  end

  test "paridade.yml: os pares que esta onda criou não são mais dívida nem pendência" do
    {
      "SsSwipeToConfirm" => "Ss::SwipeToConfirmComponent", "SsHoldToConfirm" => "Ss::HoldToConfirmComponent",
      "SsSnapCarousel" => "Ss::SnapCarouselComponent", "SsStoryRing" => "Ss::StoryRingComponent", "SsOdometer" => "Ss::OdometerComponent",
      "SsMorphButton" => "Ss::MorphButtonComponent", "SsBurst" => "Ss::BurstComponent", "SsHeatCalendar" => "Ss::HeatCalendarComponent",
      "SsBigRing" => "Ss::BigRingComponent", "SsRings" => "Ss::RingsComponent", "SsDateStrip" => "Ss::DateStripComponent",
      "SsSyncStatus" => "Ss::SyncStatusComponent"
    }.each { |f, r| assert_includes targets(PARIDADE["pares"].fetch(f)), r }
    assert_includes targets(PARIDADE["pares"]["SsSplitSlider"]), "Ss::SplitSliderComponent"
  end

  # ── Componentes ─────────────────────────────────────────────────────
  test "SwipeToConfirm: formulário com a bolinha-botão, a dica e o estado" do
    render_inline(Ss::SwipeToConfirmComponent.new(label: "Deslize para pagar", url: "/pagar", method: :post, params: { id: 7 }))
    assert_selector "form.ss-swipe-confirm[action='/pagar'][data-controller=ss-swipe-confirm][data-state=idle]"
    assert_selector "form input[type=hidden][name=id][value='7']", visible: :all
    assert_selector "button.ss-swipe-thumb[type=button][aria-label='Deslize para pagar'][aria-describedby]"
    assert_selector ".ss-sr", text: "Arraste até o fim para confirmar", visible: :all
    assert_selector ".ss-swipe-label[aria-hidden=true]", text: "Deslize para pagar"
    assert_selector "[role=status]", visible: :all
    render_inline(Ss::SwipeToConfirmComponent.new(label: "Encerrar", done: true, done_label: "Encerrado"))
    assert_selector "div.ss-swipe-confirm[data-state=done]"
    assert_selector "button.ss-swipe-thumb[aria-label=Encerrado]"
    refute_selector "form"
  end

  test "HoldToConfirm: botão com as duas camadas, perigo e formulário" do
    render_inline(Ss::HoldToConfirmComponent.new(label: "Segure para excluir", url: "/x/1", method: :delete, danger: true, duration: 800))
    assert_selector "form.ss-hold-form input[name=_method][value=delete]", visible: :all
    assert_selector "button.ss-hold-confirm.is-danger[type=button][data-ss-hold-confirm-duration-value='800'][data-state=idle]"
    assert_selector ".ss-hold-fill[aria-hidden=true] .ss-hold-d", text: "Confirmado", visible: :all
    assert_selector ".ss-sr", text: "Segure para confirmar", visible: :all
    assert_includes page.find("button.ss-hold-confirm")["data-action"], "pointerdown->ss-hold-confirm#press"
  end

  test "MorphButton: pílula, anel, ✓ e ✗, com os textos do leitor de tela" do
    render_inline(Ss::MorphButtonComponent.new(label: "Salvar", icon: "check"))
    assert_selector ".ss-morph-wrap button.ss-morph[type=submit][data-state=idle][data-controller=ss-morph]"
    assert_selector "button[data-ss-morph-loading-value='Salvar: carregando'][data-ss-morph-failed-value='Salvar: falhou']"
    assert_selector ".ss-morph-ring[aria-hidden=true] circle.bar"
    assert_selector "svg.ss-morph-ok"
    assert_selector "svg.ss-morph-err"
    render_inline(Ss::MorphButtonComponent.new(label: "Enviar", type: :button, block: false))
    assert_selector ".ss-morph-wrap.is-inline button[type=button]"
  end

  test "SnapCarousel: faixa com os itens rotulados, bolinhas ou contador" do
    render_inline(Ss::SnapCarouselComponent.new(label: "Ofertas", initial: 1, peek: 0.8)) do |c|
      3.times { |i| c.with_slide { "Oferta #{i}" } }
    end
    assert_selector "section.ss-carousel[aria-roledescription=carrossel][aria-label=Ofertas][style*='--ss-carousel-peek:80.0%']"
    assert_selector ".ss-carousel-track[tabindex='0'] .ss-carousel-slide[role=group]", count: 3
    assert_selector ".ss-carousel-slide[aria-label='Item 2 de 3'][data-current]", text: "Oferta 1"
    assert_selector ".ss-carousel-dots[aria-hidden=true] i", count: 3
    assert_selector "button.ss-carousel-arrow[aria-label=Anterior]"
    render_inline(Ss::SnapCarouselComponent.new(label: "x", indicator: :counter)) { |c| 2.times { c.with_slide { "a" } } }
    assert_selector ".ss-carousel-count[aria-live=polite]", text: "1/2"
    render_inline(Ss::SnapCarouselComponent.new(label: "vazio"))
    refute_selector ".ss-carousel"
  end

  test "StoryRing: um gomo por novidade, vistos neutros, link e o +" do
    c = Ss::StoryRingComponent.new(name: "Ana Souza", segments: 3, seen: 1, caption: "Ana", href: "/s/1", add_href: "/s/new")
    assert_equal 3, c.arcs.size
    assert_equal [true, false, false], c.arcs.map(&:last)
    render_inline(c)
    assert_selector ".ss-story.has-news a.ss-story-main[href='/s/1'][aria-label='Ana Souza, 2 novidades']"
    assert_selector "circle.is-seen", count: 1
    assert_selector "circle.is-new", count: 2
    assert_selector "a.ss-story-add[href='/s/new'][aria-label=Adicionar]"
    assert_selector ".ss-story-caption", text: "Ana"
    render_inline(Ss::StoryRingComponent.new(name: "Bia", segments: 0))
    assert_selector "span.ss-story-main[role=img][aria-label=Bia]"
    assert_selector "circle.is-seen", count: 1
  end

  test "Odometer: um rolo por dígito, casas contadas da direita e centavos menores" do
    render_inline(Ss::OdometerComponent.new(text: "R$ 1.234,56", size: 24))
    assert_selector ".ss-odo[data-controller=ss-odometer][data-ss-odometer-text-value='R$ 1.234,56'][style*='--ss-odo-size:24px']"
    assert_selector ".ss-sr[aria-live=polite]", text: "R$ 1.234,56", visible: :all
    assert_selector ".ss-odo-n[aria-hidden=true] .ss-odo-col", count: 6
    assert_selector ".ss-odo-cents .ss-odo-col", count: 2
    assert_selector ".ss-odo-col[style*='--pos:11;--k:5']"   # o 1 do milhar
    assert_selector ".ss-odo-cents .ss-odo-col[style*='--pos:16;--k:0']" # o último 6
    assert_selector ".ss-odo-ch", text: "."
    render_inline(Ss::OdometerComponent.new(text: "214", roll_in: true))
    assert_selector ".ss-odo[data-ss-odometer-roll-in-value=true] .ss-odo-col", count: 3
    refute_selector ".ss-odo-cents"
  end

  test "Burst: gatilho e tom" do
    render_inline(Ss::BurstComponent.new(on: :change, tone: :success, count: 9)) { "<input type='checkbox'>".html_safe }
    assert_selector "span.ss-burst[data-tone=success][data-action='change->ss-burst#changed'][data-ss-burst-count-value='9'] input"
    render_inline(Ss::BurstComponent.new(on: :connect, tone: :xyz)) { "x" }
    assert_selector "span.ss-burst[data-tone=accent][data-ss-burst-auto-value=true]"
  end

  test "HeatCalendar: semanas de domingo a sábado, níveis do ssHeatLevel e um ponto de tab" do
    hoje = Date.new(2026, 11, 24) # terça
    vals = { hoje => 4, hoje - 1 => 2, "2026-11-20" => 1 }
    c = Ss::HeatCalendarComponent.new(values: vals, weeks: 2, end_date: hoje)
    assert_equal 3, c.weeks
    assert_equal [0, 1, 2, 4], [nil, 1, 2, 4].map { |v| Ss::HeatCalendarComponent.level(v, 4.0) }
    render_inline(c)
    assert_selector ".ss-heatcal-grid[role=group] button.ss-heatcal-day", count: 14
    assert_selector ".ss-heatcal-pad", count: 7
    assert_selector "button[data-level='4'][aria-label='24/11/2026: 4'][tabindex='0']"
    assert_selector "button[tabindex='0']", count: 1
    assert_selector "button[data-level='2'][data-date='2026-11-23']"
    assert_selector ".ss-heatcal-out[aria-live=polite]", visible: :all
    assert_selector ".ss-heatcal-legend[aria-hidden=true] i", count: 5
    render_inline(Ss::HeatCalendarComponent.new(values: {}, month: Date.new(2026, 11, 1), format: :money, legend: false))
    assert_selector ".ss-heatcal.is-month button.ss-heatcal-day", count: 30
    assert_selector "button[aria-label='01/11/2026: nada']"
    refute_selector ".ss-heatcal-legend"
  end

  test "BigRing: marcações acesas até o valor, o número e o rótulo" do
    render_inline(Ss::BigRingComponent.new(value: 0.5, caption: "da meta", ticks: 60))
    assert_selector "figure.ss-bigring[role=img][aria-label='50% da meta'][data-tone=accent]"
    assert_selector "line.ss-bigring-tick", count: 60
    assert_selector "line.ss-bigring-tick.is-on", count: 30
    assert_selector "line.ss-bigring-tick.is-big", count: 12
    assert_selector "circle.ss-bigring-arc[style*='--v:50.0']"
    assert_selector ".ss-bigring-n [data-controller=ss-count-up][data-ss-count-up-value-value='50.0']"
    assert_selector ".ss-bigring-cap", text: "da meta"
  end

  test "Rings: até 3 anéis com rótulo para o leitor de tela" do
    render_inline(Ss::RingsComponent.new(rings: [{ value: 0.8, label: "Calorias" }, { value: 0.5, label: "Exercício", tone: :success }, 0.2, 0.9], center: "80%"))
    assert_selector ".ss-rings.ss-rings-c[role=img][aria-label='Calorias 80%, Exercício 50%, 3 20% (80%)']"
    assert_selector "circle.fill", count: 3
    assert_selector "circle.fill[style*='stroke:var(--success)']"
    assert_selector ".ss-rings > span[aria-hidden=true]", text: "80%"
  end

  test "DateStrip: os dias do mês, o escolhido, hoje e os pontinhos" do
    render_inline(Ss::DateStripComponent.new(selected: Date.new(2026, 11, 12), today: Date.new(2026, 11, 24), url: "/agenda?dia=%{date}",
                                             markers: { Date.new(2026, 11, 12) => [:accent, :success], Date.new(2026, 11, 3) => [:danger, :xyz] }))
    assert_selector "nav.ss-date-strip[aria-label='Dias de Novembro 2026']"
    assert_selector "a.ss-date-strip-day", count: 30
    assert_selector "a.ss-date-strip-day[aria-current=date][href='/agenda?dia=2026-11-12']", text: "12"
    assert_selector "a[aria-current=date][aria-label*='2 eventos']"
    assert_selector "a.ss-date-strip-day[data-today][aria-label*=hoje]", text: "24"
    assert_selector "a.ss-date-strip-day:not([aria-current])[tabindex='-1']", count: 29
    assert_selector ".ss-date-strip-days[style='--i:11']"
    assert_selector "a[href$='2026-11-03'] .ss-date-strip-dots i", count: 1
    assert_selector "button.ss-date-strip-month[aria-label='Mês: Novembro 2026. Abrir calendário']"
    assert_selector "input.ss-date-strip-picker[type=date][value='2026-11-12']", visible: :all
  end

  test "SplitSlider: a mesma redistribuição do Flutter (centavos exatos) e os campos" do
    r = Ss::SplitSliderComponent.redistribute([25_000, 25_043, 25_043], 0, 30_000, 75_086)
    assert_equal 75_086, r.sum
    assert_equal 30_000, r[0]
    assert_equal [22_543, 22_543], r[1..]
    assert_equal [0, 100], Ss::SplitSliderComponent.redistribute([50, 50], 0, 0, 100)
    assert_equal [10], Ss::SplitSliderComponent.redistribute([3], 0, 5, 10)
    render_inline(Ss::SplitSliderComponent.new(name: "divisao", total: 10_000, locked: false,
                                               entries: [{ key: "eu", name: "Eu", cents: 5_000 }, { key: "ana", name: "Ana", cents: 3_000 }]))
    assert_selector "fieldset.ss-split-slider legend.ss-sr", text: "Divisão", visible: :all
    assert_selector "input[type=range][max='10000'][step='100'][value='5000'][aria-valuetext='R$\u00A050,00']"
    assert_selector "input[type=hidden][name='divisao[ana]'][value='3000']", visible: :all
    assert_selector ".ss-split-slider-foot[aria-live=polite]", text: "Total R$\u00A0100,00 · Falta R$\u00A020,00"
  end

  test "SyncStatus: os estados, a regra do app e a última sincronização" do
    assert_equal({ state: :sending, pending_count: 2, failed_count: 1 }, Ss::SyncStatusComponent.resolve(syncing: true, failed: 1, pending: 2))
    assert_equal :failed, Ss::SyncStatusComponent.resolve(failed: 1, offline: true)[:state]
    assert_equal :offline, Ss::SyncStatusComponent.resolve(offline: true, pending: 2)[:state]
    assert_equal :pending, Ss::SyncStatusComponent.resolve(pending: 2)[:state]
    assert_equal :synced, Ss::SyncStatusComponent.resolve[:state]
    render_inline(Ss::SyncStatusComponent.new(state: :pending, pending_count: 3))
    assert_selector "span.ss-sync[data-state=pending] [role=status]", text: "3 a enviar"
    render_inline(Ss::SyncStatusComponent.new(state: :failed, failed_count: 2, href: "/fila"))
    assert_selector "a.ss-sync.ss-sync-link[href='/fila'][data-state=failed]", text: "2 com erro"
    render_inline(Ss::SyncStatusComponent.new(state: :offline, pending_count: 1, last_synced_at: Time.current.change(hour: 14, min: 32)))
    assert_selector ".ss-sync[title='Sincronizado às 14:32']", text: "Sem conexão · 1 a enviar"
    render_inline(Ss::SyncStatusComponent.new(state: :synced, last_synced_at: Date.new(2026, 11, 12).to_time))
    assert_selector ".ss-sync[title='Sincronizado em 12/11']", text: "Tudo salvo"
  end

  test "en e es: os textos novos" do
    I18n.with_locale(:en) do
      render_inline(Ss::SyncStatusComponent.new(state: :pending, pending_count: 1))
      assert_text "1 to send"
      render_inline(Ss::SwipeToConfirmComponent.new(label: "Pay"))
      assert_selector ".ss-sr", text: "Slide to the end to confirm", visible: :all
    end
    I18n.with_locale(:es) do
      render_inline(Ss::HeatCalendarComponent.new(values: {}, weeks: 1, end_date: Date.new(2026, 11, 24)))
      assert_selector ".ss-heatcal-legend", text: "menos", visible: :all
      assert_selector "figcaption", text: "Constancia", visible: :all
    end
  end

  # ── CSS e JS ────────────────────────────────────────────────────────
  test "CSS importado, só tokens e reduzir movimento; um controller por peça" do
    engine = CSS.join("engine.css").read
    assert_includes engine, '@import "./v19_paridade_web.css";'
    css = CSS.join("v19_paridade_web.css").read
    refute_match(/#(?!fff\b)[0-9a-f]{3,6}\b/i, css.gsub(%r{/\*.*?\*/}m, ""), "cor fixa no CSS (só #fff sobre a cor)")
    assert_includes css, "prefers-reduced-motion: reduce"
    %w[swipe_confirm hold_confirm morph carousel odometer burst heat_calendar date_strip split_slider].each do |c|
      assert JS.join("ss_#{c}_controller.js").exist?, "falta ss_#{c}_controller.js"
    end
    assert_match(/export function redistribute/, JS.join("ss_split_slider_controller.js").read)
  end
end
