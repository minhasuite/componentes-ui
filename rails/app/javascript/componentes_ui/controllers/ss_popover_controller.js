import { Controller } from "@hotwired/stimulus"

// Popover (Ss::PopoverComponent, Ss::WhatsNewComponent): sem CSS anchor positioning,
// posiciona o painel junto do botão ao abrir (abaixo; vira para cima se faltar espaço).
// O painel "nasce" do botão com mola (CSS); aqui só acertamos o transform-origin
// para o lado do botão quando ele vira para cima.
export default class extends Controller {
  static targets = ["trigger", "panel"]

  place(event) {
    if (event.newState !== "open" || CSS.supports("anchor-name: --a")) return
    const panel = this.panelTarget
    const r = this.triggerTarget.getBoundingClientRect()
    const end = (panel.dataset.placement || "").endsWith("end")
    panel.style.position = "fixed"
    panel.style.margin = "0"
    const pw = panel.offsetWidth
    const ph = panel.offsetHeight
    let top = r.bottom + 8
    const up = top + ph > innerHeight - 8 && r.top - ph - 8 > 8
    if (up) top = r.top - ph - 8
    let left = end ? r.right - pw : r.left
    left = Math.max(8, Math.min(left, innerWidth - pw - 8))
    panel.style.top = `${top}px`
    panel.style.left = `${left}px`
    panel.style.transformOrigin = `${end ? "right" : "left"} ${up ? "bottom" : "top"}`
  }
}
