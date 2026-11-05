import { Controller } from "@hotwired/stimulus"

// Microfone com nível (Ss::MicButtonComponent). O app manda o nível do áudio (0..1) por
// setLevel(v) ou pelo evento "ss-mic:level" (detail: número) e troca o estado por setState(s)
// ou data-ss-mic-state-value. O toque dispara "ss-mic:press" com o estado atual.
// O nível chega aos saltos: a transição do CSS (--level) suaviza.
//
// Segurar para falar (hold: true, v0.10.3): pointerdown → "ss-mic:hold-start", pointerup →
// "ss-mic:hold-end", arrastar além de 80 px ou pointercancel → "ss-mic:hold-cancel". Espaço e
// Enter seguram pelo teclado; o clique sem ponteiro (leitor de tela) alterna começar/terminar.
// Enquanto segura, o elemento ganha data-holding (o CSS cresce o botão).
const CANCEL_DISTANCE = 80

export default class extends Controller {
  static targets = ["button"]
  static values = { state: { type: String, default: "idle" }, labels: Object }

  connect() {
    this.holding = false
    this.onLevel = (e) => this.setLevel(Number(e.detail?.level ?? e.detail))
    this.element.addEventListener("ss-mic:level", this.onLevel)
  }

  disconnect() {
    this.element.removeEventListener("ss-mic:level", this.onLevel)
    if (this.holding) this.finish("hold-cancel")
  }

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

  // ── segurar para falar ──
  get disabled() { return this.hasButtonTarget && this.buttonTarget.disabled }

  begin() {
    if (this.holding || this.disabled) return
    this.holding = true
    this.element.dataset.holding = ""
    navigator.vibrate?.(10)
    this.dispatch("hold-start", { prefix: "ss-mic", detail: { state: this.stateValue } })
  }

  finish(name = "hold-end") {
    if (!this.holding) return
    this.holding = false
    delete this.element.dataset.holding
    this.dispatch(name, { prefix: "ss-mic", detail: { state: this.stateValue } })
  }

  holdStart(e) {
    if (e.button > 0) return
    e.preventDefault()
    this.origin = { x: e.clientX, y: e.clientY }
    this.pointer = true
    e.currentTarget.setPointerCapture?.(e.pointerId)
    this.begin()
  }

  holdMove(e) {
    if (!this.holding || !this.origin) return
    if (Math.hypot(e.clientX - this.origin.x, e.clientY - this.origin.y) > CANCEL_DISTANCE) this.finish("hold-cancel")
  }

  holdEnd() { this.origin = null; this.finish() }

  holdCancel() { this.origin = null; this.finish("hold-cancel") }

  holdKey(e) {
    if (e.key !== " " && e.key !== "Enter") return
    e.preventDefault()
    this.keyed = true
    if (e.type === "keydown") { if (!e.repeat) this.begin(); return }
    this.finish()
    setTimeout(() => { this.keyed = false })
  }

  // Clique depois do ponteiro ou da tecla: já tratado. Sem ponteiro (detail 0: leitor de tela): alterna.
  holdClick(e) {
    e.preventDefault()
    if (this.pointer || this.keyed || e.detail > 0) { this.pointer = this.keyed = false; return }
    this.holding ? this.finish() : this.begin()
  }

  noMenu(e) { e.preventDefault() }
}
