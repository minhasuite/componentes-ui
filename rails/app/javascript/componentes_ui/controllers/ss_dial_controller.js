import { Controller } from "@hotwired/stimulus"
import { ssNumber } from "componentes_ui/controllers/ss_intl"

// Ss::DialComponent (v1.10, par do SsDial). O arco vai de 135° a 405° (0° = direita, horário). Arrastar em volta
// (fora do miolo, como no Flutter: mais que 12% do raio) ou clicar muda; na "boca" de baixo gruda na ponta mais
// perto do valor atual (fractionForAngle do Dart). Setas ±step, PageUp/PageDown ±10%, Home/End nas pontas.
// Mudou: --f no CSS, o número, o aria-valuenow/valuetext, o hidden (input + change) e ss-dial:change { value }.
const START = 135, SWEEP = 270

export function fractionForAngle(deg, current) {
  const rel = (deg - START + 360) % 360
  if (rel <= SWEEP) return rel / SWEEP
  return current > 0.5 ? 1 : 0
}

// Kernel.format mínimo: %d, %i, %.Nf, %f, %s e %%.
export function formatValue(template, v) {
  return template.replace(/%(\.(\d+))?([difs%])/g, (_, _p, n, k) => {
    if (k === "%") return "%"
    if (k === "d" || k === "i") return String(Math.round(v))
    if (k === "f") return Number(v).toFixed(n === undefined ? 6 : Number(n))
    return String(v)
  })
}

export default class extends Controller {
  static targets = ["face", "out", "input"]
  static values = { min: Number, max: { type: Number, default: 100 }, step: { type: Number, default: 1 }, format: String, decimals: Number }

  connect() { this.v = Number(this.faceTarget.getAttribute("aria-valuenow")) }

  get enabled() { return !this.element.classList.contains("is-disabled") }
  get f() { const span = this.maxValue - this.minValue; return span === 0 ? 0 : (this.v - this.minValue) / span }

  text(v) { return this.formatValue ? formatValue(this.formatValue, v) : ssNumber(v, this.decimalsValue) }

  set(raw, commit = true) {
    const s = this.stepValue > 0 ? Math.round(raw / this.stepValue) * this.stepValue : raw
    const v = Math.min(this.maxValue, Math.max(this.minValue, Number(s.toFixed(6))))
    if (v === this.v || !this.enabled) return
    this.v = v
    this.element.style.setProperty("--f", this.f.toFixed(4))
    const t = this.text(v)
    this.outTarget.textContent = t
    this.faceTarget.setAttribute("aria-valuenow", String(v))
    this.faceTarget.setAttribute("aria-valuetext", t)
    if (this.hasInputTarget) {
      this.inputTarget.value = String(v)
      this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
      if (commit) this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
    navigator.vibrate?.(4)
    this.dispatch("change", { detail: { value: v } })
  }

  key(e) {
    if (!this.enabled) return
    const span = this.maxValue - this.minValue
    const d = { ArrowUp: this.stepValue, ArrowRight: this.stepValue, ArrowDown: -this.stepValue, ArrowLeft: -this.stepValue,
                PageUp: span / 10, PageDown: -span / 10 }[e.key]
    if (e.key === "Home") { e.preventDefault(); return this.set(this.minValue) }
    if (e.key === "End") { e.preventDefault(); return this.set(this.maxValue) }
    if (d === undefined) return
    e.preventDefault()
    this.set(this.v + d)
  }

  down(e) {
    if (!this.enabled || e.button > 0) return
    const r = this.faceTarget.getBoundingClientRect()
    const at = (ev) => {
      const dx = ev.clientX - (r.left + r.width / 2), dy = ev.clientY - (r.top + r.height / 2)
      if (Math.hypot(dx, dy) < r.width * 0.12) return
      const deg = ((Math.atan2(dy, dx) * 180) / Math.PI + 360) % 360
      this.set(this.minValue + fractionForAngle(deg, this.f) * (this.maxValue - this.minValue), false)
    }
    e.preventDefault()
    this.faceTarget.focus({ preventScroll: true })
    this.faceTarget.setPointerCapture?.(e.pointerId)
    this.element.setAttribute("data-dragging", "")
    at(e)
    const move = (ev) => at(ev)
    const up = () => {
      this.element.removeAttribute("data-dragging")
      this.faceTarget.removeEventListener("pointermove", move)
      this.faceTarget.removeEventListener("pointerup", up)
      this.faceTarget.removeEventListener("pointercancel", up)
      if (this.hasInputTarget) this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
    this.faceTarget.addEventListener("pointermove", move)
    this.faceTarget.addEventListener("pointerup", up)
    this.faceTarget.addEventListener("pointercancel", up)
  }
}
