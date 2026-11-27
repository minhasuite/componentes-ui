import { Controller } from "@hotwired/stimulus"

// Ss::DuoStatComponent (v1.10, par do SsDuoStat). Os lados são botões (aria-pressed) ou links (aria-current):
// no botão, troca aqui (--x move a pílula com a mola; .is-on vira o texto claro); no link, a página navega e o
// controller só antecipa a troca. ss-duo:change { index }; o hidden (name:) recebe o índice.
export default class extends Controller {
  static targets = ["side", "input"]
  static values = { index: Number }

  pick(e) {
    const i = Number(e.currentTarget.dataset.index)
    if (i === this.indexValue) { if (e.currentTarget.tagName === "A") e.preventDefault(); return }
    this.indexValue = i
    this.element.style.setProperty("--x", i)
    this.sideTargets.forEach((s, k) => {
      s.classList.toggle("is-on", k === i)
      if (s.tagName === "BUTTON") s.setAttribute("aria-pressed", String(k === i))
      else if (k === i) s.setAttribute("aria-current", "true")
      else s.removeAttribute("aria-current")
    })
    if (this.hasInputTarget) {
      this.inputTarget.value = String(i)
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
    navigator.vibrate?.(8)
    this.dispatch("change", { detail: { index: i } })
  }
}
