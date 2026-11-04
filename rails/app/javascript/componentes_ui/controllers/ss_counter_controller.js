import { Controller } from "@hotwired/stimulus"

// Contador de caracteres do f.ss_text_field(counter: 80): "12/80"; perto do fim fica em aviso.
export default class extends Controller {
  static targets = ["input", "output"]

  connect() { this.update() }

  update() {
    if (!this.hasInputTarget || !this.hasOutputTarget) return
    const max = Number(this.inputTarget.maxLength) || 0
    const n = this.inputTarget.value.length
    this.outputTarget.textContent = max > 0 ? `${n}/${max}` : `${n}`
    this.outputTarget.classList.toggle("is-near", max > 0 && n >= max * 0.9)
  }
}
