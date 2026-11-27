import { Controller } from "@hotwired/stimulus"

// v1.14.0 · Ss::PeriodCompareComponent (par do SsPeriodCompare): a troca de período animada. Ao sair (o
// turbo-frame ou a página trocam), guarda o desenho das linhas e o total; o novo, ao conectar com o mesmo id,
// começa do desenho antigo e desliza para o novo (a transição de `d` da v1.9) e o total rola no odômetro.
// Reduzir movimento: troca direto.
const snapshots = new Map()
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

export default class extends Controller {
  static targets = ["total"]

  connect() {
    const snap = snapshots.get(this.element.id)
    snapshots.delete(this.element.id)
    if (!snap || Date.now() - snap.at > 4000 || reduced()) return
    const lines = [...this.element.querySelectorAll(".ss-linec-line")]
    if (lines.length !== snap.lines.length) return
    this.element.classList.add("is-swapping")
    const next = lines.map((l) => l.getAttribute("d"))
    lines.forEach((l, i) => l.setAttribute("d", snap.lines[i]))
    if (this.hasTotalTarget && snap.total) {
      const to = this.totalTarget.getAttribute("data-ss-odometer-text-value")
      this.totalTarget.setAttribute("data-ss-odometer-text-value", snap.total)
      requestAnimationFrame(() => this.totalTarget.setAttribute("data-ss-odometer-text-value", to))
    }
    requestAnimationFrame(() => requestAnimationFrame(() => {
      lines.forEach((l, i) => l.setAttribute("d", next[i]))
      this.timer = setTimeout(() => this.element.classList.remove("is-swapping"), 700)
    }))
  }

  disconnect() {
    clearTimeout(this.timer)
    if (!this.element.id) return
    snapshots.set(this.element.id, {
      at: Date.now(),
      lines: [...this.element.querySelectorAll(".ss-linec-line")].map((l) => l.getAttribute("d")),
      total: this.hasTotalTarget ? this.totalTarget.getAttribute("data-ss-odometer-text-value") : null
    })
  }
}
