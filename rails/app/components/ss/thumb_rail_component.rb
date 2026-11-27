module Ss
  # Miniaturas em coluna ao lado da foto grande (produto, planta) (v1.10, par do SsThumbRail): a ativa ganha borda
  # na cor da marca e as outras ficam apagadas. Setas em cima e embaixo rolam uma miniatura e somem nas pontas.
  #
  #   <img id="foto" src="<%= fotos.first %>" alt="Vaso">
  #   render Ss::ThumbRailComponent.new(images: fotos, selected: 0, target: "foto", height: 320)
  #   images: [{ src: "/a.jpg", full: "/a-grande.jpg", alt: "Frente" }, …]
  #
  # Clicar escolhe (onSelect): dispara ss-thumb-rail:select { index, src } e, com target: (id de um <img>), troca
  # o src dele (full: ou src:). url: com %{index} (0, 1, …) faz de cada miniatura um link, para a página trocar
  # do servidor. thumb_size: px (64). height: px da coluna (padrão: a altura do pai). Teclado: ↑ ↓ andam entre
  # as miniaturas; leitor de tela: "Imagem 2 de 5", a escolhida como pressionada.
  class ThumbRailComponent < BaseComponent
    def initialize(images:, selected: 0, target: nil, url: nil, thumb_size: 64, height: nil, **rest)
      super(**rest)
      @images = Array(images).map { |i| i.is_a?(Hash) ? i.transform_keys(&:to_sym) : { src: i.to_s } }
      @selected = selected.to_i.clamp(0, [@images.size - 1, 0].max)
      @target, @url = target, url&.to_s
      @thumb = thumb_size.to_i.clamp(32, 160)
      @height = height&.to_i
    end

    def image_label(i) = ss_t("thumb_rail.image_of", default: "Imagem %{i} de %{n}", i: i + 1, n: @images.size)

    def call
      style = ["--ts:#{@thumb}px", ("height:#{@height}px" if @height)].compact.join(";")
      tag.div(**root_attrs(class: classes("ss-thumbs"), style:, role: "group", "aria-label": ss_t("thumb_rail.label", default: "Miniaturas"),
                           data: { controller: "ss-thumb-rail", ss_thumb_rail_target_value: @target }.compact)) do
        safe_join([
          arrow("chevron-up", -1, ss_t("thumb_rail.previous", default: "Miniaturas anteriores"), "up"),
          tag.div(class: "ss-thumbs-list", data: { ss_thumb_rail_target: "list", action: "scroll->ss-thumb-rail#update keydown->ss-thumb-rail#key" }) do
            safe_join(@images.each_with_index.map { |img, i| thumb(img, i) })
          end,
          arrow("chevron-down", 1, ss_t("thumb_rail.next", default: "Próximas miniaturas"), "down")
        ])
      end
    end

    private

    def arrow(icon, dir, label, name)
      tag.button(ss_icon(icon, size: nil), type: "button", class: "ss-thumbs-arrow", "aria-label": label, hidden: (dir.negative? || nil),
                 data: { ss_thumb_rail_target: name, action: "ss-thumb-rail##{dir.negative? ? "up" : "down"}" })
    end

    def thumb(img, i)
      on = i == @selected
      inner = image_tag(img[:src], alt: "", loading: "lazy")
      attrs = { class: "ss-thumbs-item", "aria-label": [image_label(i), img[:alt]].compact.join(": "), tabindex: (on ? nil : "-1"),
                data: { index: i, src: img[:full] || img[:src], ss_thumb_rail_target: "item" } }
      if @url
        link_to(inner, @url.gsub("%{index}", i.to_s), **attrs, "aria-current": (on ? "true" : nil))
      else
        tag.button(inner, type: "button", **attrs, "aria-pressed": on.to_s, data: attrs[:data].merge(action: "ss-thumb-rail#select"))
      end
    end
  end
end
