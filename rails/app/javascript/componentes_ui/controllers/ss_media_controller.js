import { Controller } from "@hotwired/stimulus"

// Player de mídia (Ss::MediaPlayerComponent): manda o formulário do slider ao soltar, pinta a
// trilha enquanto arrasta e, tocando, faz o tempo andar de segundo em segundo até o próximo
// render do app (Turbo Stream com a posição real).
export default class extends Controller {
  static targets = ["now", "bar", "range"]
  static values = { playing: Boolean, position: Number, duration: Number }

  connect() {
    if (this.playingValue && this.durationValue) {
      this.timer = setInterval(() => {
        if (this.positionValue < this.durationValue) this.positionValue += 1
      }, 1000)
    }
  }

  disconnect() { clearInterval(this.timer) }

  positionValueChanged() {
    if (!this.durationValue) return
    const p = Math.min(this.positionValue, this.durationValue)
    const pct = `${(p * 100) / this.durationValue}%`
    if (this.hasNowTarget) this.nowTarget.textContent = this.fmt(p)
    if (this.hasBarTarget) this.barTarget.style.width = pct
    if (this.hasRangeTarget && document.activeElement !== this.rangeTarget) {
      this.rangeTarget.value = p
      this.rangeTarget.style.setProperty("--pct", pct)
    }
  }

  paint(e) {
    const r = e.target
    r.style.setProperty("--pct", `${((r.value - r.min) * 100) / (r.max - r.min)}%`)
  }

  submit(e) {
    this.paint(e)
    e.target.form?.requestSubmit()
  }

  fmt(sec) {
    const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), s = Math.floor(sec % 60)
    const p = (n) => String(n).padStart(2, "0")
    return h ? `${h}:${p(m)}:${p(s)}` : `${m}:${p(s)}`
  }
}
