require "erb"
require "date"

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

    # v0.5 ─────────────────────────────────────────────────────────────

    # Odômetro: cada dígito vira uma coluna 0–9 que rola até ele (o resto fica
    # como texto). Trocar o valor (morph do Turbo) faz os dígitos rolarem.
    def ss_odometer(text, css: nil)
      digits = text.to_s.scan(/\d|\D+/).map do |part|
        part.match?(/\d/) ? %(<span class="ss-odo-digit" style="--d:#{part}"><span>0123456789</span></span>) : "<span>#{ERB::Util.h(part)}</span>"
      end.join
      %(<span class="#{["ss-odometer", css].compact.join(" ")}"><span class="ss-sr">#{ERB::Util.h(text)}</span><span aria-hidden="true" style="display:contents">#{digits}</span></span>).html_safe
    end

    # Meia-lua com agulha: value de 0 a 1; text = número do meio (padrão: a porcentagem).
    def ss_gauge(value, label:, text: nil)
      v = value.to_f.clamp(0.0, 1.0)
      text ||= "#{(v * 100).round}%"
      %(<div class="ss-gauge" style="--v:#{v.round(3)}" role="img" aria-label="#{ERB::Util.h("#{label}: #{text}")}"><b>#{ERB::Util.h(text)}</b><small>#{ERB::Util.h(label)}</small></div>).html_safe
    end

    # Anel em gomos: um gomo por unidade (até 60; acima disso, proporcional).
    def ss_countdown(total:, left:, label: nil)
      total = [total.to_i, 1].max
      left = left.to_i.clamp(0, total)
      n = [total, 60].min
      lit = total == n ? left : (left * n.to_f / total).round
      small = label ? %(<small>#{ERB::Util.h(label)}</small>) : ""
      aria = ERB::Util.h([left, label].compact.join(" ") + " de #{total}")
      %(<div class="ss-countdown" style="--n:#{n};--left:#{lit}" role="img" aria-label="#{aria}"><b>#{left}</b>#{small}</div>).html_safe
    end

    # Grade de constância: values_by_date = { Date|"aaaa-mm-dd" => número }.
    # Colunas = semanas (dom..sáb), a última termina hoje. Nível 0–4 pelo quartil
    # do valor entre os dias com valor (0 = nada; o maior = 4).
    def ss_heat(values_by_date, weeks: 12, today: Date.today, label: "Constância")
      vals = values_by_date.to_h.each_with_object({}) { |(k, v), h| h[k.is_a?(Date) ? k : Date.parse(k.to_s)] = v.to_f }
      start = today - today.wday - (weeks - 1) * 7
      cells = (start..today).map do |d|
        v = vals[d].to_f
        %(<i data-level="#{ss_heat_level(v, vals.values)}" title="#{d.strftime("%d/%m")}: #{v % 1 == 0 ? v.to_i : v}"></i>)
      end.join
      %(<div class="ss-heat" role="img" aria-label="#{ERB::Util.h(label)}">#{cells}</div>).html_safe
    end

    # Situação com pontinho: map = { "pago" => ["Pago", :success], … }.
    # Tons: neutral, info, success, warning, danger, accent. Fora do mapa: neutro.
    def ss_status(status, map)
      text, tone = map[status] || map[status.to_s] || map[status.to_s.to_sym] || [status.to_s, :neutral]
      %(<span class="ss-status" data-tone="#{ERB::Util.h(tone)}">#{ERB::Util.h(text)}</span>).html_safe
    end

    private

    def fmt(p) = "#{p[0].round(2)},#{p[1].round(2)}"

    def ss_heat_level(v, values)
      return 0 if v <= 0

      # Posição do valor entre os dias com valor (quartil): o maior é sempre 4.
      pos = values.select(&:positive?)
      (pos.count { |x| x <= v } * 4.0 / pos.size).ceil.clamp(1, 4)
    end
  end
end
