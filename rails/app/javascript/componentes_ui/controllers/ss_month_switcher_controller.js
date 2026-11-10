import { Controller } from "@hotwired/stimulus"

// Ss::MonthSwitcherComponent (v0.15): guarda o lado da troca no <html> (data-ss-month-dir),
// que sobrevive à visita do Turbo, para o título novo entrar deslizando do lado certo.
// ← → com o foco na peça (fora de campo) seguem a seta.
export default class extends Controller {
  static targets = ["prev", "next"]

  go(event) {
    const dir = event.currentTarget.dataset.ssMonthDir
    if (dir) document.documentElement.dataset.ssMonthDir = dir
  }

  key(event) {
    if (event.altKey || event.ctrlKey || event.metaKey) return
    const link = event.key === "ArrowLeft" ? (this.hasPrevTarget && this.prevTarget) : event.key === "ArrowRight" ? (this.hasNextTarget && this.nextTarget) : null
    if (!link) return
    event.preventDefault()
    link.click()
  }
}
