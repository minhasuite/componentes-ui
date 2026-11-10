require "test_helper"

# v0.15 · fase 0 do meu-financeiro: ícones, diálogo com turbo-frame, seletor de mês, barras,
# dinheiro com conta, linha de progresso, chat com cartão de ação, seção de formulário e confete.
class V15WebTest < ComponentTest
  CSS = Pathname(ComponentesUi::Engine.root).join("app/assets/tailwind/componentes_ui")
  JS = Pathname(ComponentesUi::Engine.root).join("app/javascript/componentes_ui/controllers")
  include ComponentesUi::Helpers

  test "ícone: nome da v1 e da v2, cheio, tamanho, título e reserva" do
    render_inline(Ss::IconComponent.new(name: "credit-card"))
    assert_selector "svg.ss-icon[data-icon='credit-card'][aria-hidden=true][stroke=currentColor] path"
    assert_includes rendered_content, 'viewBox="0 0 24 24"'
    render_inline(Ss::IconComponent.new(name: "magnifying-glass", size: :xs, css: "text-muted"))
    assert_selector "svg.ss-icon.is-xs.text-muted[data-icon=search]"
    render_inline(Ss::IconComponent.new(name: "star", variant: :solid, title: "Principal"))
    assert_selector "svg[data-icon=star][fill=currentColor][role=img][aria-label=Principal]"
    assert_includes rendered_content, 'viewBox="0 0 20 20"'
    assert_selector "svg title", text: "Principal", visible: :all
    render_inline(Ss::IconComponent.new(name: "nao-existe"))
    assert_selector "svg[data-icon='question-mark-circle']"
    render_inline(Ss::IconComponent.new(name: "home", size: nil))
    assert_selector "svg.ss-icon.is-free"
    assert ss_icon?("arrow-trending-up")
    assert_equal "trending-up", ss_icon_name("arrow-trending-up")
    assert_operator ss_icon_names.size, :>=, 230
  end

  test "todo nome que o meu-financeiro usa existe (v1 ou apelido da v2)" do
    %w[plus office-building credit-card chevron-down funnel check magnifying-glass currency-dollar chevron-right chevron-left check-circle
       arrow-down exclamation-triangle bell user-group star chart-square-bar chart-bar briefcase arrow-up-tray tag qr-code flag x shield-check
       lock-closed hashtag eye-slash clock calendar banknotes arrow-trending-up arrow-right arrow-left warning users user-circle user truck trophy
       trending-up trash success sparkles shopping-cart server scale receipt-percent puzzle presentation-chart-line pencil-alt paper-airplane moon
       menu list-bullet link light-bulb info home heart filter eye error dots-vertical document-magnifying-glass document-chart-bar document cog
       clipboard-check chat-bubble-left-right chart-pie chart-bar-square calendar-days calculator building-storefront bell-alert arrow-up-on-square
       arrow-trending-down arrows-right-left arrow-right-on-rectangle arrow-path arrow-down-on-square arrow-circle-up arrow-circle-down
       adjustments-horizontal academic-cap film globe-alt bolt gift cake building-library device-phone-mobile wrench shopping-bag].each do |n|
      assert ss_icon?(n), "falta o ícone #{n}"
    end
  end

  test "expressão de valor igual ao AmountExpression do meu-financeiro" do
    e = ComponentesUi::AmountExpression
    assert_equal BigDecimal("57"), e.call("45+12")
    assert_equal BigDecimal("54.5"), e.call("45+12,50-3")
    assert_equal BigDecimal("59.7"), e.call("3*19,90")
    assert_equal BigDecimal("59.7"), e.call("3×19,90")
    assert_equal BigDecimal("1500"), e.call("1.500")
    assert_equal BigDecimal("1234.56"), e.call("R$ 1.234,56")
    assert_equal BigDecimal("12.5"), e.call("12.5")
    assert_equal BigDecimal("5"), e.call("(10+5)/3")
    assert_equal BigDecimal("-3"), e.call("-3")
    assert_nil e.call("1/0")
    assert_nil e.call("45+")
    assert_nil e.call("1,500")
    assert_nil e.call("abc")
    assert_equal 5750, e.cents("45+12,50")
    assert_equal BigDecimal("1234.5"), e.call("1,234.50", decimal: ".")
    assert e.expression?("45+12")
    refute e.expression?("-45")
    assert_equal BigDecimal("57"), ss_amount_expression("45+12")
  end

  test "dinheiro: sinal travado e modo conta" do
    render_inline(Ss::MoneyInputComponent.new(name: "v", label: "Valor", value_cents: 1250))
    assert_selector ".ss-money-input[data-ss-money-signed-value=true]:not(.is-expression)"
    assert_selector "input.ss-money[inputmode=numeric]"
    render_inline(Ss::MoneyInputComponent.new(name: "v", label: "Valor", signed: false, expression: true, currency: "USD", help: "Aceita conta"))
    assert_selector ".ss-money-input.is-expression[data-ss-money-expression-value=true][data-ss-money-signed-value=false][data-ss-money-currency-value=USD]"
    assert_selector "input.ss-money[inputmode=decimal][data-action*='blur->ss-money#settle']"
    assert_selector "small.ss-money-result[aria-live=polite][data-ss-money-target=result]"
    id = page.find("input.ss-money")[:id]
    assert_equal "#{id}-help #{id}-result", page.find("input.ss-money")["aria-describedby"]
    js = JS.join("ss_intl.js").read
    assert_includes js, "export function ssAmountExpression"
    assert_includes JS.join("ss_money_controller.js").read, "ssAmountExpression"
  end

  test "seletor de mês: setas, volta ao atual, trava e frame" do
    render_inline(Ss::MonthSwitcherComponent.new(month: "2026-10", today: Date.new(2026, 11, 9), url: ->(m) { "/l?m=#{m.strftime("%Y-%m")}" }, frame: "lista"))
    assert_selector "nav.ss-month-switcher[aria-label='Mês'][data-controller=ss-month-switcher]"
    assert_selector "a[rel=prev][href='/l?m=2026-09'][data-turbo-frame=lista][data-turbo-action=advance][data-ss-month-dir=prev]"
    assert_selector "a[rel=next][href='/l?m=2026-11'][data-ss-month-dir=next]"
    assert_selector "a.ss-month-switcher-title.is-link[href='/l?m=2026-11']", text: "Outubro 2026"
    render_inline(Ss::MonthSwitcherComponent.new(month: Date.new(2026, 11, 20), today: Date.new(2026, 11, 1), max: "2026-11", url: ->(m) { "/x/#{m.month}" }))
    assert_selector "span.ss-month-switcher-title[aria-current=date]", text: "Novembro 2026"
    assert_selector "span.ss-month-switcher-arrow[aria-disabled=true]"
    assert_no_selector "a[rel=next]"
    assert_equal Date.new(2026, 3, 1), Ss::MonthSwitcherComponent.parse("2026-03")
  end

  test "diálogo: cabeçalho, frame, rodapé e fechar ao enviar" do
    render_inline(Ss::DialogComponent.new(id: "novo", title: "Novo lançamento", subtitle: "Despesa", frame_id: "dialogo", size: :lg, icon: ss_icon("plus", size: nil))) do |d|
      d.with_footer { "<button class='ss-btn'>Salvar</button>".html_safe }
      "Carregando…"
    end
    assert_selector "dialog#novo.ss-sheet.ss-dialog-panel.is-lg[aria-labelledby=novo-title][aria-describedby=novo-sub][data-controller=ss-dialog]", visible: :all
    assert_selector "dialog[data-ss-dialog-close-on-submit-value=true][data-action*='turbo:submit-end->ss-dialog#submitted']", visible: :all
    assert_selector "h2#novo-title", text: "Novo lançamento", visible: :all
    assert_selector ".ss-dialog-panel-head .ss-icon-tile svg", visible: :all
    assert_selector "turbo-frame#dialogo[data-ss-dialog-target=frame]", text: "Carregando…", visible: :all
    assert_selector "footer.ss-dialog-panel-foot .ss-btn", visible: :all
    render_inline(Ss::DialogComponent.new(id: "x", title: "Sem frame", close_on_submit: false)) { "corpo" }
    assert_selector "dialog#x[data-ss-dialog-close-on-submit-value=false] .ss-dialog-panel-body", text: "corpo", visible: :all
    assert_selector "#x-sub[hidden]", visible: :all
  end

  test "barras: agrupadas, empilhadas, negativas e linha" do
    render_inline(Ss::BarChartComponent.new(title: "Mês", labels: %w[jan fev mar],
      series: [{ name: "Receitas", values: [100, 200, 150], tone: :success }, { name: "Despesas", values: [-80, -250, -90], tone: :danger }],
      line: { name: "Saldo", values: [20, -50, 60] }))
    assert_selector "figure.ss-barc:not(.is-stacked) svg"
    assert_selector ".ss-barc-g", count: 3
    assert_selector "rect.ss-barc-bar", count: 6
    assert_selector "rect.ss-barc-bar.is-neg", count: 3
    assert_selector "rect.ss-barc-bar[style*='var(--success)']", count: 3
    assert_selector "line.ss-barc-zero", count: 1
    assert_selector "path.ss-barc-line"
    assert_selector "circle.ss-barc-dot", count: 3
    assert_selector ".ss-barc-legend li", count: 3
    assert_selector ".ss-barc-legend li.is-line", text: "Saldo"
    assert_selector "table.ss-sr th", text: "Despesas"
    assert_selector ".ss-barc-g title", text: /fev\s+Receitas: 200\s+Despesas: -250\s+Saldo: -50/, visible: :all
    render_inline(Ss::BarChartComponent.new(title: "Pilha", labels: %w[a b], stacked: true, legend: false,
      series: [{ name: "x", values: [1, 2] }, { name: "y", values: [3, nil] }]))
    assert_selector "figure.ss-barc.is-stacked rect.ss-barc-bar", count: 3
    assert_selector "rect.ss-barc-bar[style*='var(--series-1)']"
    assert_no_selector ".ss-barc-legend"
    c = Ss::BarChartComponent.new(title: "t", labels: %w[a], stacked: true, series: [{ name: "x", values: [2] }, { name: "y", values: [3] }])
    assert_equal [0.0, 5.4], c.range.map { _1.round(2) }
  end

  test "linha de progresso: tons de limite e meta" do
    render_inline(Ss::ProgressRowComponent.new(label: "Mercado", value: 500, limit: 1000))
    assert_selector ".ss-progress-row[data-tone=ok][data-kind=limit]"
    assert_selector ".ss-progress-row-pct", text: "50%"
    assert_selector ".ss-progress[role=progressbar][aria-valuenow='50'] .ss-progress-bar[style*='width:50.0%']"
    assert_selector ".ss-progress-row-foot", text: "500 de 1.000"
    assert_selector ".ss-progress-row-foot", text: "Restam 500"
    render_inline(Ss::ProgressRowComponent.new(label: "Lazer", value: 850, limit: 1000))
    assert_selector ".ss-progress-row[data-tone=warn]"
    render_inline(Ss::ProgressRowComponent.new(label: "Bar", value: 1200, limit: 1000, href: "/c/1", format: ->(v) { "R$ #{v.to_i}" }))
    assert_selector "a.ss-progress-row.is-link[href='/c/1'][data-tone=over]"
    assert_selector ".ss-progress[aria-valuenow='100'] .ss-progress-bar[style*='width:100.0%']"
    assert_selector ".ss-progress-row-foot", text: "R$ 200 acima"
    render_inline(Ss::ProgressRowComponent.new(label: "Viagem", value: 3000, limit: 3000, kind: :goal, icon: ss_icon("globe-alt", size: nil)))
    assert_selector ".ss-progress-row[data-tone=done][data-kind=goal] .ss-progress-row-ico svg"
    assert_selector ".ss-progress-row-foot", text: "Meta batida"
    render_inline(Ss::ProgressRowComponent.new(label: "Carro", value: 1000, limit: 4000, kind: :goal, color: "var(--series-3)"))
    assert_selector ".ss-progress-row-foot", text: "Faltam 3.000"
    assert_selector ".ss-progress-bar[style*='background:var(--series-3)']"
  end

  test "seção de formulário" do
    render_inline(Ss::FormSectionComponent.new(title: "Recorrência", help: "Repete todo mês", divider: true, columns: 2)) { "<input name='a'>".html_safe }
    assert_selector "fieldset.ss-fieldset.ss-form-section.is-divided[style='--ss-form-cols:2']"
    assert_selector "legend.ss-form-section-title", text: "Recorrência"
    help = page.find("small.ss-field-help")[:id]
    assert_selector "fieldset[aria-describedby='#{help}']"
    assert_selector ".ss-form-section-body.is-cols input[name=a]"
    render_inline(Ss::FormSectionComponent.new(title: "Simples")) { "x" }
    assert_selector "fieldset.ss-form-section:not(.is-divided):not([aria-describedby]) .ss-form-section-body:not(.is-cols)"
  end

  test "chat: mensagens, pensando, envio e cartão de ação" do
    render_inline(Ss::ChatComponent.new(id: "ia", url: "/ia/mensagens", placeholder: "Pergunte")) do |chat|
      chat.with_message(from: :me, text: "Gastei 45 no mercado", time: "14:05")
      chat.with_message(from: :ai, text: "Posso lançar?\n\nConfira os dados.")
    end
    assert_selector "section#ia.ss-chat-panel[data-controller=ss-chat][data-ss-chat-echo-value=true]"
    assert_selector "#ia-messages.ss-chat[role=log][aria-live=polite]"
    assert_selector ".ss-bubble.is-me[data-from=me]", text: "Gastei 45 no mercado"
    assert_selector ".ss-bubble.is-me small", text: "14:05"
    assert_selector ".ss-bubble.is-ai p", count: 2
    assert_selector ".ss-thinking[hidden][role=status][aria-label=Pensando]", visible: :all
    assert_selector "form.ss-chat-form[action='/ia/mensagens'][method=post] textarea[name=message][required][placeholder=Pergunte]"
    assert_selector "button.ss-chat-send[aria-label=Enviar]"
    assert_equal "ia-messages", Ss::ChatComponent.messages_id("ia")
    render_inline(Ss::ChatComponent.new(id: "v", url: "/m", thinking: true)) { |c| c.with_empty { "Pergunte sobre seus gastos" } }
    assert_selector ".ss-chat-empty", text: "Pergunte sobre seus gastos"
    assert_selector ".ss-thinking:not([hidden])"

    render_inline(Ss::ChatActionComponent.new(id: "acao-1", title: "Lançar despesa", rows: [["Valor", "R$ 45,00"], ["Cartão", "Nubank"]],
                                              confirm_url: "/acoes/1/confirmar", cancel_url: "/acoes/1/cancelar", icon: ss_icon("credit-card", size: nil)))
    assert_selector "article#acao-1.ss-chat-action.is-pending[aria-labelledby=acao-1-t][data-controller=ss-chat-action]"
    assert_selector ".ss-chat-action-kicker", text: "Ação proposta"
    assert_selector "dl.ss-chat-action-rows dt", text: "Cartão"
    assert_selector "dl.ss-chat-action-rows dd", text: "R$ 45,00"
    assert_selector "form.ss-chat-action-form[action='/acoes/1/confirmar'] button.ss-btn-primary", text: "Confirmar"
    assert_selector "form.ss-chat-action-form[action='/acoes/1/cancelar'] button.ss-btn-ghost", text: "Cancelar"
    render_inline(Ss::ChatActionComponent.new(id: "acao-1", title: "Lançar despesa", state: :confirmed))
    assert_selector ".ss-chat-action.is-confirmed .ss-chat-action-result[data-tone=success][role=status]", text: "Feito"
    assert_no_selector ".ss-chat-action-btns"
    render_inline(Ss::ChatActionComponent.new(title: "Excluir", state: :failed, result: "Sem permissão", danger: true))
    assert_selector ".ss-chat-action.is-failed.is-danger .ss-chat-action-result[data-tone=danger]", text: "Sem permissão"
  end

  test "confete: automático com chave e por clique" do
    render_inline(Ss::ConfettiComponent.new(key: "meta-1"))
    assert_selector "span.ss-confetti[hidden][data-controller=ss-confetti][data-ss-confetti-key-value=meta-1][data-ss-confetti-auto-value=true]", visible: :all
    render_inline(Ss::ConfettiComponent.new(on: :click)) { "<button data-action='ss-confetti#burst'>Pagar</button>".html_safe }
    assert_selector "span.ss-confetti:not([hidden])[data-ss-confetti-auto-value=false] button", text: "Pagar"
    assert_includes JS.join("ss_confetti_controller.js").read, "prefers-reduced-motion"
  end

  test "css da v0.15 importado" do
    css = CSS.join("v15_web.css").read
    [":where(.ss-icon.is-xs)", ".ss-month-switcher-title", ".ss-dialog-panel-head", "dialog.ss-dialog-panel.is-closing", ".ss-barc-bar.is-neg",
     ".ss-barc-line", ".ss-money-input.is-expression", ".ss-progress-row[data-tone=\"over\"]", ".ss-form-section.is-divided",
     ".ss-chat-action-rows", ".ss-chat-form", ".ss-confetti", "[data-privacy=\"on\"]", "prefers-reduced-motion"].each { assert_includes css, _1 }
    assert_includes CSS.join("engine.css").read, '@import "./v15_web.css";'
    %w[ss_dialog ss_month_switcher ss_chat ss_chat_action ss_confetti].each { assert JS.join("#{_1}_controller.js").exist?, _1 }
  end
end
