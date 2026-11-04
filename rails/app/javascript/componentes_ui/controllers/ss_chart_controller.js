import { Controller } from "@hotwired/stimulus"
import { inView } from "componentes_ui/controllers/ss_in_view_controller"

// Gráfico de área (Ss::AreaChartComponent): linha vertical, marcador e pílula seguem
// o mouse/dedo; ← → (e Home/End) andam pelos pontos com o foco no gráfico.
// Entrada ao aparecer (inView): a linha se desenha, a área sobe e o ponto pula.
export default class extends Controller {
  static targets = ["plot", "cursor", "dot", "pill", "label", "live"]
  static values = { points: Array, index: Number, w: Number, h: Number }

  connect() { this.stop = inView(this.element) }
  disconnect() { this.stop?.() }

  move(event) {
    const svg = this.plotTarget.querySelector("svg")
    const rect = svg.getBoundingClientRect()
    if (!rect.width) return
    const x = ((event.clientX - rect.left) / rect.width) * this.wValue
    let best = 0
    this.pointsValue.forEach((p, i) => { if (Math.abs(p[0] - x) < Math.abs(this.pointsValue[best][0] - x)) best = i })
    this.select(best, false)
  }

  key(event) {
    const last = this.pointsValue.length - 1
    const map = { ArrowRight: this.indexValue + 1, ArrowLeft: this.indexValue - 1, Home: 0, End: last }
    if (!(event.key in map)) return
    event.preventDefault()
    this.select(Math.max(0, Math.min(last, map[event.key])), true)
  }

  select(i, announce) {
    if (i === this.indexValue && !announce) return
    this.indexValue = i
    const [x, y, label, text] = this.pointsValue[i]
    this.cursorTarget.setAttribute("x1", x)
    this.cursorTarget.setAttribute("x2", x)
    this.dotTarget.setAttribute("cx", x)
    this.dotTarget.setAttribute("cy", y)
    this.pillTarget.style.left = `${(x / this.wValue) * 100}%`
    this.pillTarget.style.top = `${(y / this.hValue) * 100}%`
    this.pillTarget.textContent = text
    this.labelTargets.forEach((t, j) => t.classList.toggle("is-active", j === i))
    if (announce && this.hasLiveTarget) this.liveTarget.textContent = `${label}: ${text}`
  }
}
