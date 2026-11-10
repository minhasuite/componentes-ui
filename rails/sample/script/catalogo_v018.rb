# Gera as <section> do catálogo (rails/catalogo/index.html) para as peças da v0.18.
#   bin/rails runner script/catalogo_v018.rb > /tmp/v018.html
include ComponentesUi::Helpers
require "action_dispatch/testing/test_request"
CTRL = ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create("PATH_INFO" => "/vitrine/x"); c.response = ActionDispatch::Response.new }
def view = (@view ||= CTRL.view_context)
def r(c, &blk) = view.render(c, &blk).to_s.gsub(/<!-- (BEGIN|END) [^>]*-->/, "").gsub(/\n\s*/, "")
def esc(s) = ERB::Util.h(s)
def section(slug, nome, desc, comps, estados)
  out = +%(<section data-comp="#{slug}" data-nome="#{esc(nome)}" data-descricao="#{esc(desc)}"\n  data-comportamentos='#{esc(comps.to_json)}'>\n)
  estados.each { |(s, t, html)| out << %(  <div data-estado="#{s}" data-titulo="#{esc(t)}">#{html}</div>\n) }
  out << "</section>\n"
end
Row = Struct.new(:id, :nome, :saldo, keyword_init: true)
items = [{ label: "Novo lançamento", icon: "plus", href: "#" }, { label: "Assistente", icon: "chat-bubble-left-right", action: "x#y" }]
open_dial = r(Ss::SpeedDialComponent.new(items:, static: true, id: "cat-sd")).sub(' hidden="hidden"', "").sub('aria-expanded="false"', 'aria-expanded="true"')
out = +""
out << section("ss-speed-dial", "Ss::SpeedDialComponent", "Botão flutuante com várias ações (v0.18, par do SsSpeedDial): o + no canto abre a lista de ações acima dele.",
  ["Toque no + abre a lista (rótulo + ícone) e o + gira 45° (vira ×); as ações sobem com a mola, a de baixo primeiro.", "Esc fecha e devolve o foco ao botão; clique fora, Tab para fora e escolher uma ação fecham.",
   "↑ ↓ Home End movem o foco entre as ações; aria-expanded, aria-haspopup=menu e role=menu/menuitem.", "Com uma ação só vira o Ss::FabComponent dela. Mesmo lugar do botão flutuante: área segura, acima da .ss-sticky-bar, lift:.",
   "Reduzir movimento: sem a mola e sem o giro."],
  [["fechado", "fechado", r(Ss::SpeedDialComponent.new(items:, static: true, id: "cat-sd0"))],
   ["aberto", "aberto (duas ações)", %(<div style="padding:8px 8px 0">#{open_dial}</div>)]])
out << section("ss-row-actions", "Ss::RowActionsComponent · t.actions", "Ações no fim da linha (v0.18): no computador aparecem no hover ou no foco da linha; no toque, sempre à vista.",
  ["@media (hover: hover) and (pointer: fine): só com mouse/trackpad as ações ficam com opacity 0 até o hover ou o foco na linha (tr, li, .ss-item, .ss-card, [data-ss-row]).",
   "No toque (celular, tablet) ficam sempre à vista; com o menu (popover/details) aberto também.", "edit: abre no diálogo global (data-turbo-frame=modal); destroy: DELETE com data-turbo-confirm.",
   "No DataTable: t.actions { |row| … } é a última coluna, com o cabeçalho só para o leitor de tela."],
  [["tabela", "linha com Editar e Remover (como no toque)", %(<div style="width:520px">#{r(Ss::DataTableComponent.new(rows: [Row.new(id: 1, nome: "Nubank", saldo: 1234.5)], id: "cat-ra", caption: "Contas", tools: false)) { |t| t.column(:nome, "Nome"); t.column(:saldo, "Saldo", format: :money); t.actions { |_| view.render(Ss::RowActionsComponent.new(edit: "#", destroy: "#", reveal: false)) } }}</div>)],
   ["icones", "só ícones", r(Ss::RowActionsComponent.new(edit: "#", destroy: "#", icons: true, reveal: false))]])
out << section("ss-dt-v18", "Ss::DataTableComponent(row_attrs:, empty_art: false)", "Tabela com atributos por linha e o vazio compacto (v0.18).",
  ["row_attrs: Hash ou ->(row) { { id:, data:, class: } } vai em cada <tr>.", "empty_art: false: só a frase do vazio, sem a ilustração (tabela dentro de um card)."],
  [["vazio", "vazio compacto", %(<div style="width:420px">#{r(Ss::DataTableComponent.new(rows: [], id: "cat-dt", caption: "Contas", tools: false, empty: "Nenhuma conta ainda.", empty_art: false)) { |t| t.column(:nome, "Nome"); t.column(:saldo, "Saldo") }}</div>)]])
out << section("ss-form-actions", "Ss::FormActionsComponent · Ss::FormErrorsComponent", "Rodapé do formulário e o resumo dos erros (v0.18).",
  ["Cancelar (fantasma) + extras do bloco + o botão que envia, à direita; o envio mostra “Salvando…” (data-turbo-submits-with).", "No Ss::DialogComponent fica preso no fim do painel e o Cancelar fecha o diálogo (data-ss-dialog-dismiss).",
   "data-ss-dialog-keep-open num botão (“Salvar e criar outro”) mantém o diálogo aberto e recarrega a página de trás ao fechar.", "FormErrors: callout de perigo (role=alert) com “Confira os campos” e a lista; some sem erro."],
  [["rodape", "erros + rodapé", %(<div style="width:440px" class="ss-card ss-card-pad">#{r(Ss::FormErrorsComponent.new(errors: ["Nome não pode ficar em branco", "Valor inválido"]))}#{r(Ss::FormActionsComponent.new(sticky: false)) { %(<button type="button" class="ss-btn ss-btn-outline">Salvar e criar outro</button>).html_safe }}</div>)]])
banks = [{ id: 1, label: "Nubank", icon: "credit-card", color: "#8a05be" }, { id: 2, label: "Inter", icon: "office-building", color: "#ff7a00" }]
out << section("ss-combobox-media", "Ss::ComboboxComponent(options: [{ icon:, image:, color: }])", "Combobox com ícone ou imagem por opção (v0.18): logo do banco, ícone do perfil.",
  ["icon: (nome do ss_icon, pintado por color:) ou image: (URL) antes do rótulo, na lista e no campo (a escolhida).", "input: {} passa title:, data:, aria: ao <input> visível."],
  [["escolhida", "com a escolhida", %(<div style="width:320px">#{r(Ss::ComboboxComponent.new(name: "b", label: "Banco", id: "cat-cb", options: banks, value: 2, text: "Inter"))}</div>)]])
out << section("ss-icon-button", "Ss::IconButtonComponent · Ss::PrivacyToggleComponent", "Botão só de ícone e o de alternar (v0.18); o olho de esconder valores (par do SsPrivacyToggle).",
  ["label: é o nome lido e a dica; pressed: põe aria-pressed e, com pressed_icon:, troca o ícone pelo estado.", "PrivacyToggle: data-action=ss-privacy#toggle, aria-pressed sincronizado pelo controller, dica “Ocultar valores (P)”.",
   "Foco visível; ligado na cor da marca."],
  [["botoes", "editar · alternar (desligado, ligado) · olho", %(<div style="display:flex;gap:8px;align-items:center">#{r(Ss::IconButtonComponent.new(icon: "pencil", label: "Editar"))}#{r(Ss::IconButtonComponent.new(icon: "bell", pressed_icon: "x", label: "Silenciar", pressed: false, variant: :tonal))}#{r(Ss::IconButtonComponent.new(icon: "bell", pressed_icon: "x", label: "Silenciar", pressed: true, variant: :tonal))}#{r(Ss::PrivacyToggleComponent.new)}#{r(Ss::PrivacyToggleComponent.new(text: true))}</div>)]])
out << section("ss-on-accent", "text-on-accent · bg-grad", "Cores sobre a marca como utilitários do Tailwind (v0.18): texto e véus sobre o gradiente sem text-white solto.",
  ["text-on-accent (e /80, /60) para texto sobre o gradiente ou o accent sólido; bg-on-accent/15 e ring-on-accent/25 para véus.", "bg-grad: o gradiente da marca com o texto claro; também bg-accent-solid, text-info, bg-info-soft."],
  [["heroi", "herói", %(<div class="bg-grad" style="width:360px;padding:20px;border-radius:20px"><p style="font-weight:800;font-size:1.4rem">R$ 1.234,56</p><p class="text-on-accent/80" style="color:color-mix(in srgb,var(--on-accent) 80%,transparent)">livre para gastar no mês</p></div>)]])
print out
