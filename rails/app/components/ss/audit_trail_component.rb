module Ss
  # Histórico de mudanças: quem, quando, o quê, e cada campo "de → para" com o
  # trecho que mudou destacado (vermelho/verde tonal).
  #   render Ss::AuditTrailComponent.new(entries: [
  #     { who: "Ana Souza", at: 2.hours.ago, action: "alterou o pedido 1042",
  #       changes: [{ field: "Valor", from: "R$ 1.250,00", to: "R$ 1.320,00" }] }])
  class AuditTrailComponent < BaseComponent
    include InView
    def initialize(entries:, label: "Histórico de alterações", **opts)
      super(**opts)
      @entries = entries
      @label = label
    end

    # Divide de/para em [prefixo comum, trecho diferente, sufixo comum] por palavra.
    def self.diff(from, to)
      a = from.to_s.split(/(\s+)/)
      b = to.to_s.split(/(\s+)/)
      pre = 0
      pre += 1 while pre < a.size && pre < b.size && a[pre] == b[pre]
      suf = 0
      suf += 1 while suf < a.size - pre && suf < b.size - pre && a[-1 - suf] == b[-1 - suf]
      cut = ->(arr) { [arr[0...pre].join, arr[pre...(arr.size - suf)].join, arr[(arr.size - suf)..].join] }
      [cut.call(a), cut.call(b)]
    end

    def call
      tag.ol(**root_attrs(class: classes("ss-audit"), "aria-label": @label, data: in_view_data(stagger: true))) do
        safe_join(@entries.map { entry(_1) })
      end
    end

    private

    def entry(e)
      tag.li(class: "ss-audit-entry") do
        safe_join([
          ss_avatar(e[:who], size: 32),
          tag.div(class: "ss-audit-body") do
            safe_join([
              tag.p(class: "ss-audit-head") { safe_join([tag.b(e[:who]), " ", e[:action], " ", time(e[:at])]) },
              (tag.dl(safe_join(e[:changes].map { change(_1) }), class: "ss-audit-changes") if e[:changes].present?),
              (tag.p(e[:note], class: "ss-audit-note") if e[:note])
            ].compact)
          end
        ])
      end
    end

    def time(at)
      return tag.small(at.to_s) unless at.respond_to?(:strftime)

      tag.time(at.strftime("%d/%m %H:%M"), datetime: at.iso8601, class: "num")
    end

    def change(c)
      (fa, fb) = self.class.diff(c[:from], c[:to])
      from = c[:from].blank? ? tag.span("vazio", class: "ss-audit-none") : tag.span(class: "ss-audit-from") { safe_join([fa[0], tag.del(fa[1]), fa[2]]) }
      to = c[:to].blank? ? tag.span("vazio", class: "ss-audit-none") : tag.span(class: "ss-audit-to") { safe_join([fb[0], tag.ins(fb[1]), fb[2]]) }
      tag.div(class: "ss-audit-change") do
        safe_join([tag.dt(c[:field]), tag.dd { safe_join([from, tag.span(" → ", class: "ss-audit-arrow", "aria-label": "para"), to]) }])
      end
    end
  end
end
