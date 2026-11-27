module Ss
  # v1.13.0 "confiança na IA e suíte" (par do SsSinceLastVisit): o cartão ao abrir, "Desde ontem às 18h: 3 pedidos
  # novos, R$ 1.240 recebidos, 1 tarefa atrasada". Cada item com o número que rola (Ss::OdometerComponent(roll_in:)) e
  # a ação dele. Some sozinho em auto_hide: segundos (pausa com o mouse ou o foco em cima; nil não some) ou com
  # "Entendi"; nos dois casos o ss-since grava a última visita no localStorage (storage_key:).
  #
  #   <%= render Ss::SinceLastVisitComponent.new(since: current_user.visto_em, items: [
  #         { value: "3", label: "pedidos novos", icon: "shopping-bag", href: pedidos_path(novos: 1) },
  #         { value: ss_money(1240), label: "recebidos", icon: "cash", tone: :success },
  #         { value: "1", label: "tarefa atrasada", icon: "clock", tone: :warn, href: tarefas_path, action_label: "Ver" }]) %>
  #
  # Sem saber a última visita no servidor: src: "/novidades?desde=%{since}" — o ss-since lê o localStorage e busca o
  # cartão (o HTML deste componente) com a data em ISO 8601; na 1ª visita só guarda o agora. Sem itens, nada aparece.
  #
  # Onde entra: minhas-vendas (pedidos e recebimentos desde a última visita), meu-gestor (tarefas e aprovações),
  # meu-financeiro (lançamentos e faturas), meu-personal (treinos dos alunos).
  class SinceLastVisitComponent < BaseComponent
    TONES = %i[accent success warn danger muted].freeze

    attr_reader :since, :items, :storage_key, :auto_hide, :src

    # "Desde ontem às 18h" no idioma da página: mesmo dia → hoje; dia anterior → ontem; até 6 dias → o dia da semana;
    # mais → "Desde 12/11". (Os mesmos moldes do SsSinceLastVisit.label.)
    def self.since_label(since, now: Time.current, h: nil)
      h ||= Object.new.extend(ComponentesUi::Helpers)
      since = since.in_time_zone
      days = (now.to_date - since.to_date).to_i
      time = h.ss_trust_clock(since)
      if days <= 0 then h.ss_t("trust.since_today", time:)
      elsif days == 1 then h.ss_t("trust.since_yesterday", time:)
      elsif days < 7 then h.ss_t("trust.since_weekday", time:, weekday: Array(h.ss_t("trust.weekdays"))[since.wday])
      else h.ss_t("trust.since_date", date: h.ss_date(since, :day_month))
      end
    end

    def initialize(since: nil, items: [], storage_key: "ss-last-visit", auto_hide: 12, now: nil, src: nil, **opts)
      super(**opts)
      @since = since
      @items = Array(items).map { _1.to_h.transform_keys(&:to_sym) }
      @storage_key = storage_key
      @auto_hide = auto_hide
      @now = now
      @src = src
    end

    def render? = @src.present? || (@since && @items.any?)
    def t(key, **o) = ss_t("trust.#{key}", **o)
    def label = self.class.since_label(@since, now: @now || Time.current, h: self)
    def uid = @uid ||= "ss-since-#{object_id}"
    def tone(i) = TONES.include?(i[:tone]&.to_sym) ? i[:tone].to_sym : :accent
    def data
      { controller: "ss-since", ss_since_key_value: storage_key, ss_since_auto_hide_value: auto_hide.to_i,
        ss_since_src_value: src, action: "mouseenter->ss-since#pause mouseleave->ss-since#resume focusin->ss-since#pause focusout->ss-since#resume" }.compact
    end
  end
end
