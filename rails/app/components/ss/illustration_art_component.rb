module Ss
  # A arte de uma ilustração dos estados vazios (v1.10, par do SsIllustrationArt): bolha na cor suave da marca,
  # chão, órbita, brilhos e o símbolo do caso, em SVG com tokens (o :error em --danger). Entra crescendo com a
  # mola; parada, o símbolo flutua e os brilhos piscam. Reduzir movimento: parada. Decorativa (aria-hidden): quem
  # usa põe o título por perto. É a mesma arte do EmptyStateComponent(illustration:), que lê daqui.
  #
  #   render Ss::IllustrationArtComponent.new(:offline)
  #   render Ss::IllustrationArtComponent.new(illustration: :all_done, size: 96)
  #
  # illustration: :empty | :offline | :no_results | :all_done | :error (também noResults/allDone, como no
  # Flutter). size: px da largura (132, como o Flutter).
  class IllustrationArtComponent < BaseComponent
    ILLUSTRATIONS = {
      empty: <<~SVG,
        <svg viewBox="0 0 160 120" aria-hidden="true">
          <ellipse class="ss-ill-floor ss-ill-shadow" cx="80" cy="108" rx="48" ry="6"/>
          <circle class="ss-ill-orbit" cx="80" cy="56" r="50"/>
          <circle class="ss-ill-soft" cx="80" cy="56" r="40"/>
          <g class="ss-ill-symbol">
            <rect class="ss-ill-card" x="50" y="34" width="60" height="44" rx="10"/>
            <path class="ss-ill-accent-s" d="M50 60h16l4 7h20l4-7h16"/>
          </g>
          <path class="ss-ill-accent ss-ill-spark" d="M124 18l3 7 7 3-7 3-3 7-3-7-7-3 7-3z"/>
          <path class="ss-ill-accent ss-ill-spark is-2" d="M30 40l2 4.5 4.5 2-4.5 2-2 4.5-2-4.5-4.5-2 4.5-2z"/>
          <circle class="ss-ill-dot ss-ill-spark is-3" cx="132" cy="80" r="3"/>
        </svg>
      SVG
      offline: <<~SVG,
        <svg viewBox="0 0 160 120" aria-hidden="true">
          <ellipse class="ss-ill-floor ss-ill-shadow" cx="80" cy="108" rx="48" ry="6"/>
          <circle class="ss-ill-orbit" cx="80" cy="56" r="50"/>
          <circle class="ss-ill-soft" cx="80" cy="56" r="40"/>
          <g class="ss-ill-symbol">
            <path class="ss-ill-card" d="M58 76a14 14 0 0 1-1-28 20 20 0 0 1 38-5 15 15 0 0 1 8 33z"/>
            <path class="ss-ill-accent-s" d="M60 34l42 46"/>
          </g>
          <path class="ss-ill-line ss-ill-spark is-2" d="M32 84a10 10 0 0 1 10-10M26 84a16 16 0 0 1 16-16"/>
          <path class="ss-ill-accent ss-ill-spark" d="M124 18l3 7 7 3-7 3-3 7-3-7-7-3 7-3z"/>
        </svg>
      SVG
      no_results: <<~SVG,
        <svg viewBox="0 0 160 120" aria-hidden="true">
          <ellipse class="ss-ill-floor ss-ill-shadow" cx="80" cy="108" rx="48" ry="6"/>
          <circle class="ss-ill-orbit" cx="80" cy="56" r="50"/>
          <rect class="ss-ill-card" x="36" y="28" width="56" height="62" rx="11"/>
          <path class="ss-ill-line" d="M48 44h30M48 56h22M48 68h26"/>
          <g class="ss-ill-symbol">
            <circle class="ss-ill-lens" cx="102" cy="62" r="18"/>
            <path class="ss-ill-handle" d="M115 75l13 13"/>
            <path class="ss-ill-accent-s" d="M96 56l12 12M108 56l-12 12"/>
          </g>
          <path class="ss-ill-accent ss-ill-spark" d="M128 18l3 7 7 3-7 3-3 7-3-7-7-3 7-3z"/>
          <circle class="ss-ill-dot ss-ill-spark is-3" cx="26" cy="34" r="3.5"/>
        </svg>
      SVG
      all_done: <<~SVG,
        <svg viewBox="0 0 160 120" aria-hidden="true">
          <ellipse class="ss-ill-floor ss-ill-shadow" cx="80" cy="108" rx="48" ry="6"/>
          <circle class="ss-ill-orbit" cx="80" cy="56" r="50"/>
          <circle class="ss-ill-soft" cx="80" cy="56" r="40"/>
          <g class="ss-ill-symbol">
            <circle class="ss-ill-card" cx="80" cy="56" r="26"/>
            <path class="ss-ill-accent-s ss-ill-check" d="M68 57l8 8 16-17" pathLength="1"/>
          </g>
          <path class="ss-ill-accent ss-ill-spark" d="M124 16l3 7 7 3-7 3-3 7-3-7-7-3 7-3z"/>
          <path class="ss-ill-accent ss-ill-spark is-2" d="M30 30l2 4.5 4.5 2-4.5 2-2 4.5-2-4.5-4.5-2 4.5-2z"/>
          <circle class="ss-ill-dot2 ss-ill-spark is-3" cx="134" cy="78" r="3.5"/>
        </svg>
      SVG
      error: <<~SVG
        <svg viewBox="0 0 160 120" aria-hidden="true">
          <ellipse class="ss-ill-floor ss-ill-shadow" cx="80" cy="108" rx="48" ry="6"/>
          <circle class="ss-ill-orbit is-danger" cx="80" cy="56" r="50"/>
          <circle class="ss-ill-soft is-danger" cx="80" cy="56" r="40"/>
          <g class="ss-ill-symbol">
            <circle class="ss-ill-card" cx="80" cy="56" r="26"/>
            <path class="ss-ill-danger-s" d="M80 43v16M80 68v.5"/>
          </g>
          <circle class="ss-ill-dot ss-ill-spark is-3" cx="30" cy="30" r="4"/>
        </svg>
      SVG
    }.freeze

    KINDS = ILLUSTRATIONS.keys.freeze

    attr_reader :illustration

    def self.normalize(kind)
      k = kind.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym
      ILLUSTRATIONS.key?(k) ? k : :empty
    end

    def initialize(kind = nil, illustration: nil, size: 132, **rest)
      super(**rest)
      @illustration = self.class.normalize(illustration || kind || :empty)
      @size = size.to_i.clamp(48, 480)
    end

    def call
      tag.span(ILLUSTRATIONS[@illustration].html_safe,
               **root_attrs(class: classes("ss-illus ss-empty-art is-anim"), "aria-hidden": "true",
                            style: "--s:#{@size}px", data: { illustration: @illustration }))
    end
  end
end
