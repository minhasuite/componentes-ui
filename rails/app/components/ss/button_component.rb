module Ss
  # Botão da suíte (v0.19, par do SsButton): o .ss-btn como componente, para o produto não escrever
  # <button> à mão nem button_to com classe. Um só para os três jeitos de agir:
  #
  #   render Ss::ButtonComponent.new(label: "Novo pedido", icon: "plus", href: new_pedido_path, data: { turbo_frame: "modal" })  (link)
  #   render Ss::ButtonComponent.new(label: "Ler", variant: :outline, data: { action: "boleto#ler" })                           (botão do JS)
  #   render Ss::ButtonComponent.new(label: "Salvar", type: :submit, name: "op", value: "x", formaction: lote_path)              (envia o form)
  #   render Ss::ButtonComponent.new(label: "Remover", href: pedido_path(p), method: :delete, variant: :danger,
  #                                  size: :sm, confirm: "Remover o pedido?")                                                   (button_to)
  #   render(Ss::ButtonComponent.new(variant: :ghost)) { … conteúdo livre … }
  #
  # label: o texto (ou o bloco); icon:/trailing_icon: nome do ss_icon ou SVG já seguro (antes/depois do
  # texto). variant: :primary (padrão), :outline, :ghost, :danger, :on_grad (sobre o gradiente: o
  # .is-on-grad), :chip (a ficha .ss-chip, ex. "Hoje", "+R$ 10"), :item (linha de menu .ss-item, ex. no
  # popover ⋯; tone: :danger pinta o texto). size: :sm. block: true = largura toda.
  # href: sem method: (ou :get) vira <a>; com method: :post/:patch/:put/:delete vira um button_to (form
  # com o token); params: vão como campos escondidos; form: {} vai no <form> (data, class).
  # confirm: põe data-turbo-confirm (o Ss::ConfirmDialogComponent global mostra) com confirm_tone:
  # (:danger no Remover) e confirm_button: (verbo do OK). Sem href: <button type="button"> ou
  # type: :submit; o resto (name:, value:, form:, formaction:, data:, aria:, title:, id:, disabled:)
  # vai no elemento. submitting: "Salvando…" põe data-turbo-submits-with.
  # v0.23.1: form: "id" (texto) num <button> sem href vira o atributo form= (botão fora do form que ele envia);
  # o form: {} (hash) continua indo no <form> do button_to.
  # v0.19.2 (par do SsButton.onGradient(solid:, stacked:)): solid: true no :on_grad = branco com o texto na
  # cor funda da marca (.is-solid); stacked: true = ícone em cima do rótulo (.is-stacked), para os atalhos
  # lado a lado no herói:
  #   render Ss::ButtonComponent.new(label: "Voo", icon: "paper-airplane", variant: :on_grad, solid: true, stacked: true, href: "#")
  # v0.23 (par do SsPressable): variant: :bare = botão sem desenho (.ss-btn-bare) para conteúdo livre que já é a
  # peça (um card, uma amostra, uma linha): só o foco, o cursor e o toque que encolhe.
  #   render(Ss::ButtonComponent.new(variant: :bare, type: :submit, name: "style", value: "glass")) { render Ss::... }
  class ButtonComponent < BaseComponent
    VARIANTS = { primary: "ss-btn ss-btn-primary", outline: "ss-btn ss-btn-outline", ghost: "ss-btn ss-btn-ghost",
                 danger: "ss-btn ss-btn-danger", on_grad: "ss-btn is-on-grad", chip: "ss-chip", item: "ss-item",
                 bare: "ss-btn-bare" }.freeze
    METHODS = %w[post patch put delete].freeze

    def initialize(label: nil, icon: nil, trailing_icon: nil, href: nil, method: nil, variant: :primary, size: :md, block: false,
                   type: :button, confirm: nil, confirm_tone: nil, confirm_button: nil, params: nil, form: nil, submitting: nil,
                   tone: nil, solid: false, stacked: false, **rest)
      super(**rest)
      @solid, @stacked = solid, stacked
      @label, @icon, @trailing_icon, @href = label, icon, trailing_icon, href
      @method = method.to_s.downcase.presence
      @variant = VARIANTS.key?(variant.to_s.to_sym) ? variant.to_s.to_sym : :primary
      @size = size.to_s == "sm" ? :sm : :md
      @block = block
      @type = type.to_s == "submit" ? "submit" : (type.to_s == "reset" ? "reset" : "button")
      @confirm, @confirm_tone, @confirm_button = confirm, confirm_tone, confirm_button
      @params, @form, @submitting, @tone = params, form, submitting, tone
    end

    def call
      return button_to_form if @href && METHODS.include?(@method)
      return link_to(@href, **attrs(confirm_data)) { body } if @href

      tag.button(type: @type, form: (@form.to_s if @form.is_a?(String) || @form.is_a?(Symbol)), **attrs(confirm_data.merge(submitting_data))) { body }
    end

    private

    def css
      sm = case @variant
           when :chip, :item, :bare then nil
           else ("ss-btn-sm" if @size == :sm)
           end
      classes(VARIANTS[@variant], sm, ("is-block" if @block), ("is-danger" if @tone.to_s == "danger"),
              ("is-solid" if @solid && @variant == :on_grad), ("is-stacked" if @stacked && !%i[chip item bare].include?(@variant)))
    end

    def attrs(extra_data = {})
      root_attrs(class: css, data: extra_data)
    end

    def confirm_data
      return {} unless @confirm

      { turbo_confirm: @confirm, turbo_confirm_tone: @confirm_tone&.to_s, turbo_confirm_button: @confirm_button }.compact
    end

    def submitting_data = (@submitting ? { turbo_submits_with: @submitting } : {})

    # button_to: o confirm vai no <form> (o Turbo lê dele), o resto no <button>.
    def button_to_form
      form = (@form.is_a?(Hash) ? @form : {}).dup
      form[:data] = form[:data].to_h.merge(confirm_data)
      opts = attrs(submitting_data).merge(method: @method.to_sym, form:)
      opts[:params] = @params if @params
      button_to(@href, **opts) { body }
    end

    def body
      safe_join([icon_svg(@icon), (content.presence || (@label.nil? ? nil : tag.span(@label))), icon_svg(@trailing_icon)].compact)
    end

    def icon_svg(icon)
      return nil if icon.blank?
      return icon if icon.respond_to?(:html_safe?) && icon.html_safe?

      ss_icon(icon.to_s, size: @stacked ? :sm : :xs)
    end
  end
end
