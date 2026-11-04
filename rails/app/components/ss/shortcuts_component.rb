module Ss
  # Atalhos de teclado: "?" abre o <dialog> com a lista agrupada (.ss-kbd). Itens com
  # url viram atalho de verdade (sequência "g p" ou tecla única), fora de campos de texto.
  #   render Ss::ShortcutsComponent.new(groups: [{ title: "Ir para", items: [{ keys: "g p", label: "Pedidos", url: pedidos_path }] },
  #                                              { title: "Nesta tela", items: [{ keys: "/", label: "Buscar" }] }])
  class ShortcutsComponent < BaseComponent
    def initialize(groups:, title: nil, **opts)
      super(**opts)
      @groups = groups
      @title = title || ss_t("shortcuts.title", default: "Atalhos de teclado")
    end

    def bindings = @groups.flat_map { |g| g[:items].select { _1[:url] }.map { |i| { keys: i[:keys], url: i[:url] } } }

    def call
      did = "ss-sc-#{object_id}"
      tag.div(**root_attrs(class: classes("ss-shortcuts"), data: { controller: "ss-shortcuts", ss_shortcuts_bindings_value: bindings.to_json,
                                                                   action: "keydown@document->ss-shortcuts#key" })) do
        safe_join([
          content,
          tag.dialog(class: "ss-dialog ss-sc-dialog", "aria-labelledby": "#{did}-t", data: { ss_shortcuts_target: "dialog" }) do
            safe_join([
              tag.div(class: "ss-sc-head") { safe_join([tag.h2(@title, id: "#{did}-t"), tag.button("×", type: "button", class: "ss-sc-close", "aria-label": ss_t("common.close", default: "Fechar"), data: { action: "ss-shortcuts#close" })]) },
              tag.div(class: "ss-sc-body") { safe_join(@groups.map { group(_1) }) },
              tag.p(safe_join(["Aperte ", tag.kbd("?", class: "ss-kbd"), " em qualquer tela para ver esta lista."]), class: "ss-sc-foot")
            ])
          end
        ])
      end
    end

    private

    def group(g)
      tag.section do
        safe_join([tag.h3(g[:title]), tag.dl(safe_join(g[:items].map { |i| tag.div(safe_join([tag.dt(i[:label]), tag.dd(keys(i[:keys]))])) }))])
      end
    end

    def keys(k)
      parts = k.to_s.split(" ")
      safe_join(parts.each_with_index.flat_map { |p, i| [(tag.span(ss_t("shortcuts.then", default: "depois"), class: "ss-sc-then") if i.positive?), tag.kbd(p, class: "ss-kbd")].compact })
    end
  end
end
