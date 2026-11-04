import { Controller } from "@hotwired/stimulus"
import { reduced } from "componentes_ui/controllers/ss_motion_controller"
import { ssNumber } from "componentes_ui/controllers/ss_intl"

// Termostato (Ss::ThermostatComponent). −/+, setas do teclado e arrasto no anel mudam o alvo na
// hora (número, --f do anel, aria e o hidden) e o form é enviado depois de `debounce` ms parado
// (vários toques = um comando). Trocar o modo envia na hora e recolore o anel (data-mode).
// Sem form em volta, solta o evento ss-thermostat:change (detail.value, detail.mode).
// Enviando (turbo:submit-start/end): aria-busy e a legenda "Enviando…".
export default class extends Controller {
  static targets = ["dial", "value", "input", "minus", "plus", "legend"]
  static values = {
    min: Number, max: Number, step: { type: Number, default: 0.5 },
    debounce: { type: Number, default: 700 }, draggable: { type: Boolean, default: true },
    format: String, offLabel: String, pendingLabel: String,
  }

  connect() {
    this.v = Number(this.inputTarget.value)
    this.form = this.element.tagName === "FORM" ? this.element : this.element.closest("form")
    this.start = () => this.busy(true)
    this.end = () => this.busy(false)
    this.form?.addEventListener("turbo:submit-start", this.start)
    this.form?.addEventListener("turbo:submit-end", this.end)
  }

  disconnect() {
    clearTimeout(this.timer)
    this.form?.removeEventListener("turbo:submit-start", this.start)
    this.form?.removeEventListener("turbo:submit-end", this.end)
  }

  get off() { return this.element.dataset.mode === "off" }
  get enabled() { return !this.off && !this.element.classList.contains("is-disabled") }

  minus() { this.set(this.v - this.stepValue) }
  plus() { this.set(this.v + this.stepValue) }

  key(e) {
    const d = { ArrowUp: 1, ArrowRight: 1, ArrowDown: -1, ArrowLeft: -1, PageUp: 4, PageDown: -4 }[e.key]
    if (e.key === "Home") { e.preventDefault(); return this.set(this.minValue) }
    if (e.key === "End") { e.preventDefault(); return this.set(this.maxValue) }
    if (!d) return
    e.preventDefault()
    this.set(this.v + d * this.stepValue)
  }

  // Arrasto no anel: só a coroa (fora do miolo); na "boca" de baixo gruda na ponta mais perto.
  down(e) {
    if (!this.draggableValue || !this.enabled) return
    const r = this.dialTarget.getBoundingClientRect()
    const at = (ev) => {
      const dx = ev.clientX - (r.left + r.width / 2), dy = ev.clientY - (r.top + r.height / 2)
      return { dist: Math.hypot(dx, dy) / (r.width / 2), deg: ((Math.atan2(dy, dx) * 180) / Math.PI + 360) % 360 }
    }
    if (at(e).dist < 0.6) return
    e.preventDefault()
    this.dialTarget.setPointerCapture?.(e.pointerId)
    this.element.setAttribute("data-dragging", "")
    const move = (ev) => {
      const rel = (at(ev).deg - 135 + 360) % 360
      const f = rel <= 270 ? rel / 270 : (this.frac(this.v) > 0.5 ? 1 : 0)
      this.set(this.minValue + f * (this.maxValue - this.minValue))
    }
    const up = () => {
      this.element.removeAttribute("data-dragging")
      this.dialTarget.removeEventListener("pointermove", move)
      this.dialTarget.removeEventListener("pointerup", up)
      this.dialTarget.removeEventListener("pointercancel", up)
    }
    move(e)
    this.dialTarget.addEventListener("pointermove", move)
    this.dialTarget.addEventListener("pointerup", up)
    this.dialTarget.addEventListener("pointercancel", up)
  }

  mode(e) {
    const m = e.target.value
    this.element.dataset.mode = m
    const tone = e.target.dataset.tone
    if (tone) this.element.style.setProperty("--thermo-c", tone)
    else this.element.style.removeProperty("--thermo-c")
    this.render()
    clearTimeout(this.timer)
    this.send()
  }

  set(raw) {
    if (!this.enabled) return
    const s = this.stepValue || 1
    let n = Math.round((raw - this.minValue) / s) * s + this.minValue
    n = Math.min(this.maxValue, Math.max(this.minValue, Number(n.toFixed(4))))
    if (n === this.v) return
    this.v = n
    this.render()
    if (!reduced()) {
      this.valueTarget.animate([{ scale: 1 }, { scale: 1.08 }, { scale: 1 }], { duration: 260, easing: "ease-out" })
    }
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.send(), this.debounceValue)
  }

  render() {
    const text = this.text(this.v)
    this.inputTarget.value = this.v
    this.valueTarget.textContent = text
    this.element.style.setProperty("--f", this.frac(this.v))
    this.dialTarget.setAttribute("aria-valuenow", this.v)
    this.dialTarget.setAttribute("aria-valuetext", this.off ? this.offLabelValue : text)
    this.dialTarget.tabIndex = this.enabled ? 0 : -1
    this.minusTarget.disabled = !this.enabled || this.v <= this.minValue
    this.plusTarget.disabled = !this.enabled || this.v >= this.maxValue
    if (this.hasLegendTarget && !this.element.hasAttribute("aria-busy")) {
      this.legendTarget.textContent = this.off ? this.offLabelValue : this.legendTarget.dataset.text
    }
  }

  send() {
    if (this.form) this.form.requestSubmit()
    else this.dispatch("change", { detail: { value: this.v, mode: this.element.dataset.mode } })
  }

  busy(on) {
    if (on) {
      this.element.setAttribute("aria-busy", "true")
      if (this.hasLegendTarget) this.legendTarget.textContent = this.pendingLabelValue
    } else {
      this.element.removeAttribute("aria-busy")
      this.render()
    }
  }

  frac(v) { return this.maxValue === this.minValue ? 0 : Math.min(1, Math.max(0, (v - this.minValue) / (this.maxValue - this.minValue))) }

  text(v) {
    if (this.formatValue) return this.formatValue.replace(/%(\.\d+)?[fsd]/, (m, p) => (p ? v.toFixed(Number(p.slice(1))) : String(v)))
    const n = Number.isInteger(v) ? ssNumber(v, 0) : ssNumber(Math.round(v * 10) / 10, 1)
    return `${n}°`
  }
}
