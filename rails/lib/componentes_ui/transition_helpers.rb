module ComponentesUi
  # v1.9 · transições: lista → detalhe com a View Transitions API (par do SsOpenContainer do Flutter).
  # O card da lista e o cabeçalho do detalhe levam o mesmo view-transition-name; na navegação do
  # Turbo (com o <meta name="view-transition" content="same-origin"> no <head>) o navegador faz o
  # card "virar" o cabeçalho. Sem suporte do navegador, ou com prefers-reduced-motion, é o corte normal.
  #
  #   <head> … <%= ss_view_transitions_head %> … </head>
  #   lista:   <%= link_to pedido_path(p), class: "ss-card", **ss_view_transition_attrs(p) do %> … <% end %>
  #   detalhe: <%= render Ss::PageComponent.new(title: "Pedido #{p.numero}", view_transition: p) %>
  #
  # O nome é único por registro e parte (ss-pedido-12-card); o mesmo nome não pode aparecer duas
  # vezes na mesma tela (o navegador cancela a transição).
  module TransitionHelpers
    # Nome da transição de um registro (ActiveRecord, qualquer objeto com to_param, ou texto).
    def ss_view_transition_name(record, part = :card)
      base =
        if record.respond_to?(:model_name) && record.respond_to?(:to_param)
          "#{record.model_name.param_key}-#{record.to_param}"
        else
          record.to_s
        end
      "ss-#{base}-#{part}".downcase.gsub(/[^a-z0-9_-]+/, "-").gsub(/-{2,}/, "-").delete_suffix("-")
    end

    # Atributos para o elemento que voa (style + data-ss-vt, que liga a curva da parte).
    # part: :card (o card vira o cabeçalho), :title, :image.
    def ss_view_transition_attrs(record, part = :card)
      { style: "view-transition-name: #{ss_view_transition_name(record, part)}", data: { ss_vt: part.to_s } }
    end

    # <meta> que liga as View Transitions do Turbo (8+) entre páginas da mesma origem.
    def ss_view_transitions_head
      %(<meta name="view-transition" content="same-origin">).html_safe
    end
  end
end
