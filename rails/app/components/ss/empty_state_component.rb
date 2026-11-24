module Ss
  # Estado vazio ilustrado: variant :nada (nada ainda), :busca (sem resultado), :erro.
  # Ilustração SVG em linha com os tokens (muda com a marca e o tema).
  #   render Ss::EmptyStateComponent.new(variant: :busca, title: "Nada com “xyz”",
  #     text: "Confira a grafia ou tire filtros.", primary: { label: "Limpar busca", url: "?" },
  #     secondary: { label: "Novo cliente", url: new_cliente_path })
  # Bloco opcional: ações próprias (forms, botões) no lugar de primary/secondary.
  #
  # v0.10.1: with_art { image_tag "vazio.svg", alt: "" } troca a ilustração pela do app;
  # art: false tira a ilustração (fica só título, texto e ações).
  #
  # v1.9: illustration: :empty, :offline, :no_results, :all_done ou :error troca a arte pela
  # ilustração animada (a mesma do SsEmptyState(illustration:) do Flutter); :error vira role=alert.
  #   render Ss::EmptyStateComponent.new(illustration: :all_done, title: "Tudo em dia", text: "Nenhuma tarefa para hoje.")
  class EmptyStateComponent < BaseComponent
    include InView

    renders_one :art
    ART = {
      nada: <<~SVG,
        <svg viewBox="0 0 160 120" aria-hidden="true">
          <ellipse class="ss-ill-floor" cx="80" cy="106" rx="54" ry="7"/>
          <circle class="ss-ill-orbit" cx="80" cy="58" r="50"/>
          <rect class="ss-ill-card" x="44" y="30" width="72" height="62" rx="14"/>
          <path class="ss-ill-soft" d="M44 54h72v24a14 14 0 0 1-14 14H58a14 14 0 0 1-14-14z"/>
          <path class="ss-ill-line" d="M60 48h40M60 60h26"/>
          <path class="ss-ill-accent" d="M118 22l3 7 7 3-7 3-3 7-3-7-7-3 7-3z"/>
          <circle class="ss-ill-dot" cx="34" cy="34" r="4"/><circle class="ss-ill-dot2" cx="132" cy="82" r="3"/>
        </svg>
      SVG
      busca: <<~SVG,
        <svg viewBox="0 0 160 120" aria-hidden="true">
          <ellipse class="ss-ill-floor" cx="80" cy="106" rx="54" ry="7"/>
          <rect class="ss-ill-card" x="30" y="26" width="64" height="70" rx="12"/>
          <path class="ss-ill-line" d="M44 44h36M44 56h28M44 68h32"/>
          <circle class="ss-ill-lens" cx="100" cy="64" r="22"/>
          <path class="ss-ill-handle" d="M116 80l16 16"/>
          <path class="ss-ill-accent-s" d="M94 58c0-4 3-6 6-6s6 2 6 6c0 4-6 4-6 8M100 72v.5"/>
          <circle class="ss-ill-dot" cx="134" cy="30" r="4"/>
        </svg>
      SVG
      erro: <<~SVG
        <svg viewBox="0 0 160 120" aria-hidden="true">
          <ellipse class="ss-ill-floor" cx="80" cy="106" rx="54" ry="7"/>
          <path class="ss-ill-card" d="M50 86a20 20 0 0 1-2-40 28 28 0 0 1 54-6 22 22 0 0 1 8 46z"/>
          <path class="ss-ill-danger" d="M84 46l-12 20h10l-6 18 16-24H82l6-14z"/>
          <circle class="ss-ill-dot" cx="30" cy="30" r="4"/><circle class="ss-ill-dot2" cx="136" cy="36" r="3"/>
        </svg>
      SVG
    }.freeze

    # v1.9 · ilustrações animadas (par do SsEmptyState(illustration: SsIllustration.*) do Flutter):
    # entram crescendo com mola; paradas, o símbolo flutua e os brilhos piscam (só CSS, nada com
    # prefers-reduced-motion). Cor só por token (--accent; :error em --danger).
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

    def initialize(title:, text: nil, variant: :nada, primary: nil, secondary: nil, compact: false, art: true, illustration: nil, **opts)
      super(**opts)
      @show_art = art != false
      @title = title
      @text = text
      @variant = ART.key?(variant.to_sym) ? variant.to_sym : :nada
      @primary = primary
      @secondary = secondary
      @compact = compact
      ill = illustration&.to_sym
      @illustration = ILLUSTRATIONS.key?(ill) ? ill : nil
    end

    def call
      tag.div(**root_attrs(class: classes("ss-empty-state", ("is-compact" if @compact)), data: in_view_data(variant: @variant, illustration: @illustration), role: (error? ? "alert" : nil))) do
        safe_join([
          art_tag,
          tag.h3(@title),
          (tag.p(@text) if @text),
          actions
        ].compact)
      end
    end

    private

    def art_tag
      return nil unless @show_art
      return tag.div(art, class: "ss-empty-art is-custom") if art?

      return tag.div(ILLUSTRATIONS[@illustration].html_safe, class: "ss-empty-art is-anim", data: { illustration: @illustration }) if @illustration

      tag.div(ART[@variant].html_safe, class: "ss-empty-art")
    end

    def error? = @illustration ? @illustration == :error : @variant == :erro

    def actions
      return tag.div(content, class: "ss-empty-actions") if content.present?
      return nil unless @primary || @secondary

      tag.div(class: "ss-empty-actions") do
        safe_join([
          (link_to(@primary[:label], @primary[:url], class: "ss-btn ss-btn-primary") if @primary),
          (link_to(@secondary[:label], @secondary[:url], class: "ss-btn ss-btn-ghost") if @secondary)
        ].compact)
      end
    end
  end
end
