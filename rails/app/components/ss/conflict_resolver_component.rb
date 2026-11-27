module Ss
  # v1.13.0 "confiança na IA e suíte" (par do SsConflictResolver): o mesmo registro mudou em dois lugares. Mostra "Sua
  # versão" × "Versão do servidor" campo a campo (só os que diferem; os iguais viram uma linha "3 campos iguais…"), com
  # um rádio por lado em cada campo (resolve[campo] = mine | theirs; a sua vem marcada), "Ficar com a minha"/"Ficar
  # com a do servidor" (o ss-conflict marca todos) e "Salvar escolha".
  #
  #   <%= render Ss::ConflictResolverComponent.new(url: resolver_pedido_path(@pedido), theirs_by: outro.nome,
  #         theirs_at: @pedido.updated_at, fields: [{ key: :obs, label: "Observação", mine: params_obs, theirs: @pedido.obs }]) %>
  #
  # No web, aparece quando o salvar bate num registro velho (lock_version, ActiveRecord::StaleObjectError): o produto
  # mostra este formulário em vez de sobrescrever. No app, é o par que a fila offline abre pelo SsSyncPanel.
  # Onde entra: minhas-vendas (pedido e cliente editados no desktop e no app), meu-gestor (card de fluxo), meu-personal
  # (treino editado no app offline).
  class ConflictResolverComponent < BaseComponent
    def initialize(fields:, url:, title: nil, method: :patch, param: "resolve", mine_at: nil, theirs_at: nil, theirs_by: nil,
                   cancel_href: nil, **opts)
      super(**opts)
      all = Array(fields).map { _1.to_h.transform_keys(&:to_sym) }
      @fields = all.reject { _1[:mine].to_s == _1[:theirs].to_s }
      @same = all.size - @fields.size
      @url = url
      @title = title
      @http_method = method
      @param = param
      @mine_at = mine_at
      @theirs_at = theirs_at
      @theirs_by = theirs_by
      @cancel_href = cancel_href
    end

    attr_reader :fields, :same, :url, :http_method, :param, :cancel_href

    def t(key, **o) = ss_t("trust.#{key}", **o)
    def title = @title || t("conflict_title")
    def uid = @uid ||= "ss-conflict-#{object_id}"
    def same_text = same == 1 ? t("conflict_same_one") : t("conflict_same", count: same)
    def mine_meta = @mine_at && ss_trust_ago(@mine_at)
    def theirs_meta = [(@theirs_at && ss_trust_ago(@theirs_at)), (@theirs_by && t("conflict_by", name: @theirs_by))].compact.join(" · ").presence
    def show(v) = v.to_s.presence || t("conflict_empty")
  end
end
