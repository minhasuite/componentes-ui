import { Controller } from "@hotwired/stimulus"

// Tile de câmera (Ss::CameraTileComponent): a idade do quadro parado anda de segundo em segundo
// ("há 12 s" → "há 1 min") e o "Tentar de novo" sem URL vira o evento ss-camera:retry.
// O app troca o estado com el.dataset.state = "live" | "stale" | "error" | "offline" | "loading"
// e avisa de um quadro novo zerando data-ss-camera-age-value.
export default class extends Controller {
  static targets = ["age"]
  static values = { age: Number, labels: Object }

  connect() {
    if (this.hasAgeValue) this.timer = setInterval(() => { this.ageValue += 1 }, 1000)
  }

  disconnect() { clearInterval(this.timer) }

  ageValueChanged() {
    if (!this.hasAgeTarget) return
    const s = Math.max(0, Math.floor(this.ageValue))
    const [key, n] = s < 60 ? ["age_s", s] : s < 3600 ? ["age_min", Math.floor(s / 60)]
      : s < 86400 ? ["age_h", Math.floor(s / 3600)] : ["age_d", Math.floor(s / 86400)]
    const tpl = this.labelsValue[key]
    if (tpl) this.ageTarget.textContent = tpl.replace("{n}", n)
  }

  retry() { this.dispatch("retry", { prefix: "ss-camera" }) }

  setState(state) { this.element.dataset.state = state }
}
