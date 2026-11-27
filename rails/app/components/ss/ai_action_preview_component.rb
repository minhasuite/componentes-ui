module Ss
  # v1.13.0 "confiança na IA e suíte" (par do SsAiActionPreview): antes de a IA aplicar uma mudança, o antes e depois
  # campo a campo, com as cores semânticas e o nome do tipo em texto (Novo, Removido, Alterado; nunca só a cor). Várias
  # alterações, cada uma com a caixa de marcar (changes[] = id); "Marcar todas"/"Desmarcar todas", a contagem ao vivo e
  # Aplicar (trava com nenhuma marcada), Ajustar (adjust_href:) e Cancelar (cancel_href:, ou fecha o diálogo em volta).
  #
  #   <%= render Ss::DialogComponent.new(id: "previa-ia", title: "Antes de aplicar") do %>
  #     <%= render Ss::AiActionPreviewComponent.new(apply_url: aplicar_sugestao_path(s), adjust_href: chat_path,
  #           changes: s.mudancas.map { { id: _1.id, title: _1.titulo, fields: _1.campos } }) %>
  #   <% end %>
  #   <%= render Ss::ChatActionComponent.new(title: "Recategorizar 3 lançamentos", review_dialog: "previa-ia", ...) %>
  #
  # Campo: { label:, before:, after: } (nil = vazio; igual nos dois = some). Depois de aplicar, o produto responde com
  # turbo_stream.append "ss-toasts", Ss::ToastComponent.new(message: ss_t("trust.preview_applied", count: n),
  # undo_url: desfazer_path) — o "Desfazer" da v1.9.
  #
  # Onde entra: meu-financeiro (a IA recategoriza lançamentos), minhas-vendas (ajuste de preço e cadastro sugerido),
  # meu-gestor (automação de fluxo proposta), minhas-compras (cupom lido pela IA antes de gravar).
  class AiActionPreviewComponent < BaseComponent
    attr_reader :apply_url, :http_method, :param, :adjust_href, :cancel_href

    # :added (só depois), :removed (só antes), :changed ou :same.
    def self.kind(before, after)
      b, a = before.to_s.presence, after.to_s.presence
      return :same if b == a
      return :added if b.nil?
      return :removed if a.nil?

      :changed
    end

    def initialize(changes:, apply_url:, method: :post, param: "changes", adjust_href: nil, cancel_href: nil, title: nil, subtitle: nil, **opts)
      super(**opts)
      @changes = Array(changes).map do |c|
        c = c.to_h.transform_keys(&:to_sym)
        fields = Array(c[:fields]).map { _1.to_h.transform_keys(&:to_sym) }
                                  .map { _1.merge(kind: self.class.kind(_1[:before], _1[:after])) }.reject { _1[:kind] == :same }
        c.merge(fields:, selected: c.fetch(:selected, true))
      end
      @apply_url = apply_url
      @http_method = method
      @param = param
      @adjust_href = adjust_href
      @cancel_href = cancel_href
      @title = title
      @subtitle = subtitle
    end

    def changes = @changes
    def t(key, **o) = ss_t("trust.#{key}", **o)
    def title = @title || t("preview_title")
    def subtitle = @subtitle || t("preview_subtitle")
    def uid = @uid ||= "ss-aip-#{object_id}"
    def selected_count = @changes.count { _1[:selected] }
    def counter = t("preview_selected", count: selected_count, total: @changes.size)
    def kind_label(kind) = t("preview_#{kind}")
    def empty = t("preview_empty")
  end
end
