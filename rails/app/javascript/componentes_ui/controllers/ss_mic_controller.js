import { Controller } from "@hotwired/stimulus"

// Microfone com nível (Ss::MicButtonComponent). O app manda o nível do áudio (0..1) por
// setLevel(v) ou pelo evento "ss-mic:level" (detail: número) e troca o estado por setState(s)
// ou data-ss-mic-state-value. O toque dispara "ss-mic:press" com o estado atual.
// O nível chega aos saltos: a transição do CSS (--level) suaviza.
export default class extends Controller {
  static targets = ["button"]
  static values = { state: { type: String, default: "idle" }, labels: Object }

  connect() {
    this.onLevel = (e) => this.setLevel(Number(e.detail?.level ?? e.detail))
    this.element.addEventListener("ss-mic:level", this.onLevel)
  }

  disconnect() { this.element.removeEventListener("ss-mic:level", this.onLevel) }

  setLevel(v) {
    const level = Math.min(1, Math.max(0, Number(v) || 0))
    this.element.style.setProperty("--level", level.toFixed(3))
  }

  setState(state) { this.stateValue = state }

  stateValueChanged(state) {
    this.element.dataset.state = state
    if (state !== "listening") this.setLevel(0)
    const label = this.labelsValue[state]
    if (label && this.hasButtonTarget) this.buttonTarget.setAttribute("aria-label", label)
  }

  press() { this.dispatch("press", { prefix: "ss-mic", detail: { state: this.stateValue } }) }
}
