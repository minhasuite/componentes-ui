module Ss
  # Situação da sincronização (v1.9, par do SsSyncStatus): a pílula "pontinho + texto curto" do .ss-sync —
  # "Tudo salvo", "3 a enviar", "Enviando…" (gira), "Falhou · Tentar de novo", "2 com erro", "Sem conexão".
  #
  #   render Ss::SyncStatusComponent.new(state: :pending, pending_count: 3, href: fila_path)
  #   render Ss::SyncStatusComponent.new(**Ss::SyncStatusComponent.resolve(syncing: false, failed: 1, offline: false, pending: 3))
  #
  # state: :synced | :pending | :sending | :failed | :offline. resolve(...) é a regra do minhas-vendas-app (a mesma do
  # SsSyncStatus.resolve): enviando > com erro > sem conexão > pendente > tudo salvo. failed_count: "2 com erro"
  # no lugar do "Falhou · Tentar de novo". last_synced_at: "Sincronizado às 14:32" (hoje) ou "em 12/11" na dica e
  # no leitor de tela. href: vira link (a fila, tentar de novo). O texto é avisado ao mudar (role=status).
  class SyncStatusComponent < BaseComponent
    STATES = %i[synced pending sending failed offline].freeze

    attr_reader :state

    def self.resolve(syncing: false, failed: 0, offline: false, pending: 0)
      state = if syncing then :sending
      elsif failed.to_i.positive? then :failed
      elsif offline then :offline
      elsif pending.to_i.positive? then :pending
      else :synced
      end
      { state:, pending_count: pending.to_i, failed_count: failed.to_i }
    end

    def initialize(state:, pending_count: 0, failed_count: 0, last_synced_at: nil, href: nil, **rest)
      super(**rest)
      @state = STATES.include?(state&.to_sym) ? state.to_sym : :synced
      @pending, @failed, @last, @href = pending_count.to_i, failed_count.to_i, last_synced_at, href
    end

    def text
      n = @pending
      case state
      when :synced then ss_t("sync_status.synced", default: "Tudo salvo")
      when :pending then ss_t("sync_status.pending", default: n == 1 ? "1 a enviar" : "%{count} a enviar", count: n)
      when :sending then ss_t("sync_status.sending", default: "Enviando…")
      when :failed
        @failed.positive? ? ss_t("sync_status.failed_count", default: "%{count} com erro", count: @failed) : ss_t("sync_status.failed", default: "Falhou · Tentar de novo")
      when :offline
        n.positive? ? ss_t("sync_status.offline_pending", default: "Sem conexão · %{count} a enviar", count: n) : ss_t("sync_status.offline", default: "Sem conexão")
      end
    end

    def last_text
      return nil unless @last

      t = @last.to_time
      if t.to_date == Date.current
        ss_t("sync_status.last_today", default: "Sincronizado às %{time}", time: ss_date(t, :time))
      else
        ss_t("sync_status.last_day", default: "Sincronizado em %{date}", date: ss_date(t, :day_month))
      end
    end

    def call
      inner = safe_join([tag.span(text, role: "status"), (tag.span(", #{last_text}", class: "ss-sr") if last_text)].compact)
      attrs = root_attrs(class: classes("ss-sync", ("ss-sync-link" if @href)), title: last_text, data: { state: })
      @href ? tag.a(inner, href: @href, **attrs) : tag.span(inner, **attrs)
    end
  end
end
