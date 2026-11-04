module Ss
  # Caixa de confirmação da suíte no lugar do confirm() do navegador. Renderize uma vez
  # no layout; com global: true (padrão) o controller ss-confirm-dialog vira o confirm
  # do Turbo (Turbo.config.forms.confirm), e todo data-turbo-confirm abre esta caixa:
  #
  #   <%= render Ss::ConfirmDialogComponent.new(id: "confirmar") %>
  #   <%= button_to "Excluir", item_path(i), method: :delete, form: { data: { turbo_confirm: "Excluir o item?" } } %>
  #
  # No elemento (form, link ou botão que envia) dá para trocar por chamada:
  #   data-turbo-confirm-title="Excluir?"  data-turbo-confirm-button="Excluir"  data-turbo-confirm-tone="danger|warn|default"
  # A mensagem (data-turbo-confirm) vira o texto. Também por JS:
  #   document.getElementById("confirmar").ssConfirm("Sair sem salvar?", { tone: "warn" }).then((ok) => …)
  #
  # tone: :default (destaque da marca), :warn (aviso) ou :danger (botão vermelho).
  class ConfirmDialogComponent < BaseComponent
    TONES = %i[default warn danger].freeze
    ICONS = {
      default: %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path stroke-linecap="round" d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .9-1 1.6v.4M12 17h.01"/></svg>),
      warn: %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path stroke-linejoin="round" d="M10.3 4.3 2.8 17.5A2 2 0 0 0 4.5 20.5h15a2 2 0 0 0 1.7-3L13.7 4.3a2 2 0 0 0-3.4 0z"/><path stroke-linecap="round" d="M12 10v4M12 17h.01"/></svg>),
      danger: %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M4 7h16M10 11v6m4-6v6M6 7l1 13h10l1-13M9 7V4h6v3"/></svg>)
    }.freeze

    attr_reader :id, :tone

    def initialize(id: "ss-confirm-dialog", title: nil, text: nil, ok_label: nil, cancel_label: nil, tone: :default, global: true, **opts)
      super(**opts)
      @id = id
      @title = title
      @text = text
      @ok_label = ok_label
      @cancel_label = cancel_label
      @tone = TONES.include?(tone.to_s.to_sym) ? tone.to_s.to_sym : :default
      @global = global
    end

    def title = @title || ss_t("confirm_dialog.title", default: "Tem certeza?")
    def text = @text
    def ok_label = @ok_label || ss_t("confirm_dialog.ok", default: "Confirmar")
    def cancel_label = @cancel_label || ss_t("confirm_dialog.cancel", default: "Voltar")

    def dialog_attrs
      root_attrs(id:, class: classes("ss-dialog", "ss-confirm-dialog", ("is-#{tone}" unless tone == :default)),
                 "aria-labelledby": "#{id}-t", "aria-describedby": "#{id}-m",
                 data: { controller: "ss-confirm-dialog", ss_confirm_dialog_global_value: @global, ss_confirm_dialog_tone_value: tone,
                         action: "close->ss-confirm-dialog#closed click->ss-confirm-dialog#backdrop" })
    end

    # Os três ícones vão no HTML; o CSS mostra o do tom (o JS troca o tom por chamada).
    def icons = safe_join(ICONS.map { |k, svg| tag.span(svg.html_safe, class: "ss-confirm-dialog-ico", data: { tone: k }) })
  end
end
