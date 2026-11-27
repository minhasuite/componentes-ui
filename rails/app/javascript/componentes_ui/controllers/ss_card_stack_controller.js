import { Controller } from "@hotwired/stimulus"

// Ss::CardStackComponent (v1.10, par do SsCardStack). Fechado ↔ aberto pela classe .is-open: o CSS anima o
// top de cada cartão e a altura com a mola (--ss-bounce); clicar no meio inverte do ponto em que está (a
// transição de CSS parte do valor atual). Fechado, os de trás ficam inert (o foco não cai num cartão escondido).
// Evento ss-card-stack:change { open }.
export default class extends Controller {
  static targets = ["card", "toggle", "text"]
  static values = { openLabel: String, closeLabel: String }

  get open() { return this.element.classList.contains("is-open") }

  toggle() {
    const open = !this.open
    this.element.classList.toggle("is-open", open)
    this.cardTargets.forEach((c, i) => { c.inert = !open && i > 0 })
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", String(open))
    if (this.hasTextTarget) this.textTarget.textContent = open ? this.closeLabelValue : this.openLabelValue
    navigator.vibrate?.(8)
    this.dispatch("change", { detail: { open } })
  }
}
