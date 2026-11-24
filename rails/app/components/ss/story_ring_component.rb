module Ss
  # Avatar com anel de novidades em gomos (v1.9, par do SsStoryRing): um gomo por novidade; os novos no gradiente
  # da marca, os vistos numa linha neutra fina. Quando entra na tela, os gomos se desenham em sequência.
  #
  #   render Ss::StoryRingComponent.new(name: "Ana Souza", segments: 3, seen: 1, caption: "Ana", href: story_path(a))
  #   render Ss::StoryRingComponent.new(name: "Você", segments: 0, caption: "Você", add_href: new_story_path)
  #
  # segments: total de gomos (0 = só o anel fino); seen: quantos já foram vistos (os primeiros). size: px (64).
  # href: o avatar vira link; add_href: o "+" no canto (outro link, "Adicionar"). caption: o nome embaixo (negrito
  # quando há novidade). Leitor de tela: "Ana Souza, 2 novidades". Reduzir movimento: o anel já aparece pronto.
  class StoryRingComponent < BaseComponent
    include InView

    def initialize(name:, segments: 1, seen: 0, size: 64, caption: nil, href: nil, add_href: nil, add_label: nil, **rest)
      super(**rest)
      @name, @segments = name.to_s, [segments.to_i, 0].max
      @seen = seen.to_i.clamp(0, @segments)
      @size, @caption, @href, @add_href, @add_label = size.to_i.clamp(32, 160), caption, href, add_href, add_label
    end

    def news = @segments - @seen

    def label
      return @name if news.zero?

      "#{@name}, #{ss_t("story_ring.news", default: news == 1 ? "1 novidade" : "%{count} novidades", count: news)}"
    end

    def uid = @uid ||= "ss-story-#{object_id}"

    # Gomos em unidades de pathLength 100: [início, comprimento, visto?]. Com mais de um, 4 de folga entre eles.
    def arcs
      n = [@segments, 1].max
      gap = n > 1 ? 4.0 : 0.0
      len = 100.0 / n - gap
      Array.new(n) { |i| [i * 100.0 / n + gap / 2, len, @segments.zero? || i < @seen] }
    end

    def ring
      grad = tag.defs(tag.linearGradient(safe_join(%w[1 2 3].each_with_index.map { |k, i| tag.stop(offset: "#{i * 50}%", style: "stop-color:var(--aurora-#{k})") }),
                                         id: "#{uid}-g", x1: "0", y1: "0", x2: "1", y2: "1"))
      segs = arcs.each_with_index.map do |(start, len, seen), i|
        tag.circle(cx: 50, cy: 50, r: 47, pathLength: 100, class: (seen ? "is-seen" : "is-new"),
                   style: "--len:#{len.round(2)};--off:#{(-start).round(2)};--i:#{i};#{seen ? "" : "stroke:url(##{uid}-g)"}")
      end
      tag.svg(safe_join([grad, *segs]), viewBox: "0 0 100 100", class: "ss-story-svg", "aria-hidden": "true")
    end

    def call
      face = safe_join([tag.span(safe_join([ring, tag.span(ss_avatar(@name, size: @size - 10), class: "ss-story-face")]), class: "ss-story-ring", "aria-hidden": "true"),
                        (tag.span(@caption, class: "ss-story-caption", "aria-hidden": "true") if @caption)].compact)
      main = if @href
        tag.a(face, href: @href, class: "ss-story-main", "aria-label": label)
      else
        tag.span(face, class: "ss-story-main", role: "img", "aria-label": label)
      end
      add = if @add_href
        add_label = @add_label || ss_t("story_ring.add", default: "Adicionar")
        tag.a(ss_icon("plus", size: nil), href: @add_href, class: "ss-story-add", "aria-label": add_label, title: add_label)
      end
      tag.div(safe_join([main, add].compact), **root_attrs(class: classes("ss-story", ("has-news" if news.positive?)), style: "--s:#{@size}px",
                                                         data: in_view_data))
    end
  end
end
