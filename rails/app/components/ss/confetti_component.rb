module Ss
  # Comemoração com confete (v0.15, par do showSsConfetti): canvas por cima da tela, cores da
  # marca e das séries, ~2,6 s, nada com "reduzir movimento". Só em conquista (meta batida,
  # fatura paga, 1º lançamento): no máximo um por tela.
  #
  #   <%= render Ss::ConfettiComponent.new(key: "meta-#{meta.id}") if meta.batida? %>   (dispara ao aparecer, uma vez por key)
  #   <%= render(Ss::ConfettiComponent.new(on: :click)) do %><button data-action="ss-confetti#burst">Pagar</button><% end %>
  #
  # key: lembra no navegador (localStorage "ss-celebrated:<key>") e não repete. on: :connect
  # (padrão) ou :click (só pelo data-action). Por JS: window.ssConfetti().
  class ConfettiComponent < BaseComponent
    def initialize(key: nil, on: :connect, **rest)
      super(**rest)
      @key, @on = key, on.to_s == "click" ? "click" : "connect"
    end

    def call
      inner = content
      tag.span(**root_attrs(class: classes("ss-confetti"), hidden: inner.blank?, "aria-hidden": (inner.blank? ? "true" : nil),
                            data: { controller: "ss-confetti", ss_confetti_key_value: @key, ss_confetti_auto_value: @on == "connect" }.compact)) { inner }
    end
  end
end
