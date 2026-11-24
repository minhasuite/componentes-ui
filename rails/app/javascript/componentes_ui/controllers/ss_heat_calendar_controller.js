import { Controller } from "@hotwired/stimulus"

// Ss::HeatCalendarComponent (v1.9, par do SsHeatCalendar): o dia clicado ou focado fica aria-pressed e o texto
// dele (o aria-label: "12/11/2026: 3") vai para a linha de baixo. Um ponto de tab só (tabindex móvel):
// ↑ ↓ um dia, ← → uma semana, Home/End o primeiro e o último dia. Clicar de novo no escolhido limpa.
export default class extends Controller {
  static targets = ["day", "out"]

  pick(e) {
    const day = e.currentTarget
    const again = e.type === "click" && day.getAttribute("aria-pressed") === "true"
    this.dayTargets.forEach((d) => { d.setAttribute("aria-pressed", "false"); d.tabIndex = -1 })
    day.tabIndex = 0
    if (again) { this.outTarget.textContent = ""; return }
    day.setAttribute("aria-pressed", "true")
    this.outTarget.textContent = day.getAttribute("aria-label")
  }

  key(e) {
    const days = this.dayTargets
    const i = days.indexOf(e.currentTarget)
    const step = { ArrowUp: -1, ArrowDown: 1, ArrowLeft: -7, ArrowRight: 7 }[e.key]
    let j = null
    if (step) {
      const target = new Date(`${e.currentTarget.dataset.date}T12:00:00`)
      target.setDate(target.getDate() + step)
      const iso = target.toISOString().slice(0, 10)
      j = days.findIndex((d) => d.dataset.date === iso)
    } else if (e.key === "Home") j = 0
    else if (e.key === "End") j = days.length - 1
    if (j === null) return
    e.preventDefault()
    if (j >= 0 && j !== i) days[j].focus()
  }
}
