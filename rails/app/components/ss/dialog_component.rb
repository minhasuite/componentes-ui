module Ss
  # Diálogo genérico (v0.15, par do showSsSheet/SsSheet): um <dialog> com cabeçalho (ícone,
  # título, subtítulo, X), corpo livre ou num turbo-frame e rodapé de ações. Folha de baixo no
  # celular e caixa no centro no desktop (o .ss-sheet). É o modal de formulário da suíte:
  #
  #   <%= render Ss::DialogComponent.new(id: "novo-lancamento", title: "Novo lançamento", frame_id: "dialogo") %>
  #   <%= link_to "Novo", new_lancamento_path, data: { turbo_frame: "dialogo" } %>   (abre e carrega)
  #   <button data-ss-dialog-open="novo-lancamento">Abrir</button>                    (abre o que já tem)
  #
  # Na resposta do frame, <turbo-frame id="dialogo" data-dialog-title="Editar" data-dialog-subtitle="…">
  # troca o título; um elemento [data-ss-dialog-close] dentro do frame fecha o diálogo. Envio do
  # formulário dentro dele que deu certo (2xx/3xx) fecha sozinho (close_on_submit: false desliga);
  # 422 com o formulário de novo fica aberto, com o erro. Esc, X e clique no fundo fecham.
  # Por JS: elemento.ssDialog.open() / .close().
  #
  # size: :sm (25rem), :md (32rem, padrão), :lg (44rem). icon: svg (ss_icon("plus", size: nil)).
  class DialogComponent < BaseComponent
    SIZES = %i[sm md lg].freeze
    renders_one :footer

    attr_reader :id, :title, :subtitle

    def initialize(id:, title: nil, subtitle: nil, icon: nil, frame_id: nil, open: false, size: :md, close_on_submit: true,
                   close_label: nil, **rest)
      super(**rest)
      @id, @title, @subtitle, @icon, @frame_id, @open = id, title, subtitle, icon, frame_id, open
      @size = SIZES.include?(size.to_s.to_sym) ? size.to_s.to_sym : :md
      @close_on_submit = close_on_submit
      @close_label = close_label
    end

    def frame_id = @frame_id
    def icon = @icon.presence&.to_s&.html_safe
    def close_label = @close_label || ss_t("common.close", default: "Fechar")

    def dialog_attrs
      root_attrs(id:, class: classes("ss-sheet", "ss-dialog-panel", "is-#{@size}"), "aria-labelledby": "#{id}-title",
                 "aria-describedby": (subtitle ? "#{id}-sub" : nil),
                 data: { controller: "ss-dialog", ss_dialog_open_value: @open, ss_dialog_close_on_submit_value: @close_on_submit,
                         action: "turbo:before-fetch-request->ss-dialog#loading turbo:frame-load->ss-dialog#loaded " \
                                 "turbo:submit-end->ss-dialog#submitted click->ss-dialog#backdrop" })
    end
  end
end
