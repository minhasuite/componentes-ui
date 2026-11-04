module Ss
  # Ícones em SVG (linha, currentColor) das peças da casa (v0.10). O app pode passar os dele
  # (icon: "<svg …>"); estes são o padrão. Uso: Ss::CasaIcons.svg(:mic).
  module CasaIcons
    A = 'viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"'.freeze
    PATHS = {
      play: '<path d="M7 4.5v15l12.5-7.5z" fill="currentColor" stroke="none"/>',
      pause: '<rect x="6" y="4.5" width="4" height="15" rx="1.2" fill="currentColor" stroke="none"/><rect x="14" y="4.5" width="4" height="15" rx="1.2" fill="currentColor" stroke="none"/>',
      prev: '<path d="M18 5v14L8 12z" fill="currentColor" stroke="none"/><path d="M6 5v14"/>',
      next: '<path d="M6 5v14l10-7z" fill="currentColor" stroke="none"/><path d="M18 5v14"/>',
      volume: '<path d="M4 9v6h4l5 4V5L8 9z"/><path d="M16.5 8.5a5 5 0 0 1 0 7"/>',
      volume_off: '<path d="M4 9v6h4l5 4V5L8 9z"/><path d="m17 9 5 6m0-6-5 6"/>',
      note: '<path d="M9 18V5l11-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="17" cy="16" r="3"/>',
      speaker: '<rect x="5" y="2.5" width="14" height="19" rx="2.5"/><circle cx="12" cy="14" r="3.5"/><path d="M12 7h.01"/>',
      info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v5m0-8h.01"/>',
      warn: '<path d="M12 3 2 20h20z"/><path d="M12 10v4m0 3h.01"/>',
      critical: '<circle cx="12" cy="12" r="9"/><path d="M12 7v6m0 3.5h.01"/>',
      success: '<circle cx="12" cy="12" r="9"/><path d="m8 12.5 3 3 5-6"/>',
      close: '<path d="M6 6l12 12M18 6 6 18"/>',
      mic: '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3"/>',
      mic_off: '<path d="M9 9v2a3 3 0 0 0 5.1 2.1M15 9.3V6a3 3 0 0 0-5.7-1.3M5 11a7 7 0 0 0 11.4 5.4M19 11a7 7 0 0 1-.6 2.8M12 18v3M3 3l18 18"/>',
      refresh: '<path d="M20 11a8 8 0 1 0-2.3 5.7"/><path d="M20 4v7h-7"/>',
      camera_off: '<path d="M3 3l18 18M10.5 6H14a2 2 0 0 1 2 2v3.5l5-3.5v8M16 16a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2"/>',
      broken: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="m3 15 5-5 4 4m2-2 2-2 5 5"/><path d="M14 4l-2 6 3 2-2 8"/>',
      clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
      home: '<path d="M3 11 12 4l9 7"/><path d="M5 10v10h14V10"/>',
      grid: '<path d="M12 2v4M8 6h8l-2 6h-4z"/><path d="M10 12 7 22m7-10 3 10M8.5 17h7"/>',
      solar: '<rect x="3" y="9" width="18" height="10" rx="1.5"/><path d="M3 14h18M9 9v10M15 9v10M12 2v3M5.6 4.6l1.4 1.4M18.4 4.6 17 6"/>',
      battery: '<rect x="3" y="7" width="16" height="10" rx="2"/><path d="M21 10.5v3M11 9l-2 3h4l-2 3"/>',
      bolt: '<path d="M13 2 4 14h7l-1 8 9-12h-7z"/>',
      up: '<path d="m6 15 6-6 6 6"/>',
      down: '<path d="m6 9 6 6 6-6"/>',
      left: '<path d="m15 6-6 6 6 6"/>',
      right: '<path d="m9 6 6 6-6 6"/>',
      back: '<path d="M19 12H5m6-6-6 6 6 6"/>',
      menu: '<path d="M4 7h16M4 12h16M4 17h16"/>',
      plus: '<path d="M12 5v14M5 12h14"/>',
      minus: '<path d="M5 12h14"/>',
      drop: '<path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z"/>',
      wind: '<path d="M3 8h11a3 3 0 1 0-3-3M3 12h16a3 3 0 1 1-3 3M3 16h8"/>',
      search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
      block: '<circle cx="12" cy="12" r="9"/><path d="m5.6 5.6 12.8 12.8"/>',
      chevron: '<path d="m9 6 6 6-6 6"/>',
      dots: '<circle cx="12" cy="5" r="1.4" fill="currentColor"/><circle cx="12" cy="12" r="1.4" fill="currentColor"/><circle cx="12" cy="19" r="1.4" fill="currentColor"/>',
      copy: '<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/>',
      trash: '<path d="M4 7h16M10 11v6m4-6v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
      arrow_up: '<path d="M12 19V5m-6 6 6-6 6 6"/>',
      arrow_down: '<path d="M12 5v14m-6-6 6 6 6-6"/>',
      puzzle: '<path d="M10 3h4v3a2 2 0 1 0 4 0V3h3v7h-3a2 2 0 1 0 0 4h3v7h-7v-3a2 2 0 1 0-4 0v3H3v-7h3a2 2 0 1 0 0-4H3V3z"/>',
      check: '<path d="M5 13l4 4L19 7"/>',
      power: '<path d="M12 3v9"/><path d="M6.3 6.8a8 8 0 1 0 11.4 0"/>'
    }.freeze

    def self.svg(name, css: nil)
      %(<svg #{A}#{%( class="#{css}") if css}>#{PATHS.fetch(name.to_sym)}</svg>).html_safe
    end
  end
end
