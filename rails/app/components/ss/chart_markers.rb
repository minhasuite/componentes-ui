module Ss
  # v0.27: marcas verticais (anotações) dos gráficos por categoria (BarChartComponent e LineChartComponent,
  # par do SsChartMarker do Flutter). Cada marca cai no rótulo do eixo X que ela nomeia:
  #
  #   markers: [{ at: "12/11", label: "v2.3.1", kind: :deploy },
  #             { at: "14/11", label: "API fora do ar", kind: :incident },
  #             { at: "14/11", label: "migração", kind: :note }]
  #
  # Traço tracejado de cima a baixo e o rótulo no topo; deploy na cor de informação, incidente na de perigo,
  # nota na apagada (kind desconhecido = nota). Duas marcas no mesmo rótulo empilham o texto (a área de cima
  # cresce para caber). Marca com at: que não está nos rótulos não aparece. Entram na tabela do leitor de tela.
  module ChartMarkers
    MARKER_KINDS = { deploy: "var(--ss-info)", incident: "var(--danger)", note: "var(--muted)" }.freeze
    MARKER_LINE = 13.0

    def init_markers(markers)
      @markers = Array(markers).filter_map do |m|
        m = m.to_h.transform_keys(&:to_sym)
        i = labels.index(m[:at].to_s)
        next if i.nil?

        kind = MARKER_KINDS.key?(m[:kind]&.to_sym) ? m[:kind].to_sym : :note
        { index: i, label: m[:label].to_s, kind:, color: MARKER_KINDS[kind] }
      end
      per = Hash.new(0)
      @markers.each { |m| m[:row] = (per[m[:index]] += 1) }
    end

    def markers = @markers || []
    def markers? = markers.any?

    # Quantas linhas de rótulo empilhadas no rótulo mais cheio (0 sem marcas).
    def marker_rows = markers.map { _1[:row] }.max.to_i

    # Espaço extra no alto para os rótulos das marcas.
    def marker_pad = marker_rows * MARKER_LINE

    # Rótulo da marca no alto (a classe hospedeira dá marker_x(m) e w). Perto da borda direita, alinha pelo fim.
    def marker_text_y(m) = (11 + MARKER_LINE * (m[:row] - 1)).round(2)
    def marker_anchor(m) = marker_x(m) > w - 90 ? "end" : "start"
    def marker_text_x(m) = marker_anchor(m) == "end" ? marker_x(m) - 4 : marker_x(m) + 4

    def marker_kind_label(kind) = ss_t("chart.marker.#{kind}", default: { deploy: "implantação", incident: "incidente", note: "nota" }[kind])

    # O SVG das marcas (traço de top a bottom e o rótulo no alto), para o desenho do gráfico.
    def markers_svg(top:, bottom:)
      markers.map do |m|
        x = marker_x(m)
        h = ERB::Util.h(m[:label])
        line = m[:row] == 1 ? %(<line class="ss-chart-mark-line" x1="#{x}" x2="#{x}" y1="#{top}" y2="#{bottom}" style="stroke:#{m[:color]}"/>) : ""
        %(<g class="ss-chart-mark" data-kind="#{m[:kind]}">#{line}<text class="ss-chart-mark-text" x="#{marker_text_x(m)}" y="#{marker_text_y(m)}" text-anchor="#{marker_anchor(m)}" style="fill:#{m[:color]}">#{h}</text></g>)
      end.join.html_safe
    end

    # O texto da célula "Marcas" da linha i na tabela do leitor de tela.
    def markers_at(i) = markers.select { _1[:index] == i }.map { "#{_1[:label]} (#{marker_kind_label(_1[:kind])})" }.join("; ")
  end
end
