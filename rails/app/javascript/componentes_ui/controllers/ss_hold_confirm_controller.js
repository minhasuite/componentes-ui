import { Controller } from "@hotwired/stimulus"

// Ss::HoldToConfirmComponent (v1.9, par do SsHoldToConfirm): segurar enche o fundo (--p 0..1) em duration ms;
// cheio = data-state="done", vibra e envia o formulário em volta (ou dispara "ss-hold-confirm:confirm").
// Soltar antes volta (240 ms × o quanto encheu). Espaço/Enter seguram como o dedo. O clique sem pressão
// antes (leitor de tela) confirma direto. Sem formulário, volta ao começo depois de 1,6 s.
export default class extends Controller {
  static targets = ["name"]
  static values = { duration: { type: Number, default: 1200 }, label: String, doneLabel: String }

  connect() { this.p = 0; this.pressed = false }
  disconnect() { cancelAnimationFrame(this.frame); clearTimeout(this.reset) }

  get idle() { return this.element.dataset.state === "idle" && !this.element.disabled }

  press(e) {
    if (!this.idle || (e && e.button > 0)) return
    this.pressed = true
    navigator.vibrate?.(6)
    this.element.classList.add("is-holding")
    this.animate(1, this.durationValue * (1 - this.p))
  }

  release() {
    if (!this.pressed) return
    this.pressed = false
    this.element.classList.remove("is-holding")
    if (this.element.dataset.state !== "idle") return
    this.animate(0, 240 * this.p + 1)
  }

  key(e) {
    if ((e.key === " " || e.key === "Enter") && !e.repeat) { e.preventDefault(); this.kbd = true; this.press() }
  }

  keyup(e) {
    if (e.key === " " || e.key === "Enter") { e.preventDefault(); this.release() }
  }

  click(e) {
    // Clique que não veio de segurar (leitor de tela): confirma.
    if (this.kbd || e.detail > 0) { this.kbd = false; return }
    if (this.idle) this.done()
  }

  menu(e) { if (e.pointerType !== "mouse") e.preventDefault() } // toque longo não abre o menu do navegador

  animate(to, ms) {
    cancelAnimationFrame(this.frame)
    const from = this.p, t0 = performance.now()
    const step = (now) => {
      const t = Math.min(1, (now - t0) / Math.max(1, ms))
      this.set(from + (to - from) * (to === 0 ? 1 - Math.pow(1 - t, 3) : t))
      if (t < 1) this.frame = requestAnimationFrame(step)
      else if (to === 1) this.done()
    }
    this.frame = requestAnimationFrame(step)
  }

  set(p) {
    this.p = p
    this.element.style.setProperty("--p", p.toFixed(4))
  }

  done() {
    cancelAnimationFrame(this.frame)
    this.set(1)
    this.element.dataset.state = "done"
    this.element.classList.remove("is-holding")
    if (this.hasNameTarget) this.nameTarget.textContent = this.doneLabelValue
    this.element.setAttribute("aria-live", "polite")
    navigator.vibrate?.([10, 40, 10])
    const form = this.element.closest("form.ss-hold-form")
    if (form) form.requestSubmit()
    else this.element.dispatchEvent(new CustomEvent("ss-hold-confirm:confirm", { bubbles: true }))
    this.reset = setTimeout(() => this.restore(), 1600)
  }

  restore() {
    this.element.dataset.state = "idle"
    this.element.removeAttribute("aria-live")
    if (this.hasNameTarget) this.nameTarget.textContent = this.labelValue
    this.set(0)
  }
}
