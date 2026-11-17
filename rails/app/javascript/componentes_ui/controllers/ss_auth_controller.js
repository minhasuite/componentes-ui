import { Controller } from "@hotwired/stimulus"

// Ss::AuthLayoutComponent(motion: true) (v1.4, variante :wall): a folhinha reage à entrada.
// - Enviar o formulário (ou tocar em "Entrar com o Google"): a folha se solta do pino e cai; por baixo aparece a
//   seguinte (o <template> do componente) com a saudação da hora, "Abrindo o <produto>…" e o carimbo. O envio
//   segue na hora: nada espera a animação.
// - error: true: a folha treme ao abrir (a página voltou com o erro). Se o Turbo devolver falha sem trocar a
//   página, a folha volta ao pino e treme.
// Com "reduzir movimento", a folha só some (sem cair) e nada treme.
export default class extends Controller {
  static targets = ["next"]
  static values = { error: Boolean, greetings: Array }

  connect() {
    this.sheet = this.element.querySelector(".ss-auth-wall .ss-auth-sheet")
    this.onEnd = (e) => { if (e.detail && e.detail.success === false) this.restore(true) }
    this.onShow = (e) => { if (e.persisted) this.restore(false) }
    document.addEventListener("turbo:submit-end", this.onEnd)
    window.addEventListener("pageshow", this.onShow)
    if (this.errorValue) this.shake()
  }

  disconnect() {
    document.removeEventListener("turbo:submit-end", this.onEnd)
    window.removeEventListener("pageshow", this.onShow)
  }

  click(e) {
    const google = e.target.closest(".ss-google-btn")
    if (google && !e.defaultPrevented && e.button === 0 && !e.metaKey && !e.ctrlKey) this.leave()
  }

  leave() {
    if (!this.sheet || this.leaving || !this.hasNextTarget) return
    this.leaving = true
    const next = this.nextTarget.content.firstElementChild.cloneNode(true)
    next.querySelector(".ss-auth-hello").textContent = this.greeting() + "."
    const s = this.sheet
    Object.assign(next.style, { left: s.offsetLeft + "px", top: s.offsetTop + "px", width: s.offsetWidth + "px", height: s.offsetHeight + "px" })
    s.after(next)
    this.next = next
    this.sheet.classList.remove("is-shaking")
    this.sheet.classList.add("is-tearing")
  }

  restore(shake) {
    if (!this.leaving) return
    this.leaving = false
    if (this.next) this.next.remove()
    this.sheet.classList.remove("is-tearing")
    if (shake) this.shake()
  }

  shake() {
    if (!this.sheet) return
    this.sheet.classList.remove("is-shaking")
    void this.sheet.offsetWidth
    this.sheet.classList.add("is-shaking")
  }

  greeting() {
    const [manha, tarde, noite] = this.greetingsValue
    const h = new Date().getHours()
    return h >= 5 && h < 12 ? manha : h >= 12 && h < 18 ? tarde : noite
  }
}
