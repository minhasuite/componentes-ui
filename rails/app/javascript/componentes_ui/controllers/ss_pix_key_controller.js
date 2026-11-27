import { Controller } from "@hotwired/stimulus"
import { ssPixKeyDisplay, ssPixKeyType } from "componentes_ui/controllers/ss_br"

// v1.12.0 (f.ss_pix_key, par do SsPixKeyField): o tipo da chave Pix enquanto digita (CPF, CNPJ, telefone, e-mail ou
// aleatória) na linha de baixo, a chave formatada ao sair do campo e o erro pelo setCustomValidity (o ss-validate
// mostra). only-value prende num tipo.
export default class extends Controller {
  static targets = ["input", "out"]
  static values = { texts: Object, only: String }

  connect() { if (this.inputTarget.value) this.check() }

  type(v) {
    const t = ssPixKeyType(v)
    return !this.onlyValue || t === this.onlyValue ? t : null
  }

  check() {
    const v = this.inputTarget.value.trim()
    const t = v ? this.type(v) : null
    this.inputTarget.setCustomValidity(v && !t ? this.textsValue.invalid : "")
    this.outTarget.hidden = !t
    this.outTarget.innerHTML = t ? `<span class="ss-badge ss-badge-success">${this.textsValue.types?.[t] ?? t}</span> <span class="num"></span>` : ""
    if (t) this.outTarget.querySelector(".num").textContent = ssPixKeyDisplay(v, t)
  }

  leave() {
    const v = this.inputTarget.value.trim()
    const t = v && this.type(v)
    if (t) this.inputTarget.value = ssPixKeyDisplay(v, t)
  }
}
