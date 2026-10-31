require "erb"

module ComponentesUi
  # Helpers de view para as peças que precisam de conta (pontos, matiz).
  # Entram em todas as views do app (ver Engine). Mesma conta do Flutter.
  module Helpers
    # "R$ 1.234,56" → R$ 1.234<small>,56</small> dentro de .ss-amount.
    def ss_amount(text, css: nil)
      main, cents = text.to_s.match(/\A(.*?)(,\d{2})?\z/m).captures
      inner = "#{ERB::Util.h(main)}#{"<small>#{ERB::Util.h(cents)}</small>" if cents}"
      %(<span class="#{["ss-amount", css].compact.join(" ")}">#{inner}</span>).html_safe
    end

    # Minigráfico sem eixo (curva suave). Vai na base de um .ss-stat ou solto.
    def ss_sparkline(values, height: 44, area: true)
      vals = values.map(&:to_f)
      return "".html_safe if vals.size < 2

      w = 100.0
      top = 6.0
      h = height - top - 2
      lo, hi = vals.minmax
      span = (hi - lo).zero? ? 1 : hi - lo
      pts = vals.each_with_index.map { |v, i| [w * i / (vals.size - 1), top + h * (1 - (v - lo) / span)] }
      d = +"M#{fmt(pts[0])}"
      pts.each_cons(2).with_index do |(p1, p2), i|
        p0 = pts[[i - 1, 0].max]
        p3 = pts[[i + 2, pts.size - 1].min]
        c1 = [p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6]
        c2 = [p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6]
        d << " C#{fmt(c1)} #{fmt(c2)} #{fmt(p2)}"
      end
      area_path = area ? %(<path class="area" d="#{d} L#{w},#{height} L0,#{height} Z"/>) : ""
      %(<svg class="ss-spark" viewBox="0 0 #{w.to_i} #{height}" preserveAspectRatio="none" aria-hidden="true">) +
        %(#{area_path}<path class="line" d="#{d}"/></svg>).html_safe
    end

    # Anéis concêntricos (até 3), valores de 0 a 1; center = texto do meio.
    def ss_rings(values, size: 128, stroke: 11, center: nil, colors: %w[var(--aurora-2) var(--aurora-3) var(--aurora-1)])
      circles = values.first(3).each_with_index.map do |v, i|
        r = size / 2.0 - stroke / 2.0 - i * (stroke + 4)
        pct = (v.to_f.clamp(0.0, 1.0) * 100).round(1)
        # stroke no style: atributo de apresentação do SVG não aceita var().
        attrs = %(cx="#{size / 2.0}" cy="#{size / 2.0}" r="#{r}" pathLength="100")
        %(<circle class="track" #{attrs} style="stroke:#{colors[i]}"/><circle class="fill" #{attrs} style="stroke:#{colors[i]};--v:#{pct};--i:#{i}"/>)
      end.join
      label = center ? %(<span>#{ERB::Util.h(center)}</span>) : ""
      %(<div class="ss-rings" style="width:#{size}px;height:#{size}px"><svg viewBox="0 0 #{size} #{size}" aria-hidden="true">#{circles}</svg>#{label}</div>).html_safe
    end

    # Iniciais sobre gradiente com matiz tirado do nome (sempre o mesmo).
    # status: "ok", "danger", "warn" (ponto no canto).
    def ss_avatar(name, size: 42, status: nil, brand_hue: 250)
      hue = (brand_hue + (ss_seed(name) % 5 - 2) * 24) % 360
      st = status ? %( data-status="#{ERB::Util.h(status)}") : ""
      %(<span class="ss-avatar" style="--h:#{hue};--s:#{size}px" title="#{ERB::Util.h(name)}" aria-label="#{ERB::Util.h(name)}"#{st}>#{ERB::Util.h(ss_initials(name))}</span>).html_safe
    end

    def ss_initials(name)
      parts = name.to_s.strip.split(/\s+/)
      return "?" if parts.empty?

      (parts.size == 1 ? parts[0][0] : parts[0][0] + parts[-1][0]).upcase
    end

    # Hash estável do nome (igual ao SsAvatar.seed do Flutter).
    def ss_seed(name)
      name.to_s.strip.downcase.encode("UTF-16LE").unpack("v*").reduce(7) { |h, u| (h * 31 + u) & 0x7fffffff }
    end

    private

    def fmt(p) = "#{p[0].round(2)},#{p[1].round(2)}"
  end
end
