import { Controller } from "@hotwired/stimulus"

// Contagem regressiva até uma hora (Pix): mm:ss no relógio; ao zerar, põe
// data-expired no elemento (o CSS troca o texto).
export default class extends Controller {
  static targets = ["clock"]
  static values = { until: String }

  connect() {
    this.end = Date.parse(this.untilValue)
    this.render()
    this.timer = setInterval(() => this.render(), 1000)
  }

  disconnect() { clearInterval(this.timer) }

  render() {
    const left = Math.max(0, Math.round((this.end - Date.now()) / 1000))
    const h = Math.floor(left / 3600)
    const m = Math.floor((left % 3600) / 60)
    const s = left % 60
    const pad = (n) => String(n).padStart(2, "0")
    if (this.hasClockTarget) this.clockTarget.textContent = h ? `${h}:${pad(m)}:${pad(s)}` : `${pad(m)}:${pad(s)}`
    this.element.toggleAttribute("data-expired", left === 0)
    if (left === 0) clearInterval(this.timer)
  }
}
