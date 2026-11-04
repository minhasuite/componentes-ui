module Ss
  # Radar de busca: ondas saem do ícone central enquanto procura; os itens achados entram
  # "pulando" em volta como chips. O app atualiza com Turbo Stream (replace) a cada achado.
  #
  #   render Ss::ScanRadarComponent.new(state: :searching, items: [{ label: "Lâmpada sala", icon: svg, url: … }])
  #   render Ss::ScanRadarComponent.new(state: :empty, retry_url: buscar_path)
  #
  # state: :searching | :found | :empty. Até 6 itens em volta. As ondas são o laço da busca: param
  # quando acha e com prefers-reduced-motion. retry_url: vira button_to (POST).
  class ScanRadarComponent < BaseComponent
    STATES = %i[searching found empty].freeze
    DEFAULTS = { searching: "Procurando…", found_one: "1 encontrado", found: "%{n} encontrados",
                 empty: "Nada encontrado", retry: "Procurar de novo" }.freeze

    attr_reader :state, :items, :retry_url, :size

    def initialize(state: :searching, items: [], icon: nil, retry_url: nil, size: 240, labels: {}, **rest)
      super(**rest)
      @state = STATES.include?(state.to_s.to_sym) ? state.to_s.to_sym : :searching
      @items = Array(items).map { |i| i.to_h.transform_keys(&:to_sym) }
      @icon, @retry_url, @size = icon, retry_url, size.to_i
      @labels = labels.to_h.transform_keys(&:to_sym)
    end

    def label(key, **vars)
      text = @labels[key] || ss_t("scan_radar.#{key}", default: DEFAULTS[key], **vars)
      I18n.interpolate(text, vars)
    end

    def status_text
      case state
      when :searching then label(:searching)
      when :empty then label(:empty)
      else items.size == 1 ? label(:found_one, n: 1) : label(:found, n: items.size)
      end
    end

    def icon = (@icon || Ss::CasaIcons.svg(:home)).html_safe

    # Posição do chip i em volta (mesma conta do Flutter): ângulos espalhados, raios alternados.
    def chip_style(i)
      a = -Math::PI / 2 + i * (2 * Math::PI / 6) + (i.odd? ? 0.25 : 0)
      r = i.even? ? 40 : 33
      format("left: %.2f%%; top: %.2f%%; --i: %d", 50 + Math.cos(a) * r, 50 + Math.sin(a) * r, i)
    end
  end
end
