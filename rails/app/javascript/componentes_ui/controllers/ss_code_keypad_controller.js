import { Controller } from "@hotwired/stimulus"
import { reduced } from "componentes_ui/controllers/ss_motion_controller"

// Teclado de código (Ss::CodeKeypadComponent). Teclas na tela e no teclado físico (números,
// Backspace, Enter); com length, envia ao completar. Estados em data-state: idle | busy |
// error | success. Enviando pelo Turbo: busy (teclas travadas); falhou: error (treme e limpa).
// Veio do servidor com error: treme e limpa ao conectar. Evento ss-code-keypad:error também
// dispara o erro (ex.: resposta por turbo stream que não troca o bloco); ss-code-keypad:reset
// limpa e destrava.
export default class extends Controller {
  static targets = ["dots", "msg", "input", "key", "back", "submit"]
  static values = { length: Number, max: { type: Number, default: 8 }, obscure: { type: Boolean, default: true }, errorText: String, successText: String }

  connect() {
    this.code = ""
    this.form = this.element.tagName === "FORM" ? this.element : this.element.closest("form")
    this.start = () => this.setState("busy")
    this.end = (e) => (e.detail?.success === false ? this.error() : this.setState("success"))
    this.onError = () => this.error()
    this.onReset = () => this.reset()
    this.form?.addEventListener("turbo:submit-start", this.start)
    this.form?.addEventListener("turbo:submit-end", this.end)
    this.element.addEventListener("ss-code-keypad:error", this.onError)
    this.element.addEventListener("ss-code-keypad:reset", this.onReset)
    this.render()
    if (this.element.dataset.state === "error") this.error(false)
  }

  disconnect() {
    clearTimeout(this.clearTimer)
    this.form?.removeEventListener("turbo:submit-start", this.start)
    this.form?.removeEventListener("turbo:submit-end", this.end)
    this.element.removeEventListener("ss-code-keypad:error", this.onError)
    this.element.removeEventListener("ss-code-keypad:reset", this.onReset)
  }

  reset() {
    clearTimeout(this.clearTimer)
    this.code = ""
    this.setState("idle")
  }

  get locked() { return ["busy", "success"].includes(this.element.dataset.state) }

  press(e) { this.type(e.currentTarget.dataset.digit) }

  back() {
    if (this.locked || !this.code) return
    this.code = this.code.slice(0, -1)
    this.render()
  }

  key(e) {
    if (e.target.closest("button[type=submit]") && e.key === "Enter") return
    if (/^\d$/.test(e.key)) {
      e.preventDefault()
      this.type(e.key)
      const b = this.keyTargets.find((k) => k.dataset.digit === e.key)
      if (b) { b.setAttribute("data-pressed", ""); setTimeout(() => b.removeAttribute("data-pressed"), 120) }
    } else if (e.key === "Backspace") {
      e.preventDefault()
      this.back()
    } else if (e.key === "Enter") {
      e.preventDefault()
      if (this.code && !this.locked) this.submit()
    }
  }

  type(d) {
    if (this.locked || this.code.length >= this.maxValue) return
    if (this.element.dataset.state === "error") this.setState("idle")
    this.code += d
    this.render(true)
    if (this.lengthValue && this.code.length === this.lengthValue) this.submit()
  }

  submit() {
    const btn = this.hasSubmitTarget ? this.submitTargets[0] : null
    if (this.form) this.form.requestSubmit(this.lengthValue ? null : btn)
    else this.dispatch("submit", { detail: { code: this.code } })
  }

  // Erro: bolinhas vermelhas, treme e limpa (com menos movimento, só limpa).
  error(withText = true) {
    this.setState("error")
    if (withText || !this.msgTarget.textContent.trim()) this.msgTarget.textContent = this.errorTextValue
    if (!reduced()) {
      this.element.removeAttribute("data-shake")
      void this.element.offsetWidth
      this.element.setAttribute("data-shake", "")
    }
    clearTimeout(this.clearTimer)
    this.clearTimer = setTimeout(() => {
      this.element.removeAttribute("data-shake")
      this.code = ""
      this.render()
    }, 650)
  }

  setState(s) {
    this.element.dataset.state = s
    if (s === "busy") this.element.setAttribute("aria-busy", "true")
    else this.element.removeAttribute("aria-busy")
    if (s === "success") this.msgTarget.textContent = this.successTextValue
    if (s === "idle" || s === "busy") this.msgTarget.textContent = ""
    this.render()
  }

  render(pop = false) {
    const n = this.code.length
    this.inputTarget.value = this.code
    const total = this.lengthValue || Math.max(4, n)
    const dots = this.dotsTarget
    while (dots.children.length < total) dots.appendChild(document.createElement("i"))
    while (dots.children.length > total) dots.lastElementChild.remove()
    ;[...dots.children].forEach((el, i) => {
      const on = i < n
      if (!this.obscureValue && on) {
        if (el.tagName !== "B") { const b = document.createElement("b"); dots.replaceChild(b, el); el = b }
        el.textContent = this.code[i]
      } else if (el.tagName !== "I") {
        const dot = document.createElement("i"); dots.replaceChild(dot, el); el = dot
      }
      el.classList.toggle("is-on", on)
    })
    dots.setAttribute("aria-valuetext", n)
    dots.title = (dots.dataset.countLabel || "%{n}").replace("%{n}", n)
    const locked = this.locked
    this.keyTargets.forEach((k) => (k.disabled = locked || n >= this.maxValue))
    if (this.hasBackTarget) this.backTarget.disabled = locked || n === 0
    this.submitTargets.forEach((b) => (b.disabled = locked || n === 0))
    if (pop && !reduced()) dots.children[n - 1]?.animate([{ scale: 0.6 }, { scale: 1.25 }, { scale: 1 }], { duration: 320, easing: "ease-out" })
  }
}
