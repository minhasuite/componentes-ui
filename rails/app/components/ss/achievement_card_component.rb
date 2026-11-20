module Ss
  # Cartão de conquista (v1.8, par do SsAchievementCard): medalhão com o ícone, o título, a regra (description) e o
  # rodapé. Conquistada (earned: true): medalhão na cor da marca e o selo "Conquistada" com o caption ("em 12/11").
  # Ainda não: medalhão apagado e, com progress (0 a 1), a barra fina e o progress_label ("12 de 30 dias").
  # Vários lado a lado: dentro de .ss-achievement-grid (auto-fill, mínimo 14rem).
  #
  #   <div class="ss-achievement-grid">
  #     <%= render Ss::AchievementCardComponent.new(title: "Primeiro turno coberto", description: "Cobriu um turno aberto.",
  #                                                 earned: true, caption: "em 12/11") %>
  #     <%= render Ss::AchievementCardComponent.new(title: "30 dias seguidos", description: "Sequência de 30 dias.", icon: "fire",
  #                                                 progress: 0.4, progress_label: "12 de 30 dias") %>
  #   </div>
  #
  # icon: nome do ss_icon (padrão "trophy", o badge-check do conjunto; o mesmo do Flutter). href: o cartão vira link.
  class AchievementCardComponent < BaseComponent
    def initialize(title:, description:, icon: "trophy", earned: false, caption: nil, progress: nil, progress_label: nil, href: nil, **rest)
      super(**rest)
      @title, @description, @icon = title, description, icon
      @earned = earned ? true : false
      @caption, @progress_label, @href = caption.presence, progress_label.presence, href
      @progress = progress.nil? ? nil : progress.to_f.clamp(0.0, 1.0)
    end

    def call
      attrs = root_attrs(class: classes("ss-card", "ss-achievement", @earned ? "is-earned" : "is-locked"))
      parts = safe_join([medal, title, tag.p(@description, class: "ss-achievement-text"), foot].compact)
      @href ? link_to(@href, **attrs) { parts } : tag.article(**attrs) { parts }
    end

    private

    def medal = tag.span(ss_icon(@icon, size: nil), class: "ss-achievement-medal", "aria-hidden": "true")

    def title
      tag.h3(class: "ss-achievement-title") do
        safe_join([tag.span("#{ss_t('achievement.label', default: 'Conquista')}: ", class: "ss-sr"), @title])
      end
    end

    def foot
      if @earned
        tag.p(class: "ss-achievement-foot") do
          safe_join([tag.span(class: "ss-badge ss-badge-accent ss-achievement-seal") { safe_join([ss_icon("check", size: :xs), tag.span(ss_t("achievement.earned", default: "Conquistada"))]) },
                     (tag.span(@caption, class: "ss-achievement-caption") if @caption)].compact, " ")
        end
      elsif @progress || @progress_label
        missing = ss_t("achievement.missing", default: "Falta")
        tag.div(class: "ss-achievement-progress") do
          safe_join([progress_bar(missing), (tag.small(@progress_label) if @progress_label)].compact)
        end
      end
    end

    def progress_bar(missing)
      return nil unless @progress

      pct = (@progress * 100).round
      tag.div(class: "ss-progress", role: "progressbar", "aria-valuenow": pct, "aria-valuemin": 0, "aria-valuemax": 100,
              "aria-label": @progress_label ? "#{missing}: #{@progress_label}" : @title) do
        tag.div(class: "ss-progress-bar", style: "width:#{pct}%")
      end
    end
  end
end
