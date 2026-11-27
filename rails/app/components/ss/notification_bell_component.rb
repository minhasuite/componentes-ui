module Ss
  # Sino de avisos do topo (v0.25, par do SsNotificationBell): ícone com o contador de não lidos e, ao tocar, o
  # popover com os últimos avisos (abrir/ler), "marcar todas como lidas", a engrenagem das preferências e
  # "ver todos" (a central do app). Vai no slot bell do Ss::AppShellComponent (à direita da barra de cima).
  #
  #   s.with_bell do
  #     render Ss::NotificationBellComponent.new(count: 3, src: avisos_recentes_path, count_url: avisos_contagem_path,
  #       all_href: avisos_path, read_all_href: avisos_lidos_path, settings_href: avisos_ajustes_path)
  #   end
  #
  # Lista: items: [{ title:, text:, time: (texto ou <time>), href:, method: (:patch para "abrir marca como lida"),
  # unread: true, icon: (nome ou SVG), tone: :accent/:danger/… }] ou src: (URL que devolve o
  # <turbo-frame id="<id>-list"> com o Ss::NotificationListComponent.new(frame_id: "<id>-list", items: …)):
  # carrega ao abrir a primeira vez (loading=lazy) e recarrega nas outras. Os links da lista vão para a página
  # inteira (target _top).
  # Contador: count: no servidor; count_url: (JSON { count: n }) atualiza a cada every: ms (60 s; pausa com a
  # aba escondida, confere ao voltar e ao abrir). O controller ss-bell dispara "ss-bell:change" ({ count }).
  # read_all_href: vira um PATCH (read_all_method: troca). Textos do I18n (componentes_ui.bell.*).
  class NotificationBellComponent < BaseComponent
    BELL = %(<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M6 16V11a6 6 0 1 1 12 0v5l1.5 2h-15zM10 20a2 2 0 0 0 4 0"/></svg>).freeze

    def initialize(count: 0, items: nil, src: nil, count_url: nil, every: 60_000, all_href: nil, read_all_href: nil, read_all_method: :patch,
                   settings_href: nil, id: "ss-bell", label: nil, empty: nil, **rest)
      super(**rest)
      @count = count.to_i
      @items, @src, @count_url, @every = items, src, count_url, every.to_i
      @all_href, @read_all_href, @read_all_method, @settings_href = all_href, read_all_href, read_all_method, settings_href
      @id = id.to_s
      @label = label || ss_t("bell.title", default: "Avisos")
      @empty = empty
    end

    def self.count_text(n) = n.to_i > 99 ? "99+" : n.to_i.to_s

    def call
      tag.span(**root_attrs(class: classes("ss-bell", "ss-popover-host"), data: bell_data)) do
        safe_join([trigger, panel])
      end
    end

    private

    def pid = "#{@id}-panel"
    def frame_id = "#{@id}-list"
    def unread_label = ss_t("bell.unread", count: "%{count}", default: "%{count} não lidos")
    # v1.9.3: o singular ("Avisos, 1 não lido"; antes "1 não lidos").
    def unread_single = ss_t("bell.unread_single", default: "1 não lido")
    def button_label(n) = n.positive? ? "#{@label}, #{n == 1 ? unread_single : unread_label.sub('%{count}', self.class.count_text(n))}" : @label

    def bell_data
      { controller: "ss-popover ss-bell", ss_bell_url_value: @count_url, ss_bell_every_value: @every, ss_bell_label_value: @label,
        ss_bell_unread_value: "#{@label}, #{unread_label}", ss_bell_unread_one_value: "#{@label}, #{unread_single}" }.compact
    end

    def trigger
      tag.button(type: "button", class: "ss-icon-btn ss-bell-btn", popovertarget: pid, "aria-label": button_label(@count), title: @label,
                 style: "anchor-name:--#{pid}", data: { ss_popover_target: "trigger", ss_bell_target: "button" }) do
        safe_join([BELL.html_safe, tag.span(self.class.count_text(@count), class: "ss-bell-count", hidden: !@count.positive?, "aria-hidden": "true", data: { ss_bell_target: "count" })])
      end
    end

    def panel
      tag.div(id: pid, popover: "auto", class: "ss-popover ss-bell-panel", role: "dialog", "aria-label": @label, style: "position-anchor:--#{pid}",
              data: { placement: "bottom-end", ss_popover_target: "panel", action: "toggle->ss-popover#place toggle->ss-bell#toggled" }) do
        safe_join([head, tag.div(list, class: "ss-bell-body"), foot].compact)
      end
    end

    def head
      tools = [
        (render(ButtonComponent.new(label: ss_t("bell.read_all", default: "Marcar todas como lidas"), icon: "check", href: @read_all_href, method: @read_all_method,
                                    variant: :ghost, size: :sm, form: { class: "contents", data: { turbo_frame: "_top" } })) if @read_all_href),
        (render(IconButtonComponent.new(icon: "cog", label: ss_t("bell.settings", default: "Preferências dos avisos"), href: @settings_href, size: :sm)) if @settings_href)
      ].compact
      tag.div(class: "ss-bell-head") { safe_join([tag.p(@label, class: "ss-popover-title"), (tag.div(safe_join(tools), class: "ss-bell-tools") if tools.any?)].compact) }
    end

    def list
      return render(NotificationListComponent.new(items: @items, empty: @empty)) unless @src

      content_tag("turbo-frame", id: frame_id, src: @src, loading: "lazy", target: "_top", data: { ss_bell_target: "frame" }) do
        tag.div(tag.i + tag.i + tag.i, class: "ss-skel ss-bell-skel", "aria-label": ss_t("bell.loading", default: "Carregando…"), role: "status")
      end
    end

    def foot
      link_to(ss_t("bell.all", default: "Ver todos os avisos"), @all_href, class: "ss-bell-foot", data: { turbo_frame: "_top" }) if @all_href
    end
  end
end
