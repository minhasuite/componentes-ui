module Ss
  # Cartão físico (v0.19, par do SsWalletCard): o retângulo de cartão de crédito (1,586:1) no gradiente
  # da marca, com chip, bandeira, final do número, nome e um valor (fatura, saldo). Inclina de leve
  # seguindo o mouse e o brilho acompanha (controller ss-tilt; nada no toque nem com menos movimento).
  #
  #   render Ss::WalletCardComponent.new(amount: ss_money(1234.5), label: "Fatura", holder: "Nubank",
  #                                      number: "4086", href: cartao_path(c)) { image_tag("visa.svg") }
  #
  # amount: valor já formatado (o modo privacidade borra); label: o rótulo dele (padrão "Saldo total");
  # holder: o nome no cartão, com holder_label: em cima (padrão "Cartão"); number: o final (só os 4
  # dígitos; sai "•••• •••• •••• 4086"); network: a bandeira em texto quando não há logo; expiry:;
  # o bloco é o logo da bandeira (vai numa placa clara no canto). colors: ["#1a1f71", "#3b82f6"] troca o
  # gradiente pelas cores do cartão (dado do usuário/da bandeira, vai inline como variável); sem ele, a
  # marca. href: o cartão vira link (aria-label: "Abrir …"). tilt: false desliga a inclinação.
  class WalletCardComponent < BaseComponent
    def initialize(amount: nil, label: nil, holder: nil, holder_label: nil, number: nil, network: nil, expiry: nil,
                   colors: nil, href: nil, tilt: true, **rest)
      super(**rest)
      @amount, @holder, @number, @network, @expiry, @href, @tilt = amount, holder, number, network, expiry, href, tilt
      @label = label || ss_t("wallet_card.balance", default: "Saldo total")
      @holder_label = holder_label || ss_t("wallet_card.card", default: "Cartão")
      @colors = Array(colors).map(&:to_s).select { _1.match?(ComponentesUi::HEX) || _1.match?(/\A#\h{3}\z/) }.first(2)
    end

    def call
      style = (@colors.size == 2 ? "--ss-wc-1: #{@colors[0]}; --ss-wc-2: #{@colors[1]}" : nil)
      data = @tilt ? { controller: [@attrs.dig(:data, :controller), "ss-tilt"].compact.join(" ") } : {}
      attrs = root_attrs(class: classes("ss-wallet-card", ("has-colors" if style)), style:, data:)
      inner = safe_join([top, number_row, foot])
      return link_to(@href, **attrs, "aria-label": @attrs[:"aria-label"] || [@holder, @number].compact.join(" ")) { inner } if @href

      tag.div(**attrs) { inner }
    end

    private

    def top
      logo = if content.present? then tag.span(content, class: "ss-wallet-card-logo")
             elsif @network.present? then tag.span(@network.to_s.upcase, class: "ss-wallet-card-network")
             end
      tag.div(safe_join([tag.span(class: "ss-wallet-card-chip", "aria-hidden": "true"),
                         (tag.span(@expiry, class: "ss-wallet-card-expiry num") if @expiry), logo].compact), class: "ss-wallet-card-top")
    end

    def number_row
      return "".html_safe if @number.blank? && @holder.blank? && @amount.blank?

      digits = @number.presence || "••••"
      tag.p("•••• •••• •••• #{digits}", class: "ss-wallet-card-number num")
    end

    def foot
      left = (tag.div(safe_join([tag.span(@holder_label, class: "ss-wallet-card-k"), tag.span(@holder, class: "ss-wallet-card-v")])) if @holder)
      right = (tag.div(safe_join([tag.span(@label, class: "ss-wallet-card-k"), tag.span(@amount, class: "ss-wallet-card-v money num")]), class: "is-end") if @amount)
      tag.div(safe_join([left || tag.span, right].compact), class: "ss-wallet-card-foot")
    end
  end
end
