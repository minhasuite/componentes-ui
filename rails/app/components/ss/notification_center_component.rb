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
  class NotificationCenterComponent < BaseComponent
    TONES = %i[accent success warn danger muted].freeze

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

    def item(it)
      css = ["ss-ncenter-item", ("is-unread" if it[:unread])].compact.join(" ")
      time = it[:at] && tag.time(ss_date(it[:at], :time), datetime: it[:at].respond_to?(:iso8601) ? it[:at].iso8601 : it[:at].to_s, class: "ss-ncenter-time")
      body = safe_join([
        (tag.span(svg(it[:icon] || "bell"), class: ["ss-icon-tile", ("is-#{it[:tone]}" if TONES.include?(it[:tone]&.to_sym))].compact.join(" ")) if it[:icon] != false),
        tag.span(class: "ss-ncenter-text") do
          safe_join([tag.span(it[:title], class: "ss-ncenter-title"), (tag.span(it[:text], class: "ss-ncenter-note") if it[:text].present?)].compact)
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
      tag.li(safe_join([main, actions(it)].compact), class: css, id: (it[:id] && "#{@id}-item-#{it[:id]}"))
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
