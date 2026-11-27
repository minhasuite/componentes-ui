import { Controller } from "@hotwired/stimulus"

// Ss::MonthGridComponent (v1.10, par do SsMonthGrid). Um ponto de Tab na grade (roving tabindex): ← → andam um
// dia, ↑ ↓ uma semana, Home/End vão ao começo/fim da semana; o foco não sai do mês (os dias de fora são só
// desenho). Sem url: o dia é botão: choose() marca (aria-pressed), grava no input name: e dispara
// ss-month-grid:select { date }. PageUp/PageDown e arrastar para o lado (≥ SWIPE px) vão ao mês vizinho
// (data-ss-month-grid-prev/next-value, o onMonthChanged do app).
const SWIPE = 48 // px de arrasto horizontal para trocar de mês (o 200 px/s do app, em distância)

export default class extends Controller {
  static targets = ["day", "input"]
  static values = { prev: String, next: String, frame: String }

  connect() {
    this.down = (e) => { if (e.pointerType !== "mouse") this.x0 = e.clientX }
    this.up = (e) => {
      if (this.x0 == null) return
      const dx = e.clientX - this.x0
      this.x0 = null
      if (Math.abs(dx) >= SWIPE) this.go(dx < 0 ? this.nextValue : this.prevValue)
    }
    this.element.addEventListener("pointerdown", this.down)
    this.element.addEventListener("pointerup", this.up)
  }

  disconnect() {
    this.element.removeEventListener("pointerdown", this.down)
    this.element.removeEventListener("pointerup", this.up)
  }

  choose(e) {
    const day = e.currentTarget
    this.dayTargets.forEach((d) => { d.setAttribute("aria-pressed", "false"); d.tabIndex = -1 })
    day.setAttribute("aria-pressed", "true")
    day.tabIndex = 0
    if (this.hasInputTarget) {
      this.inputTarget.value = day.dataset.date
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
    this.dispatch("select", { detail: { date: day.dataset.date } })
  }

  key(e) {
    if (e.key === "PageUp" || e.key === "PageDown") {
      const url = e.key === "PageUp" ? this.prevValue : this.nextValue
      if (url) { e.preventDefault(); this.go(url) }
      return
    }
    const days = this.dayTargets
    const i = days.indexOf(document.activeElement)
    if (i < 0) return
    const wd = new Date(days[i].dataset.date + "T12:00").getDay()
    const step = { ArrowRight: 1, ArrowLeft: -1, ArrowDown: 7, ArrowUp: -7, Home: -wd, End: 6 - wd }[e.key]
    if (step === undefined) return
    e.preventDefault()
    const j = Math.min(days.length - 1, Math.max(0, i + step))
    days.forEach((d) => { d.tabIndex = -1 })
    days[j].tabIndex = 0
    days[j].focus()
  }

  go(url) {
    if (!url) return
    if (window.Turbo) window.Turbo.visit(url, this.frameValue ? { frame: this.frameValue } : {})
    else window.location.href = url
  }
}
