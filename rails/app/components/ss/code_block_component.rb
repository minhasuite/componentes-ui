module Ss
  # Texto técnico em DM Mono (v0.10.2, par do SsCodeBlock): log, YAML, chave de integração,
  # resposta da API. copy: true (padrão) põe o botão de copiar no canto (ss-copy: o ✓ fica 2 s);
  # terminal: true usa o fundo escuro fixo; max_height: ("24rem") rola; wrap: false rola de lado.
  #
  #   render Ss::CodeBlockComponent.new(text: @token, terminal: false)
  #   render Ss::CodeBlockComponent.new(text: log, terminal: true, max_height: "60vh")
  class CodeBlockComponent < BaseComponent
    COPY = %(<svg class="ss-code-idle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/></svg>).freeze
    DONE = %(<svg class="ss-code-done" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>).freeze

    def initialize(text:, copy: true, terminal: false, max_height: nil, wrap: true, label: nil, **opts)
      super(**opts)
      @text, @copy, @terminal, @max_height, @wrap, @label = text.to_s, copy, terminal, max_height, wrap, label
    end

    def copy_label = ss_t("code_block.copy", default: "Copiar")
    def copied_label = ss_t("code_block.copied", default: "Copiado")

    def call
      pre = tag.pre(tag.code(@text), class: ["ss-code", ("is-terminal" if @terminal), ("is-nowrap" unless @wrap)].compact.join(" "),
                    tabindex: (0 if @max_height || !@wrap), "aria-label": @label)
      style = [("--ss-code-max: #{@max_height}" if @max_height), @attrs[:style]].compact.join("; ").presence
      return tag.div(pre, **root_attrs(class: classes("ss-code-wrap"), style:)) unless @copy

      tag.div(**root_attrs(class: classes("ss-code-wrap"), style:,
                           data: { controller: "ss-copy", ss_copy_text_value: @text, ss_copy_done_value: copied_label })) do
        safe_join([pre, tag.button(safe_join([COPY.html_safe, DONE.html_safe, tag.span(copy_label, class: "ss-sr", data: { ss_copy_target: "label" })]),
                                   type: "button", class: "ss-icon-btn is-sm ss-code-copy", title: copy_label,
                                   data: { action: "ss-copy#copy", ss_copy_target: "button" })])
      end
    end
  end
end
