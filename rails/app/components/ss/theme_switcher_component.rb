module Ss
  # Troca de tema (Auto, Claro, Escuro, OLED) e de paleta. Grava no navegador
  # (controller ss-theme). As paletas vêm de ComponentesUi::PALETAS (gerado de
  # paletas/paletas.json, as mesmas do Flutter); o produto pode limitar.
  #   render Ss::ThemeSwitcherComponent.new
  #   render Ss::ThemeSwitcherComponent.new(palettes: false)              # só o tema
  #   render Ss::ThemeSwitcherComponent.new(palettes: %w[none eucalipto]) # "none" (ou "violeta") = a padrão
  #   render Ss::ThemeSwitcherComponent.new(compact: true)                # barra de cima: faixa rolável
  # Com muitas paletas (mais de 8, fora do compact) agrupa por família; group: false desliga.
  class ThemeSwitcherComponent < BaseComponent
    # chave do parâmetro ("none" = sem data-palette) → [nome, slug do swatch]
    PALETTES = ComponentesUi::PALETAS.to_h { |slug, nome|
      [slug == ComponentesUi::PALETA_PADRAO ? "none" : slug, [nome, slug]]
    }.freeze
    # [valor, rótulo pt-BR de reserva, oled]; o texto sai de componentes_ui.theme_switcher.themes.*.
    THEMES = [["system", "Auto", nil], ["light", "Claro", nil], ["dark", "Escuro", false], ["dark", "OLED", true]].freeze
    GROUP_FROM = 9

    def initialize(palettes: PALETTES.keys, oled: true, compact: false, group: nil, label: nil, **opts)
      super(**opts)
      keys = palettes ? Array(palettes).map { |k| k.to_s == ComponentesUi::PALETA_PADRAO ? "none" : k.to_s } : []
      @palettes = PALETTES.slice(*keys)
      @oled = oled
      @compact = compact
      @group = group.nil? ? (!compact && @palettes.size >= GROUP_FROM) : group
      @label = label || ss_t("theme_switcher.label", default: "Aparência")
    end

    def themes
      list = @oled ? THEMES : THEMES.first(3)
      list.map { |value, text, oled| [value, ss_t("theme_switcher.themes.#{oled ? "oled" : value}", default: text), oled] }
    end

    # [[família ou nil, [[chave, nome, slug], …]], …]
    def palette_groups
      items = @palettes.map { |key, (_name, slug)| [key, ss_palette_name(slug), slug] }
      return [[nil, items]] unless @group
      items.group_by { |(_, _, slug)| ComponentesUi::PALETA_FAMILIA[slug] }
           .sort_by { |fam, _| ComponentesUi::PALETA_FAMILIAS.index(fam) || 99 }
    end

    def default_name = (slug = @palettes.values.first&.last) && ss_palette_name(slug)
  end
end
