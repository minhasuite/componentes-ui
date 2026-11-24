import { Controller } from "@hotwired/stimulus"

// Ss::SwipeToConfirmComponent (v1.9, par do SsSwipeToConfirm): arrastar a bolinha até o fim confirma.
// data-state: idle | loading | done; --p (0..1) é a posição da bolinha. Passou de 85% ao soltar: gruda no fim,
// envia o formulário (requestSubmit) e espera o turbo:submit-end (sucesso = done; falha = volta).
// Sem formulário: evento "ss-swipe-confirm:confirm" (cancelável, detail: { done(), fail() }).
// Clique de teclado ou do leitor de tela (event.detail === 0) confirma direto; clique de mouse sem arrastar só
// dá uma cutucada (a bolinha anda um pouco e volta) para mostrar que é de arrastar.
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches
const ARM = 0.85

export default class extends Controller {
  static targets = ["track", "thumb", "status"]
  static values = { label: String, doneLabel: String, loading: String }

  connect() {
    this.form = this.element.tagName === "FORM" ? this.element : null
    this.onEnd = (e) => { if (this.element.dataset.state === "loading") e.detail?.success ? this.finish() : this.back(true) }
    this.form?.addEventListener("turbo:submit-end", this.onEnd)
    this.set(this.element.dataset.state === "done" ? 1 : 0)
  }

  disconnect() {
    this.form?.removeEventListener("turbo:submit-end", this.onEnd)
    this.stopDrag?.()
  }

  get course() { return Math.max(1, this.trackTarget.clientWidth - this.thumbTarget.offsetWidth) }

  set(p) {
    this.p = Math.min(1, Math.max(0, p))
    this.element.style.setProperty("--p", this.p.toFixed(4))
  }

  down(e) {
    if (this.element.dataset.state !== "idle" || this.thumbTarget.disabled || e.button > 0) return
    e.preventDefault()
    this.thumbTarget.setPointerCapture?.(e.pointerId)
    this.element.classList.remove("is-settling")
    const x0 = e.clientX, p0 = this.p
    this.moved = false
    const move = (ev) => {
      const dx = ev.clientX - x0
      if (Math.abs(dx) > 3) this.moved = true
      this.set(p0 + dx / this.course)
      const armed = this.p > ARM
      if (armed !== this.element.classList.contains("is-armed")) {
        this.element.classList.toggle("is-armed", armed)
        if (armed) navigator.vibrate?.(8)
      }
    }
    const up = () => {
      this.stopDrag()
      if (this.p > ARM) this.confirm()
      else if (this.moved) this.back()
    }
    this.stopDrag = () => {
      this.thumbTarget.removeEventListener("pointermove", move)
      this.thumbTarget.removeEventListener("pointerup", up)
      this.thumbTarget.removeEventListener("pointercancel", up)
      this.stopDrag = null
    }
    this.thumbTarget.addEventListener("pointermove", move)
    this.thumbTarget.addEventListener("pointerup", up)
    this.thumbTarget.addEventListener("pointercancel", up)
  }

  click(e) {
    if (this.element.dataset.state !== "idle") return
    if (e.detail === 0) return this.confirm() // teclado ou leitor de tela
    if (this.moved) { this.moved = false; return }
    if (reduced()) return
    // Cutucada: mostra que é de arrastar.
    this.element.classList.add("is-settling")
    this.set(0.18)
    setTimeout(() => this.back(), 220)
  }

  confirm() {
    if (this.element.dataset.state !== "idle") return
    this.element.classList.add("is-settling")
    this.element.classList.remove("is-armed")
    this.set(1)
    this.element.dataset.state = "loading"
    this.element.setAttribute("aria-busy", "true")
    this.say(this.loadingValue)
    if (this.form) return this.form.requestSubmit()
    const ev = new CustomEvent("ss-swipe-confirm:confirm", { bubbles: true, cancelable: true,
      detail: { done: () => this.finish(), fail: () => this.back(true) } })
    if (this.element.dispatchEvent(ev)) this.finish()
  }

  finish() {
    this.element.dataset.state = "done"
    this.element.removeAttribute("aria-busy")
    this.thumbTarget.setAttribute("aria-label", this.doneLabelValue)
    this.thumbTarget.removeAttribute("aria-describedby")
    this.set(1)
    navigator.vibrate?.([10, 40, 10])
    this.say(this.doneLabelValue)
  }

  back(error = false) {
    this.element.dataset.state = "idle"
    this.element.removeAttribute("aria-busy")
    this.element.classList.remove("is-armed")
    this.element.classList.toggle("is-settling", !reduced())
    this.set(0)
    if (error) { navigator.vibrate?.(30); this.say(this.labelValue) }
  }

  say(text) { if (this.hasStatusTarget) this.statusTarget.textContent = text || "" }
}
