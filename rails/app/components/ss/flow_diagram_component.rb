module Ss
  # Fluxo de energia: um nó central (casa) e até 4 em volta (rede, solar, bateria, outro). As
  # ligações são pontos que correm no sentido da energia, mais rápido quanto maior a potência.
  #
  #   render Ss::FlowDiagramComponent.new(
  #     center: { id: :casa, kind: :home, label: "Casa", value: "2,4 kW" },
  #     around: [{ id: :solar, kind: :solar, label: "Solar", value: "3,8 kW" },
  #              { id: :rede, kind: :grid, label: "Rede", value: "1,4 kW" },
  #              { id: :bat, kind: :battery, label: "Bateria", value: "1 kW", caption: "72%" }],
  #     links: [{ from: :solar, to: :casa, power: 3800 }, { from: :casa, to: :rede, power: 1400 }])
  #
  # kind: :grid | :solar | :battery | :home | :custom (icon: "<svg…>", color: cor CSS). slot: :top |
  # :left | :right | :bottom (padrão pela ordem). power > 0 corre de from para to; < 0 ao contrário;
  # 0 fica só o trilho. Velocidade ∝ |power| / max_power. É o único laço contínuo da suíte: para
  # com animate: false e com prefers-reduced-motion (aí mostra uma seta parada no sentido).
  # Caixa estreita (≲ 350 px, v0.10.1): nomes menores e o do nó de cima vai para cima do disco,
  # para não encostar no do centro (data-slot no nó; regra @container no CSS).
  class FlowDiagramComponent < BaseComponent
    W, H = 360, 300
    SLOTS = { top: [180, 46], left: [52, 140], right: [308, 140], bottom: [180, 250] }.freeze
    COLORS = { grid: "var(--ss-info)", solar: "#e0952a", battery: "var(--success)", home: "var(--accent)",
               custom: "var(--muted)" }.freeze
    ICONS = { grid: :grid, solar: :solar, battery: :battery, home: :home, custom: :bolt }.freeze
    R_CENTER, R_NODE = 42, 31

    Node = Struct.new(:id, :kind, :label, :value, :caption, :icon, :color, :x, :y, :r, :slot, keyword_init: true)
    Link = Struct.new(:x1, :y1, :x2, :y2, :power, :color, :dur, keyword_init: true)

    attr_reader :nodes, :links

    def initialize(center:, around: [], links: [], max_power: 5000, animate: true, label: nil, **rest)
      super(**rest)
      @animate = animate
      @max = max_power.to_f.positive? ? max_power.to_f : 5000.0
      c = center.to_h.transform_keys(&:to_sym)
      @nodes = { c[:id].to_s => node(c, W / 2, 140, R_CENTER, :center) }
      free = SLOTS.keys - around.map { |n| n.to_h.transform_keys(&:to_sym)[:slot]&.to_sym }.compact
      around.first(4).each do |n|
        n = n.to_h.transform_keys(&:to_sym)
        slot = (n[:slot]&.to_sym if SLOTS.key?(n[:slot]&.to_sym)) || free.shift || :bottom
        x, y = SLOTS[slot]
        @nodes[n[:id].to_s] = node(n, x, y, R_NODE, slot)
      end
      @links = Array(links).filter_map { |l| link(l.to_h.transform_keys(&:to_sym)) }
      @label = label
    end

    def animate? = !!@animate
    def icon(name) = Ss::CasaIcons.svg(name)

    def node_icon(n)
      n.icon.present? ? n.icon.to_s.html_safe : icon(ICONS[n.kind] || :bolt)
    end

    # Descrição para leitor de tela: "Casa 2,4 kW, Solar 3,8 kW…".
    def aria_label = @label || nodes.values.map { |n| [n.label, n.value, n.caption].compact.join(" ") }.join(", ")

    def pos_style(n)
      size = n.r * 2 * 100.0 / W
      format("left: %.3f%%; top: %.3f%%; --d: %.3fcqw; --c: %s", n.x * 100.0 / W, n.y * 100.0 / H, size, n.color)
    end

    # Pontos da ligação: 3 círculos que andam de (x1,y1) até (x2,y2) em dur segundos, defasados.
    def dots(l)
      dx, dy = (l.x2 - l.x1).round(2), (l.y2 - l.y1).round(2)
      safe_join(Array.new(3) do |i|
        tag.circle(cx: l.x1, cy: l.y1, r: 4, class: "ss-flow-dot",
                   style: format("--dx: %spx; --dy: %spx; --dur: %.2fs; animation-delay: %.2fs", dx, dy, l.dur, -l.dur * i / 3.0))
      end)
    end

    # Seta parada no meio, no sentido da energia (sem animação).
    def arrow(l)
      mx, my = (l.x1 + l.x2) / 2.0, (l.y1 + l.y2) / 2.0
      len = Math.hypot(l.x2 - l.x1, l.y2 - l.y1)
      vx, vy = (l.x2 - l.x1) / len, (l.y2 - l.y1) / len
      nx, ny = -vy, vx
      pts = [[mx + vx * 6, my + vy * 6], [mx - vx * 5 + nx * 6, my - vy * 5 + ny * 6], [mx - vx * 5 - nx * 6, my - vy * 5 - ny * 6]]
      tag.polygon(points: pts.map { |p| p.map { |v| v.round(2) }.join(",") }.join(" "), class: "ss-flow-arrow")
    end

    private

    def node(h, x, y, r, slot)
      kind = h[:kind].to_s.to_sym
      kind = :custom unless COLORS.key?(kind)
      color = h[:color].to_s.match?(/\A[#\w\s(),.%-]+\z/) ? h[:color].to_s : COLORS[kind]
      Node.new(id: h[:id].to_s, kind:, label: h[:label], value: h[:value], caption: h[:caption], icon: h[:icon],
               color:, x:, y:, r:, slot:)
    end

    def link(h)
      a, b = nodes[h[:from].to_s], nodes[h[:to].to_s]
      return nil unless a && b

      power = h[:power].to_f
      src, dst = power.negative? ? [b, a] : [a, b]
      len = Math.hypot(dst.x - src.x, dst.y - src.y)
      ux, uy = (dst.x - src.x) / len, (dst.y - src.y) / len
      vel = 0.15 + 0.95 * (power.abs / @max).clamp(0, 1)
      # Saindo para baixo, a linha passaria pelo nome do nó (embaixo do disco): começa depois dele.
      # (O nome do centro é maior em caixa estreita: folga de 20.)
      gap = ->(n) { n.slot == :center ? 20 : 16 }
      ea, eb = (uy > 0.5 ? gap.(src) : 0), (uy < -0.5 ? gap.(dst) : 0)
      Link.new(x1: (src.x + ux * (src.r + 3 + ea)).round(2), y1: (src.y + uy * (src.r + 3 + ea)).round(2),
               x2: (dst.x - ux * (dst.r + 3 + eb)).round(2), y2: (dst.y - uy * (dst.r + 3 + eb)).round(2),
               power:, color: src.color, dur: (1 / vel).round(2))
    end
  end
end
