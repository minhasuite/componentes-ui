import { Controller } from "@hotwired/stimulus"

// Ss::FloatingBarsComponent (v1.10, par do SsFloatingBars). Clicar numa barra a escolhe (.is-on: cheia e com a
// etiqueta do valor; aria-pressed nos botões, aria-current nos links). ss-floating-bars:change { index }.
// A subida em cascata é CSS (ss-in-view marca data-in-view).
export default class extends Controller {
  static targets = ["bar"]

  pick(e) {
    const i = Number(e.currentTarget.dataset.index)
    const was = this.barTargets.findIndex((b) => b.classList.contains("is-on"))
    if (i === was) { if (e.currentTarget.tagName === "A") e.preventDefault(); return }
    this.barTargets.forEach((b, k) => {
      b.classList.toggle("is-on", k === i)
      if (b.tagName === "BUTTON") b.setAttribute("aria-pressed", String(k === i))
      else if (k === i) b.setAttribute("aria-current", "true")
      else b.removeAttribute("aria-current")
    })
    navigator.vibrate?.(8)
    this.dispatch("change", { detail: { index: i } })
  }
}
