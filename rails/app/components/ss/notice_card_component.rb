module Ss
  # Aviso com ações: ícone, título, texto, tom, hora e N botões (o 1º cheio, os outros fantasma),
  # mais o "dispensar" opcional.
  #
  #   render Ss::NoticeCardComponent.new(title: "Porta aberta", text: "Há 10 min", tone: :warn, time: "14:32",
  #            actions: [{ label: "Fechar", url: fechar_path }, { label: "Ignorar", url: ignorar_path, method: :delete }],
  #            dismiss_url: aviso_path(a))
  #
  # tone: :info | :warn | :critical | :success. Cada ação: label:, url:, method: (:post; :get vira
  # link), params:, icon: (svg). dismiss_url: vira button_to (DELETE); dismissible: true sem URL só
  # tira da tela (controller ss-notice, evento "ss-notice:dismiss"). critical é role="alert".
  #
  # v0.10.1 (mesmo nome do SsNoticeCard: onTap, image, unread, footer):
  # - url: o card inteiro vira link (link "esticado" no título; ações e dispensar continuam
  #   clicáveis por cima, sem <a>/<button> dentro de <a>). É sempre GET.
  # - image_url: (+ image_alt:) imagem na largura do texto, embaixo dele, 16:9, cantos redondos.
  # - unread: true ponto da cor do tom antes do título e borda mais forte (cor do tom, 2 px).
  # - footer: "Respondido: Sim" (texto) ou o slot with_footer { … }: rodapé miúdo e apagado
  #   com um fio em cima (o slot ganha do texto).
  #
  #   render Ss::NoticeCardComponent.new(title: "Nova mensagem", text: "…", url: aviso_path(a), unread: true,
  #            image_url: a.foto_url, image_alt: "Foto da portaria", footer: "Respondido: Sim")
  class NoticeCardComponent < BaseComponent
    TONES = %i[info warn critical success].freeze
    DEFAULTS = { dismiss: "Dispensar" }.freeze

    attr_reader :title, :text, :tone, :time, :actions, :dismiss_url, :url, :image_url, :image_alt, :footer_text

    renders_one :footer

    def initialize(title:, text: nil, tone: :info, icon: nil, time: nil, actions: [], dismiss_url: nil,
                   dismiss_method: :delete, dismissible: false, dismiss_label: nil, url: nil, image_url: nil, image_alt: nil,
                   unread: false, footer: nil, **rest)
      super(**rest)
      @title, @text, @icon, @time = title, text, icon, time
      @tone = TONES.include?(t = (tone.to_s == "warning" ? :warn : tone.to_s.to_sym)) ? t : :info
      @actions = Array(actions).map { |a| a.to_h.transform_keys(&:to_sym) }
      @dismiss_url, @dismiss_method, @dismissible, @dismiss_label = dismiss_url, dismiss_method, dismissible, dismiss_label
      @url, @image_url, @image_alt, @unread, @footer_text = url.presence, image_url.presence, image_alt, unread, footer.presence
    end

    def link? = url.present?
    def unread? = !!@unread
    def footer_any? = footer? || footer_text.present?
    def root_classes = classes("ss-notice", ("is-link" if link?), ("is-unread" if unread?))

    def icon = (@icon || Ss::CasaIcons.svg(tone)).html_safe
    def dismiss_label = @dismiss_label || ss_t("notice_card.dismiss", default: DEFAULTS[:dismiss])
    def dismiss? = dismiss_url.present? || @dismissible
    def role = tone == :critical ? "alert" : "status"

    def action_button(a, i)
      css = ["ss-btn", "ss-btn-sm", i.zero? ? "ss-btn-primary" : "ss-btn-ghost"].join(" ")
      inner = safe_join([(a[:icon].to_s.html_safe if a[:icon]), a[:label]].compact)
      if a[:url].nil?
        tag.button(inner, type: "button", class: css, disabled: true)
      elsif a[:method].to_s == "get"
        link_to(inner, a[:url], class: css)
      else
        button_to(a[:url], method: a[:method] || :post, params: a[:params] || {}, class: css, form_class: "ss-notice-form") { inner }
      end
    end

    def close_button
      x = Ss::CasaIcons.svg(:close)
      if dismiss_url
        button_to(dismiss_url, method: @dismiss_method, class: "ss-notice-x", form_class: "ss-notice-form",
                               title: dismiss_label, aria: { label: dismiss_label }) { x }
      else
        tag.button(x, type: "button", class: "ss-notice-x", title: dismiss_label, aria: { label: dismiss_label },
                      data: { action: "ss-notice#dismiss" })
      end
    end

    def root_data
      return {} unless @dismissible && dismiss_url.nil?

      own = @attrs.to_h[:data].to_h
      { controller: [own[:controller] || own["controller"], "ss-notice"].compact.join(" ") }
    end
  end
end
