module Ss
  # Central de notificações (v1.9 · produto, par do SsNotificationCenter): a página inteira dos avisos, agrupada por dia
  # ("Hoje", "Ontem", "segunda-feira, 5 de outubro", outro ano com a data), com a faixa "3 não lidas · Marcar todas como
  # lidas", cada aviso lido/não lido (negrito e o ponto), abrir (marca como lida e leva ao destino), marcar como lida e
  # arquivar, e "Carregar mais" que pagina sozinho (turbo-frame lazy). O sino do topo continua sendo o
  # Ss::NotificationBellComponent (que usa o Ss::NotificationListComponent no popover).
  #
  #   render Ss::NotificationCenterComponent.new(id: "avisos", unread_count: 3, read_all_href: avisos_lidos_path,
  #     next_href: avisos_path(page: 2), items: @avisos.map { |a|
  #       { id: a.id, title: a.title, text: a.body, at: a.created_at, unread: a.read_at.nil?, icon: "check-circle", tone: :success,
  #         href: abrir_aviso_path(a), method: :patch, read_href: aviso_lido_path(a), archive_href: arquivar_aviso_path(a) } })
  #
  # items: [{ id:, title:, text:, at: (Time/Date; agrupa e mostra a hora), unread:, icon:, tone: (:accent/:success/:warn/
  # :danger/:muted), href:, method: (abrir com PATCH/POST = button_to; sem method, link), read_href:, archive_href:,
  # read_method: (:patch), archive_method: (:patch) }]. read_all_href: vira PATCH (read_all_method: troca).
  #
  # Paginação: com next_href:, o fim da lista é um <turbo-frame id="<id>-p<page+1>" src=next_href loading=lazy> com o
  # "Carregar mais". A resposta da próxima página é o mesmo componente com fragment: true, page: (2, 3…) e o mesmo id:;
  # sai só o <turbo-frame id="<id>-p<page>"> com os grupos e o frame da página seguinte. after: (o at: do último aviso
  # da página anterior) evita repetir o título do dia na emenda. Os links dentro vão para a página inteira (_top).
  # now: (padrão Time.current) é o "hoje" dos grupos. empty:/empty_text: trocam o vazio.
  #
  # v1.9.2, aviso rico (tudo opcional, par do SsNotificationItem(level:, image:, actions:, onMute:)):
  #   level: :info/:warning/:critical  aviso e crítico ganham o tom (âmbar, vermelho) no ícone e no contorno, o ícone do
  #                                    nível (icon:/tone: passados ganham)
  #                                    nível e o selo com o nome ("Aviso", "Crítico"); info fica como antes.
  #   image: "url" (image_alt:)        foto embaixo do texto (instantâneo da câmera), preguiçosa, 16:9 no máximo.
  #   actions: [{ label:, href:, method: (:patch; :get = link), params:, icon: }]  botões de resposta embaixo (o 1º
  #                                    cheio, os outros fantasma). v1.9.3: link (:get) para URL externa (http(s) de
  #                                    outro host) abre em outra aba (target="_blank" rel="noopener"); target: troca.
  #   mute: { href:, method: (:patch), label:, params: } ou { label:, options: [{ label:, href:, method:, params: }] }
  #                                    "Silenciar": um botão, ou o menu com as opções ("Por 1 hora", "Por 8 horas").
  #
  #   { id: n.id, title: n.title, text: n.body, at: n.created_at, unread: n.read_at.nil?, level: :critical,
  #     image: n.image_url, actions: n.actions.map { |a| { label: a["title"], href: responder_path(n), params: { action_id: a["id"] } } },
  #     mute: { options: [1, 8, 24].map { |h| { label: "Por #{h} h", href: silenciar_path(n, hours: h) } } } }
  class NotificationCenterComponent < BaseComponent
    TONES = %i[accent success warn danger muted].freeze
    LEVELS = { warning: ["warn", "exclamation-triangle", "ss-badge-warning"], critical: ["danger", "exclamation-circle", "ss-badge-danger"] }.freeze

    def initialize(items: [], id: "ss-ncenter", unread_count: nil, read_all_href: nil, read_all_method: :patch, next_href: nil,
                   fragment: false, page: 1, after: nil, now: nil, empty: nil, empty_text: nil, label: nil, **rest)
      super(**rest)
      @items = Array(items).map { |i| i.to_h.transform_keys(&:to_sym) }
      @id, @read_all_href, @read_all_method, @next_href, @fragment = id.to_s, read_all_href, read_all_method, next_href, fragment
      @page, @after = [page.to_i, 1].max, after
      @unread = unread_count.nil? ? @items.count { _1[:unread] } : unread_count.to_i
      @now = now || (Time.respond_to?(:current) ? Time.current : Time.now)
      @empty, @empty_text, @label = empty, empty_text, label
    end

    def frame_id(page = @page) = "#{@id}-p#{page}"

    def call
      return content_tag("turbo-frame", safe_join([groups, next_frame].compact), id: frame_id, target: "_top") if @fragment

      tag.section(**root_attrs(id: @id, class: classes("ss-ncenter"), "aria-label": label)) do
        if @items.empty?
          render(EmptyStateComponent.new(title: @empty || ss_t("notification_center.empty", default: "Nenhuma notificação"),
                                         text: @empty_text || ss_t("notification_center.empty_text", default: "Os avisos do app aparecem aqui.")))
        else
          safe_join([head, groups, next_frame].compact)
        end
      end
    end

    # "Hoje", "Ontem", "segunda-feira, 5 de outubro" (no ano) ou a data do idioma.
    def day_label(at)
      d = at.to_date
      today = @now.to_date
      return ss_t("notification_center.today", default: "Hoje") if d == today
      return ss_t("notification_center.yesterday", default: "Ontem") if d == today - 1
      return ss_date(d) unless d.year == today.year

      ss_t("notification_center.day_pattern", default: "%{weekday}, %{day} de %{month}",
                                               weekday: ss_weekdays(long: true)[d.wday], day: d.day, month: ss_months[d.month - 1])
    end

    private

    def label = @label || ss_t("notification_center.title", default: "Notificações")

    def head
      count = tag.p(unread_text, class: "ss-ncenter-count", role: "status")
      button = if @read_all_href && @unread.positive?
                 render(ButtonComponent.new(label: ss_t("notification_center.read_all", default: "Marcar todas como lidas"), icon: "check",
                                            href: @read_all_href, method: @read_all_method, variant: :ghost, size: :sm, form: { class: "contents" }))
               end
      tag.div(safe_join([count, button].compact), class: "ss-ncenter-head")
    end

    def unread_text
      return ss_t("notification_center.all_read", default: "Tudo lido") unless @unread.positive?

      if @unread == 1
        ss_t("notification_center.unread_one", default: "1 não lida")
      else
        ss_t("notification_center.unread_other", count: @unread, default: "%{count} não lidas")
      end
    end

    def groups
      grupos = @items.chunk_while { |a, b| same_day?(a[:at], b[:at]) }
      safe_join(grupos.map do |its|
        primeiro = its.first[:at]
        titulo = primeiro && !(@after && primeiro.to_date == @after.to_date) ? day_label(primeiro) : nil
        tag.div(class: "ss-ncenter-group") do
          safe_join([(tag.h3(titulo, class: "ss-ncenter-day") if titulo), tag.ul(safe_join(its.map { item(_1) }), class: "ss-ncenter-list")].compact)
        end
      end)
    end

    def same_day?(a, b) = a.nil? == b.nil? && (a.nil? || a.to_date == b.to_date)

    def level_of(it) = LEVELS[it[:level]&.to_sym]

    def item(it)
      lv = level_of(it)
      extra = extra(it)
      css = ["ss-ncenter-item", ("is-unread" if it[:unread]), ("is-#{it[:level]}" if lv), ("has-extra" if extra)].compact.join(" ")
      tone = it[:tone] || lv&.first
      icon = it[:icon] || (lv ? lv[1] : "bell")
      time = it[:at] && tag.time(ss_date(it[:at], :time), datetime: it[:at].respond_to?(:iso8601) ? it[:at].iso8601 : it[:at].to_s, class: "ss-ncenter-time")
      body = safe_join([
        (tag.span(svg(icon), class: ["ss-icon-tile", ("is-#{tone}" if TONES.include?(tone&.to_sym))].compact.join(" ")) if it[:icon] != false),
        tag.span(class: "ss-ncenter-text") do
          safe_join([tag.span(it[:title], class: "ss-ncenter-title"),
                     (tag.span(safe_join([ss_icon(lv[1], size: nil), tag.span(level_label(it[:level]))]), class: "ss-badge #{lv[2]} ss-ncenter-level") if lv),
                     (tag.span(it[:text], class: "ss-ncenter-note") if it[:text].present?)].compact)
        end,
        time,
        (tag.span(tag.span(ss_t("notification_center.unread", default: "não lida"), class: "ss-sr"), class: "ss-ncenter-dot") if it[:unread])
      ].compact)
      main = if it[:href] && it[:method].present? && it[:method].to_s != "get"
               render(ButtonComponent.new(href: it[:href], method: it[:method], variant: :bare, css: "ss-ncenter-main", form: { class: "contents", data: { turbo_frame: "_top" } })) { body }
             elsif it[:href]
               link_to(it[:href], class: "ss-ncenter-main", data: { turbo_frame: "_top" }) { body }
             else
               tag.div(body, class: "ss-ncenter-main")
             end
      tag.li(safe_join([main, actions(it), extra].compact), class: css, id: (it[:id] && "#{@id}-item-#{it[:id]}"))
    end

    def level_label(level) = ss_t("notification_center.level_#{level}", default: { warning: "Aviso", critical: "Crítico" }.fetch(level.to_sym, level.to_s))

    # Foto, botões de resposta e "Silenciar", embaixo do aviso, alinhados ao texto.
    def extra(it)
      img = (tag.img(src: it[:image], alt: it[:image_alt] || "", loading: "lazy", class: "ss-ncenter-img") if it[:image].present?)
      btns = Array(it[:actions]).map { _1.to_h.transform_keys(&:to_sym) }.each_with_index.map do |a, i|
        reply_button(a, variant: i.zero? ? :primary : :ghost)
      end
      btns << mute(it[:mute].to_h.transform_keys(&:to_sym)) if it[:mute].present?
      parts = [img, (tag.div(safe_join(btns), class: "ss-ncenter-replies") if btns.any?)].compact
      tag.div(safe_join(parts), class: "ss-ncenter-extra") if parts.any?
    end

    def reply_button(a, variant:, label: a[:label], icon: a[:icon])
      method = (a[:method] || :patch).to_s
      target = (a.key?(:target) ? a[:target] : ("_blank" if method == "get" && external?(a[:href])))
      render(ButtonComponent.new(label:, icon:, href: a[:href], method: (method unless method == "get"), params: a[:params], target:,
                                 variant:, size: :sm, form: { class: "contents", data: { turbo_frame: "_top" } },
                                 data: ({ turbo_frame: "_top" } if method == "get" && target.blank?)))
    end

    # URL absoluta (http/https) de outro host que não o da página.
    def external?(href)
      uri = URI.parse(href.to_s)
      return false unless %w[http https].include?(uri.scheme) && uri.host.present?

      host = (helpers.request.host if helpers.respond_to?(:request) && helpers.request)
      host.blank? || uri.host.casecmp(host).nonzero?
    rescue URI::InvalidURIError, NoMethodError
      false
    end

    def mute(m)
      label = m[:label] || ss_t("notification_center.mute", default: "Silenciar")
      opts = Array(m[:options]).map { _1.to_h.transform_keys(&:to_sym) }
      return reply_button(m, variant: :ghost, label:, icon: m[:icon] || "volume-off") if opts.empty?

      tag.details(class: "ss-menu ss-ncenter-mute") do
        safe_join([tag.summary(safe_join([ss_icon(m[:icon] || "volume-off", size: nil), tag.span(label)]), class: "ss-menu-btn"),
                   tag.div(safe_join(opts.map { |o| reply_button(o, variant: :item, icon: o[:icon] || "clock") }), class: "ss-ncenter-mute-list")])
      end
    end

    def actions(it)
      btns = [
        (action(it[:read_href], it[:read_method] || :patch, "check", ss_t("notification_center.mark_read", default: "Marcar como lida")) if it[:unread] && it[:read_href]),
        (action(it[:archive_href], it[:archive_method] || :patch, "archive", ss_t("notification_center.archive", default: "Arquivar")) if it[:archive_href])
      ].compact
      tag.div(safe_join(btns), class: "ss-ncenter-actions") if btns.any?
    end

    def action(href, method, icon, text)
      button_to(href, method: method, class: "ss-icon-btn is-sm", title: text, "aria-label": text, form: { class: "contents", data: { turbo_frame: "_top" } }) do
        ss_icon(icon, size: nil)
      end
    end

    def next_frame
      return unless @next_href

      more = ss_t("notification_center.load_more", default: "Carregar mais")
      nid = frame_id(@page + 1)
      content_tag("turbo-frame", id: nid, src: @next_href, loading: "lazy", target: "_top", class: "ss-ncenter-next") do
        link_to(more, @next_href, class: "ss-btn ss-btn-ghost ss-btn-sm", data: { turbo_frame: nid })
      end
    end

    def svg(icon)
      return icon if icon.respond_to?(:html_safe?) && icon.html_safe?

      ss_icon(icon.to_s, size: nil)
    end
  end
end
