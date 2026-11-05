module Ss
  # Lista de arrastar para mudar a ordem (v0.10.2, par do SsReorderableList): seções de um
  # painel, favoritos, passos. Cada item tem a alça (.ss-sortable-handle): arrasta com o mouse
  # ou o dedo, e com o foco nela ↑/↓ movem (o leitor de tela ouve "Movido para a posição 2 de 5").
  #
  #   render Ss::SortableListComponent.new(url: reorder_site_favorites_path(@site), label: "Favoritos") do |l|
  #     @favoritos.each { |f| l.with_item(id: f.id, title: f.title) { render "favorito", f: } }
  #   end
  #
  # - url: manda a ordem nova a cada mudança: PATCH JSON { ids: [...] } (param: troca "ids"),
  #   com o token CSRF; method: troca o verbo. Sem url, só o evento ss-sortable:change
  #   (detail: { ids }) e, com name:, um input hidden name[] por item na ordem (dentro de um form).
  # - title: de cada item vai no nome da alça ("Arrastar para mudar a ordem: Sala").
  # - gap: espaço entre os itens (CSS, padrão .5rem).
  class SortableListComponent < BaseComponent
    GRIP = %(<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><circle cx="9" cy="6" r="1.6"/><circle cx="15" cy="6" r="1.6"/><circle cx="9" cy="12" r="1.6"/><circle cx="15" cy="12" r="1.6"/><circle cx="9" cy="18" r="1.6"/><circle cx="15" cy="18" r="1.6"/></svg>).freeze

    renders_many :items, lambda { |id:, title: nil, **attrs, &block|
      label = ss_t("sortable.handle", title: title.to_s, default: "Arrastar para mudar a ordem: %{title}").sub(/:\s*\z/, "")
      tag.li(class: ["ss-sortable-item", attrs.delete(:class)].compact.join(" "), data: { id:, ss_sortable_target: "item" }, **attrs) do
        safe_join([
          tag.button(GRIP.html_safe, type: "button", class: "ss-sortable-handle", title: label, "aria-label": label,
                     "aria-describedby": "#{list_id}-hint",
                     data: { action: "pointerdown->ss-sortable#grab keydown->ss-sortable#key" }),
          tag.div(class: "ss-sortable-main", &block),
          (hidden_field_tag("#{@name}[]", id, id: nil) if @name)
        ].compact)
      end
    }

    def initialize(url: nil, method: :patch, param: "ids", name: nil, label: nil, gap: nil, id: nil, **opts)
      super(**opts)
      @url, @method, @param, @name, @label, @gap = url, method, param, name, label, gap
      @id = id || "ss-sortable-#{SecureRandom.hex(3)}"
    end

    def list_id = @id
    def label = @label || ss_t("sortable.label", default: "Lista ordenável")

    def call
      style = [("--ss-sortable-gap: #{@gap}" if @gap), @attrs[:style]].compact.join("; ").presence
      tag.div(**root_attrs(class: classes("ss-sortable-wrap"), style:,
                           data: { controller: "ss-sortable", ss_sortable_url_value: @url, ss_sortable_method_value: @method.to_s.upcase,
                                   ss_sortable_param_value: @param,
                                   ss_sortable_moved_value: ss_t("sortable.moved", n: "{n}", total: "{total}", default: "Movido para a posição {n} de {total}") })) do
        safe_join([
          tag.ol(safe_join(items), class: "ss-sortable", id: list_id, "aria-label": label, data: { ss_sortable_target: "list" }),
          tag.p("#{ss_t("sortable.up", default: "Mover para cima")} / #{ss_t("sortable.down", default: "Mover para baixo")}: ↑ ↓",
                id: "#{list_id}-hint", class: "ss-sr"),
          tag.p(class: "ss-sr", role: "status", data: { ss_sortable_target: "live" })
        ])
      end
    end
  end
end
