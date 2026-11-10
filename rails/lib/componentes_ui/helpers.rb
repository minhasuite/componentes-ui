require "erb"
require "date"
require "i18n"
require "componentes_ui/icons"
require "componentes_ui/amount_expression"

module ComponentesUi
  # Helpers de view para as peças que precisam de conta (pontos, matiz).
  # Entram em todas as views do app (ver Engine). Mesma conta do Flutter.
  module Helpers
    # Símbolo de cada moeda (ISO 4217). Fora do mapa, sai o próprio código ("CHF 10,00").
    CURRENCY_SYMBOLS = {
      "BRL" => "R$", "USD" => "US$", "EUR" => "€", "GBP" => "£", "ARS" => "$", "CLP" => "$", "COP" => "$",
      "MXN" => "$", "UYU" => "$U", "PYG" => "₲", "PEN" => "S/", "BOB" => "Bs", "CAD" => "CA$", "JPY" => "¥"
    }.freeze

    # ── i18n (v0.10) ──────────────────────────────────────────────────
    # Texto da gem: I18n.t("componentes_ui.<key>"). Quem chama passa sempre
    # default: com o texto pt-BR, para o app sem os YAML da gem continuar igual.
    #   ss_t("toast.undo", default: "Desfazer")
    def ss_t(key, **opts)
      I18n.t("componentes_ui.#{key}", **opts)
    rescue I18n::InvalidLocale
      # Fora do Rails (teste puro) o I18n pode não ter locale nenhum carregado.
      opts[:default].is_a?(String) ? I18n.interpolate(opts[:default], opts.except(:default, :locale)) : opts[:default]
    end

    # Idioma dos números e do dinheiro: ComponentesUi.config.locale ou o da página.
    def ss_number_locale
      (ComponentesUi.config.locale if ComponentesUi.respond_to?(:config)) || I18n.locale
    end

    # Moeda ISO dos helpers de dinheiro (padrão BRL).
    def ss_currency
      (ComponentesUi.config.currency if ComponentesUi.respond_to?(:config)) || "BRL"
    end

    def ss_currency_symbol(currency = nil)
      code = (currency || ss_currency).to_s.upcase
      CURRENCY_SYMBOLS.fetch(code, code)
    end

    # Idioma em BCP 47 para o Intl do navegador ("pt-BR", "en", "es").
    def ss_intl_locale = ss_number_locale.to_s.tr("_", "-")

    # Número no formato do idioma: ss_number(1234.5, precision: 2) → "1.234,50" (pt/es) ou "1,234.50" (en).
    def ss_number(value, precision: 0, locale: nil)
      loc = locale || ss_number_locale
      sep = ss_t("number.separator", locale: loc, default: ",")
      del = ss_t("number.delimiter", locale: loc, default: ".")
      v = value.to_f
      str = Kernel.format("%.#{precision.to_i}f", v.abs)
      int, dec = str.split(".")
      int = int.gsub(/(\d)(?=(\d{3})+\z)/, "\\1#{del}")
      neg = v.negative? && str.to_f != 0
      "#{"-" if neg}#{int}#{"#{sep}#{dec}" if dec}"
    end

    # Espaço não separável (U+00A0) entre símbolo e número (v0.15.2): "R$" nunca fica
    # sozinho no fim da linha. O mesmo do SsFormats (Flutter) e do Intl (JS da gem).
    NBSP = "\u00A0"

    # Dinheiro no formato do idioma e na moeda da config (ou a de currency:, ISO 4217):
    #   ss_money(1234.5) → "R$ 1.234,50" (pt-BR), "R$1,234.50" (en), "1.234,50 R$" (es).
    #   ss_money(12, currency: "USD") → "US$ 12,00"; ss_money(10, currency: "CHF") → "CHF 10,00".
    # O espaço do formato sai não separável (U+00A0), também no "%u %n" de um YAML do app.
    # minus: o sinal do negativo ("-" ou o "−" tipográfico).
    def ss_money(value, currency: nil, precision: 2, locale: nil, minus: "-")
      loc = locale || ss_number_locale
      pattern = ss_t("money.format", locale: loc, default: "%u#{NBSP}%n").tr(" ", NBSP)
      v = value.to_f
      text = pattern.sub("%u", ss_currency_symbol(currency)).sub("%n", ss_number(v.abs, precision:, locale: loc))
      v.negative? && v.round(precision) != 0 ? "#{minus}#{text}" : text
    end

    # Quantidade sem zeros inúteis e com a unidade (v0.15.2, igual ao SsFormats.qty):
    #   ss_qty(2) → "2", ss_qty(1.5, "l") → "1,5 L" (litro em maiúscula), ss_qty(0.25, "kg") → "0,25 kg".
    def ss_qty(value, unit = nil, locale: nil)
      return "—" if value.nil?

      v = value.to_f
      n = if v == v.round
        v.round.to_s
      else
        sep = ss_t("number.separator", locale: locale || ss_number_locale, default: ",")
        Kernel.format("%.3f", v).sub(/0+\z/, "").tr(".", sep)
      end
      u = unit.to_s.strip
      return n if u.empty?

      "#{n} #{u == "l" ? "L" : u}"
    end

    # Data no formato curto do idioma (strftime dos YAML da gem):
    #   ss_date(d) → "31/10/2026" | ss_date(d, :day_month) → "31/10" | :day_month_time | :time
    def ss_date(value, format = :date)
      defaults = { date: "%d/%m/%Y", day_month: "%d/%m", day_month_time: "%d/%m %H:%M", time: "%H:%M" }
      value.strftime(ss_t("date.formats.#{format}", default: defaults.fetch(format)))
    end

    # Nomes de dia e mês do idioma (arrays dos YAML), 0 = domingo / 0 = janeiro.
    WEEKDAYS_PT = %w[dom seg ter qua qui sex sáb].freeze
    WEEKDAYS_LONG_PT = %w[domingo segunda-feira terça-feira quarta-feira quinta-feira sexta-feira sábado].freeze
    MONTHS_PT = %w[janeiro fevereiro março abril maio junho julho agosto setembro outubro novembro dezembro].freeze
    MONTHS_SHORT_PT = %w[jan fev mar abr mai jun jul ago set out nov dez].freeze

    # (default: com array no I18n é lista de alternativas, por isso o || depois.)
    def ss_weekdays(long: false) = ss_t("date.#{long ? "weekdays" : "weekdays_short"}", default: nil) || (long ? WEEKDAYS_LONG_PT : WEEKDAYS_PT)
    def ss_months(short: false) = ss_t("date.#{short ? "months_short" : "months"}", default: nil) || (short ? MONTHS_SHORT_PT : MONTHS_PT)

    # ── Moldura (v0.10.1) ─────────────────────────────────────────────
    # Script inline para o <head> do layout com Ss::AppShellComponent: lê a escolha
    # "menu recolhido" (localStorage ou cookie ss_shell_collapsed) e põe
    # data-ss-shell-collapsed no <html> antes da 1ª pintura (o menu não pisca aberto).
    # Também copia o localStorage antigo para o cookie, que o servidor lê.
    #   <head> … <%= ss_app_shell_head %> … </head>
    # Com CSP, sai com o nonce da requisição (content_security_policy_nonce).
    APP_SHELL_HEAD_JS = <<~JS.gsub(/\n\s*/, "").freeze
      (function(){try{var d=document.documentElement,v=null,m=document.cookie.match(/(?:^|;\\s*)ss_shell_collapsed=([01])/);
      try{v=localStorage.getItem("ss-shell-collapsed")}catch(e){}
      if(v!=="1"&&v!=="0")v=m?m[1]:null;
      if(v==="1")d.setAttribute("data-ss-shell-collapsed","");
      if(v&&(!m||m[1]!==v))document.cookie="ss_shell_collapsed="+v+"; path=/; max-age=31536000; samesite=lax"}catch(e){}})();
    JS

    def ss_app_shell_head
      nonce = (content_security_policy_nonce if respond_to?(:content_security_policy_nonce)) rescue nil
      attr = nonce ? %( nonce="#{ERB::Util.html_escape(nonce)}") : ""
      %(<script#{attr} data-ss-shell-head>#{APP_SHELL_HEAD_JS}</script>).html_safe
    end

    # v0.11: densidade. Nome válido ("compact"/"standard"/"comfortable"); o resto vira "standard".
    def ss_density(value = nil)
      v = (value || (ComponentesUi.config.density if ComponentesUi.respond_to?(:config))).to_s
      ComponentesUi::DENSITIES.include?(v) ? v : "standard"
    end

    # Atributo do <html> (ou de qualquer contêiner) com a densidade: vazio no padrão.
    #   <html lang="pt-BR" <%= tag.attributes(ss_density_attrs) %>>
    #   <section <%= tag.attributes(ss_density_attrs("compact")) %>>…</section>
    def ss_density_attrs(value = nil)
      d = ss_density(value)
      d == "standard" ? {} : { "data-ss-density" => d }
    end

    SS_DENSITY_HEAD_JS = <<~JS.gsub(/\s*\n\s*/, "").freeze
      (function(){try{var v=localStorage.getItem("ss-density");
      if(v==="compact"||v==="comfortable")document.documentElement.setAttribute("data-ss-density",v);
      else if(v==="standard")document.documentElement.removeAttribute("data-ss-density")}catch(e){}})();
    JS

    # No <head>, antes do CSS: aplica a densidade que a pessoa escolheu (localStorage
    # ss-density, do Ss::DensityPickerComponent) antes da 1ª pintura e sobrevive ao morph
    # do Turbo. Sem escolha, vale a do <html> (ss_density_attrs / config).
    def ss_density_head
      nonce = (content_security_policy_nonce if respond_to?(:content_security_policy_nonce)) rescue nil
      attr = nonce ? %( nonce="#{ERB::Util.html_escape(nonce)}") : ""
      %(<script#{attr} data-ss-density-head>#{SS_DENSITY_HEAD_JS}</script>).html_safe
    end

    # v0.10.2: "Pular para o conteúdo" (.ss-skip), o primeiro Tab da página. Ponha logo no
    # começo do <body>; o alvo precisa de id (o <main> do AppShell é #conteudo, com tabindex=-1).
    #   <%= ss_skip_link %>   <%= ss_skip_link("#principal", "Ir para a lista") %>
    def ss_skip_link(target = "#conteudo", label = nil)
      label ||= ss_t("skip_link.label", default: "Pular para o conteúdo")
      %(<a href="#{ERB::Util.html_escape(target)}" class="ss-skip">#{ERB::Util.html_escape(label)}</a>).html_safe
    end

    # Nome da paleta e da família no idioma da página (paletas.rb tem o pt-BR, gerado).
    def ss_palette_name(slug)
      pt = ComponentesUi::PALETAS[slug.to_s] if defined?(ComponentesUi::PALETAS)
      ss_t("palettes.#{slug}", default: pt || slug.to_s)
    end

    def ss_palette_family(name)
      ss_t("palette_families.#{name.to_s.downcase.unicode_normalize(:nfkd).gsub(/[^a-z]/, "")}", default: name.to_s)
    end

    # "R$ 1.234,56" → R$ 1.234<small>,56</small> dentro de .ss-amount. Os centavos
    # saem pelo separador decimal do idioma ("$1,234.56" → <small>.56</small>), e o
    # símbolo depois do número também vale ("1.234,56 R$").
    def ss_amount(text, css: nil)
      sep = Regexp.escape(ss_t("number.separator", locale: ss_number_locale, default: ","))
      main, cents, tail = text.to_s.match(/\A(.*?)(#{sep}\d{2})?(\s*[^\d\s][^\d]*)?\z/m).captures
      inner = cents ? "#{ERB::Util.h(main)}<small>#{ERB::Util.h(cents)}</small>#{ERB::Util.h(tail)}" : ERB::Util.h(text.to_s)
      %(<span class="#{["ss-amount", css].compact.join(" ")}">#{inner}</span>).html_safe
    end

    # Minigráfico sem eixo (curva suave). Vai na base de um .ss-stat ou solto.
    # v0.16 (par do SsSparkline(target:, markMin:)): target: desenha a linha tracejada do alvo (entra
    # na escala); mark_min: true marca o menor valor com um ponto verde.
    def ss_sparkline(values, height: 44, area: true, target: nil, mark_min: false)
      vals = values.map(&:to_f)
      return "".html_safe if vals.size < 2

      w = 100.0
      top = 6.0
      h = height - top - 2
      lo, hi = (target ? vals + [target.to_f] : vals).minmax
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
      alvo = target ? %(<path class="target" d="M0,#{(top + h * (1 - (target.to_f - lo) / span)).round(2)} H#{w.to_i}"/>) : ""
      i = vals.index(vals.min)
      # Ponto do menor (não repete o último); a elipse compensa o preserveAspectRatio="none".
      minimo = mark_min && i != vals.size - 1 ? %(<ellipse class="min" cx="#{pts[i][0].round(2)}" cy="#{pts[i][1].round(2)}" rx="1.6" ry="3"/>) : ""
      (%(<svg class="ss-spark" viewBox="0 0 #{w.to_i} #{height}" preserveAspectRatio="none" aria-hidden="true">) +
        %(#{alvo}#{area_path}<path class="line" d="#{d}"/>#{minimo}</svg>)).html_safe
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
    # status: o ponto no canto ("success" ou qualquer valor = verde, "danger", "warn", "muted" = apagado,
    # v0.13); ring: true (v0.13) põe o anel na cor da marca (o ring: do SsAvatar).
    def ss_avatar(name, size: 42, status: nil, brand_hue: 250, ring: false)
      hue = (brand_hue + (ss_seed(name) % 5 - 2) * 24) % 360
      st = status ? %( data-status="#{ERB::Util.h(status)}") : ""
      st += " data-ring" if ring
      %(<span class="ss-avatar" style="--h:#{hue};--s:#{size}px" title="#{ERB::Util.h(name)}" aria-label="#{ERB::Util.h(name)}"#{st}>#{ERB::Util.h(ss_initials(name))}</span>).html_safe
    end

    # v0.13: as variáveis CSS da marca a partir de uma ou duas cores (#rrggbb), para pintar um
    # trecho (style=) com outra marca: o par do SsBrand.fromColors do Flutter (mesmas misturas:
    # hover = 14% de preto, suave = 14% sobre a superfície). Cor inválida = nil.
    #   <div style="<%= ss_brand_style("#0284c7", "#14b8a6") %>">…</div>
    def ss_brand_style(accent, accent2 = nil) = ComponentesUi.brand_css(accent, accent2)

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
    # v0.16 (par do SsCountdownRing(warnAt:)): warn_at: n deixa o anel âmbar com n ou menos
    # (data-tone="warn") e vermelho no zero (data-tone="over").
    def ss_countdown(total:, left:, label: nil, warn_at: nil)
      total = [total.to_i, 1].max
      left = left.to_i.clamp(0, total)
      tone = if warn_at.nil? then nil elsif left.zero? then "over" elsif left <= warn_at.to_i then "warn" end
      n = [total, 60].min
      lit = total == n ? left : (left * n.to_f / total).round
      small = label ? %(<small>#{ERB::Util.h(label)}</small>) : ""
      aria = ERB::Util.h(ss_t("countdown.aria", default: "%{left} de %{total}", left: [left, label].compact.join(" "), total:))
      %(<div class="ss-countdown" style="--n:#{n};--left:#{lit}"#{%( data-tone="#{tone}") if tone} role="img" aria-label="#{aria}"><b>#{left}</b>#{small}</div>).html_safe
    end

    # Grade de constância: values_by_date = { Date|"aaaa-mm-dd" => número }.
    # Colunas = semanas (dom..sáb), a última termina hoje. Nível 0–4 pelo quartil
    # do valor entre os dias com valor (0 = nada; o maior = 4).
    def ss_heat(values_by_date, weeks: 12, today: Date.today, label: nil)
      label ||= ss_t("heat.label", default: "Constância")
      vals = values_by_date.to_h.each_with_object({}) { |(k, v), h| h[k.is_a?(Date) ? k : Date.parse(k.to_s)] = v.to_f }
      start = today - today.wday - (weeks - 1) * 7
      cells = (start..today).map do |d|
        v = vals[d].to_f
        %(<i data-level="#{ss_heat_level(v, vals.values)}" title="#{ss_date(d, :day_month)}: #{v % 1 == 0 ? v.to_i : v}"></i>)
      end.join
      %(<div class="ss-heat" role="img" aria-label="#{ERB::Util.h(label)}">#{cells}</div>).html_safe
    end

    # ── Ícones (v0.15) ────────────────────────────────────────────────
    # SVG inline do conjunto da gem (Heroicons v1, MIT; ComponentesUi::Icons), na cor do texto.
    # Aceita o nome da v1 e o da v2 ("magnifying-glass" → search); nome que não existe vira o
    # "question-mark-circle" (a tela nunca quebra por um ícone salvo no banco).
    #   ss_icon("credit-card")                      → .ss-icon (1,25rem)
    #   ss_icon("star", variant: :solid, size: :xs, css: "text-warn")
    #   ss_icon("bell", title: "Avisos")            → role="img" + <title>
    #   render Ss::NoteComponent.new(icon: ss_icon("bell", size: nil))  (o componente dimensiona)
    # size: :xs (1rem), :sm (1,25rem, padrão), :md (1,5rem), :lg (1,75rem) ou nil (sem tamanho).
    ICON_SIZES = %i[xs sm md lg].freeze
    ICON_FALLBACK = "question-mark-circle".freeze

    def ss_icon_name(name)
      n = name.to_s.strip.downcase.delete_prefix("heroicon-").tr("_", "-")
      n = ComponentesUi::Icons::ALIASES.fetch(n, n)
      ComponentesUi::Icons::OUTLINE.key?(n) ? n : nil
    end

    def ss_icon?(name) = !ss_icon_name(name).nil?

    def ss_icon_names = ComponentesUi::Icons::OUTLINE.keys

    def ss_icon(name, variant: :outline, size: :sm, css: nil, title: nil)
      n = ss_icon_name(name) || ICON_FALLBACK
      solid = variant.to_s == "solid" && ComponentesUi::Icons::SOLID.key?(n)
      paint = solid ? %(viewBox="0 0 20 20" fill="currentColor") : %(viewBox="0 0 24 24" fill="none" stroke="currentColor")
      klass = ["ss-icon", ("is-#{size}" if ICON_SIZES.include?(size&.to_sym) && size.to_sym != :sm), (size.nil? ? "is-free" : nil), css].compact.join(" ")
      a11y = title.to_s.empty? ? %(aria-hidden="true") : %(role="img" aria-label="#{ERB::Util.h(title)}")
      body = (solid ? ComponentesUi::Icons::SOLID : ComponentesUi::Icons::OUTLINE).fetch(n)
      label = title.to_s.empty? ? "" : "<title>#{ERB::Util.h(title)}</title>"
      %(<svg xmlns="http://www.w3.org/2000/svg" #{paint} class="#{ERB::Util.h(klass)}" data-icon="#{n}" #{a11y} focusable="false">#{label}#{body}</svg>).html_safe
    end

    # ── Valor digitado como conta (v0.15) ─────────────────────────────
    # "45+12,50" → BigDecimal("57.5"); nil se não fecha. Ver ComponentesUi::AmountExpression.
    def ss_amount_expression(text) = ComponentesUi::AmountExpression.call(text)

    # Situação com pontinho: map = { "pago" => ["Pago", :success], … }.
    # Tons: neutral, info, success, warning, danger, accent. Fora do mapa: neutro.
    def ss_status(status, map)
      text, tone = map[status] || map[status.to_s] || map[status.to_s.to_sym] || [status.to_s, :neutral]
      # v0.18: :warn e :warning dão o mesmo âmbar (sai data-tone="warning", o de sempre).
      tone = :warning if tone.to_s == "warn"
      %(<span class="ss-status" data-tone="#{ERB::Util.h(tone)}">#{ERB::Util.h(text)}</span>).html_safe
    end

    private

    def fmt(p) = "#{p[0].round(2)},#{p[1].round(2)}"

    def ss_heat_level(v, values)
      return 0 if v <= 0

      # Mesma conta do ssHeatLevel do Flutter: fração do maior valor, em 4 faixas.
      max = values.max.to_f
      return 0 if max <= 0

      (v / max * 4).ceil.clamp(1, 4)
    end
  end
end
