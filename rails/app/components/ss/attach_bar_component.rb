module Ss
  # Fileira de botões quadrados coloridos com ícone para anexar (v1.10, par do SsAttachBar): foto, documento,
  # contato, local. Entram em cascata crescendo com a mola; o ícone fica escuro quando o fundo é claro.
  #
  #   render Ss::AttachBarComponent.new(items: [
  #     { icon: "camera", label: "Foto", accept: "image/*", name: "anexo[foto]" },            # <label> com <input type=file>
  #     { icon: "document-text", label: "Arquivo", accept: ".pdf", name: "anexo[arquivo]", form: "f-chat" },
  #     { icon: "location-marker", label: "Local", href: local_path },                      # link
  #     { icon: "user", label: "Contato", data: { action: "chat#contato" } }                # <button type=button>
  #   ])
  #
  # Cada item: icon:, label:, e um de accept:/name: (arquivo), href: ou data: (botão). tone: 1..6 (a cor da
  # série; padrão: a ordem) ou color: (cor CSS por token, ex. "var(--success)"). size: px do quadrado (padrão:
  # a altura do controle da densidade + 8, 56 no padrão). Cada botão tem o rótulo como nome e o alvo ≥ 44.
  class AttachBarComponent < BaseComponent
    # Séries de fundo claro: o ícone vai em --ink.
    LIGHT_TONES = [5].freeze

    def initialize(items:, size: nil, **rest)
      super(**rest)
      @items = Array(items).map { |i| i.to_h.symbolize_keys }
      @size = size&.to_i&.clamp(44, 120)
    end

    def call
      tag.div(**root_attrs(class: classes("ss-attach"), role: "group", style: (@size ? "--s:#{@size}px" : nil))) do
        safe_join(@items.each_with_index.map { |it, i| item(it, i) })
      end
    end

    private

    def item(it, i)
      tone = (it[:tone] || (i % 6) + 1).to_i.clamp(1, 6)
      style = ["--i:#{[i, 8].min}", ("--c:#{it[:color]}" if it[:color])].compact.join(";")
      cls = ["ss-attach-item", ("is-light" if !it[:color] && LIGHT_TONES.include?(tone))].compact.join(" ")
      body = safe_join([tag.span(ss_icon(it[:icon], size: nil), class: "ss-attach-sq", "aria-hidden": "true"),
                        tag.span(it[:label], class: "ss-attach-label")])
      data = { tone: (it[:color] ? nil : tone) }
      if it[:accept] || it[:name]
        tag.label(class: cls, style:, data:) do
          safe_join([body, tag.input(type: "file", class: "ss-attach-file", accept: it[:accept], name: it[:name], form: it[:form],
                                     multiple: it[:multiple] || nil, "aria-label": it[:label])])
        end
      elsif it[:href]
        link_to(body, it[:href], class: cls, style:, data: data.merge(it[:data].to_h), "aria-label": it[:label])
      else
        tag.button(body, type: :button, class: cls, style:, data: data.merge(it[:data].to_h), "aria-label": it[:label],
                         disabled: it[:disabled] || nil)
      end
    end
  end
end
