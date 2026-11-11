# Gera as <section> do catálogo (rails/catalogo/index.html) para as peças da v0.21.
#   bin/rails runner script/catalogo_v021.rb > /tmp/v021.html
include ComponentesUi::Helpers
require "action_dispatch/testing/test_request"
CTRL = ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create("PATH_INFO" => "/vitrine/x"); c.response = ActionDispatch::Response.new }
def view = (@view ||= CTRL.view_context)
def r(c, &blk) = view.render(c, &blk).to_s.gsub(/<!-- (BEGIN|END) [^>]*-->/, "").gsub(/\n\s*/, "")
def esc(s) = ERB::Util.h(s)
def section(slug, nome, desc, comps, estados)
  out = +%(<section data-comp="#{slug}" data-nome="#{esc(nome)}" data-descricao="#{esc(desc)}"\n  data-comportamentos='#{esc(comps.to_json)}'>\n)
  estados.each { |(s, t, html)| out << %(  <div data-estado="#{s}" data-titulo="#{esc(t)}">#{html}</div>\n) }
  out << "</section>\n"
end
bulb = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9c.6.4 1 1.1 1 1.8V16h5v-.3c0-.7.4-1.4 1-1.8A6 6 0 0 0 12 3z"/></svg>'
out = +""
tiles = r(Ss::DeviceTileComponent.new(name: "Abajur", state: "Ligado · 15%", on: true, tone: "#ffaa5a", level: 0.15, icon: bulb, url: "#")) +
        r(Ss::DeviceTileComponent.new(name: "Fita de LED", state: "Ligada · 100%", on: true, tone: "#5078ff", level: 1, icon: bulb, url: "#"))
out << section("ss-device-level-v21", "Ss::DeviceTileComponent(level:)", "Brilho real da lâmpada no tile (v0.21, par do SsDeviceTile(level:)).",
  ["level: 0..1 (o dimmer); ligado, tinta, borda e halo vão de 35% a 100% (.has-level, --ss-level).", "Com tone: na cor real da lâmpada; sem level, igual a antes."],
  [["brilho", "15% e 100% na cor da lâmpada", %(<div style="display:grid;gap:12px;width:360px">#{tiles}</div>)]])
cue = %w[on open arrive].map do |k|
  view.tag.div(class: "ss-cue is-cueing", style: "--tone: var(--warn)", data: ss_cue_data(kind: k, active: true, key: "cat-#{k}")) { %(<span class="ss-icon-tile">#{ss_icon("light-bulb")}</span>).html_safe }
end.join
out << section("ss-cue", ".ss-cue + ss-cue", "Micro-animação de mudança de estado da casa (v0.21, par do SsCue): ligou, abriu, chegou.",
  ["Toca uma vez (620 ms) quando active vira verdadeiro; nada na primeira pintura nem ao desligar.", "on: pulo .94 → 1 pela mola e halo na cor (--tone); open: gira ~28° pela borda esquerda; arrive: sobe 8 px com a mola.",
   "key: guarda o estado entre trocas do HTML (Turbo Frame/Stream).", "prefers-reduced-motion desliga."],
  [["acenos", "ligou · abriu · chegou (no meio)", %(<div style="display:flex;gap:16px">#{cue}</div>)]])
print out
