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
  #
  # v0.18 (o que o modal do meu-financeiro fazia à mão):
  # - Ficar aberto depois de salvar: data-ss-dialog-keep-open no <form> ou no botão que enviou
  #   ("Salvar e criar outro"); a resposta (o redirect para o formulário limpo) carrega no frame.
  #   Fechar depois disso recarrega a página de trás (Turbo.visit da URL atual, action: "replace"),
  #   porque algo foi salvo; um elemento [data-ss-dialog-refresh] (ou o antigo
  #   [data-modal-refresh-on-close]) na resposta faz o mesmo. refresh_on_close: true recarrega
  #   sempre que fechar depois de um envio que deu certo.
  # - Resposta sem o frame (turbo:frame-missing, ex. um redirect para uma página inteira): fecha e
  #   segue a URL numa visita normal (follow_missing: false volta ao erro do Turbo).
  # - Fechar: Esc, X, clique no fundo e qualquer [data-ss-dialog-dismiss] clicado dentro (o "Cancelar"
  #   do Ss::FormActionsComponent, o X de um cabeçalho que veio na resposta); data-action="ss-dialog#close"
  #   também. ([data-ss-dialog-close] continua sendo "fechar ao carregar esta resposta".)
  # - global: true = o "frame global do layout": um diálogo só no layout (frame_id: "modal" por
  #   padrão) que qualquer link com data-turbo-frame="modal" abre, de qualquer tela. Abre quando o
  #   frame recebe conteúdo (link, formulário ou turbo-stream), fecha quando o frame esvazia e limpa o
  #   frame ao fechar (clear_on_close:, padrão = global). header: false tira o cabeçalho (quando a
  #   resposta traz o dela; o nome lido vem de title: ou do 1º h2 da resposta).
  #   Antes do cache do Turbo o diálogo fecha (voltar não mostra o formulário aberto).
  class DialogComponent < BaseComponent
    SIZES = %i[sm md lg].freeze
    renders_one :footer

    attr_reader :id, :title, :subtitle

    def initialize(id:, title: nil, subtitle: nil, icon: nil, frame_id: nil, open: false, size: :md, close_on_submit: true,
                   close_label: nil, global: false, header: true, clear_on_close: nil, refresh_on_close: false,
                   follow_missing: true, **rest)
      super(**rest)
      @global = global
      frame_id ||= "modal" if global
      @id, @title, @subtitle, @icon, @frame_id, @open = id, title, subtitle, icon, frame_id, open
      @size = SIZES.include?(size.to_s.to_sym) ? size.to_s.to_sym : :md
      @close_on_submit = close_on_submit
      @close_label = close_label
      @header = header
      @clear_on_close = clear_on_close.nil? ? global : clear_on_close
      @refresh_on_close, @follow_missing = refresh_on_close, follow_missing
    end

    def header? = @header != false
    def global? = @global

    def frame_id = @frame_id
    def icon = @icon.presence&.to_s&.html_safe
    def close_label = @close_label || ss_t("common.close", default: "Fechar")

    def dialog_attrs
      root_attrs(id:, class: classes("ss-sheet", "ss-dialog-panel", "is-#{@size}", ("is-headless" unless header?)),
                 "aria-labelledby": (header? ? "#{id}-title" : nil), "aria-label": (header? ? nil : title),
                 "aria-describedby": (header? && subtitle ? "#{id}-sub" : nil),
                 data: { controller: "ss-dialog", ss_dialog_open_value: @open, ss_dialog_close_on_submit_value: @close_on_submit,
                         ss_dialog_global_value: (true if @global), ss_dialog_clear_value: (true if @clear_on_close),
                         ss_dialog_refresh_value: (true if @refresh_on_close),
                         ss_dialog_follow_missing_value: (false unless @follow_missing),
                         action: "turbo:before-fetch-request->ss-dialog#loading turbo:frame-load->ss-dialog#loaded " \
                                 "turbo:submit-end->ss-dialog#submitted turbo:frame-missing->ss-dialog#missing " \
                                 "click->ss-dialog#backdrop click->ss-dialog#closer" }.compact)
    end
  end
end
