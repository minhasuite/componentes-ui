import { Controller } from "@hotwired/stimulus"

// Dinheiro BRL como caixa: os dígitos entram pela direita; o hidden guarda os centavos inteiros.
export default class extends Controller {
  static targets = ["input", "view", "hidden"]

  format() {
    const digits = this.inputTarget.value.replace(/\D/g, "").replace(/^0+/, "").slice(0, 13)
    const neg = this.inputTarget.value.trim().startsWith("-")
    if (!digits) { this.inputTarget.value = ""; this.hiddenTarget.value = ""; this.viewTarget.replaceChildren(); return this.changed() }
    const cents = BigInt(digits)
    const reais = (cents / 100n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".")
    const c = (cents % 100n).toString().padStart(2, "0")
    const text = `${neg ? "-" : ""}R$ ${reais},${c}`
    this.inputTarget.value = text
    this.hiddenTarget.value = `${neg ? "-" : ""}${cents}`
    const small = document.createElement("small"); small.textContent = `,${c}`
    const amount = document.createElement("span"); amount.className = "ss-amount"
    amount.append(`${neg ? "-" : ""}R$ ${reais}`, small)
    this.viewTarget.replaceChildren(amount)
    this.toEnd()
    this.changed()
  }

  key(e) { if (e.key === "-") { e.preventDefault(); const v = this.inputTarget.value; this.inputTarget.value = v.startsWith("-") ? v.slice(1) : `-${v}`; this.format() } }

  toEnd() { const n = this.inputTarget.value.length; requestAnimationFrame(() => this.inputTarget.setSelectionRange?.(n, n)) }

  changed() { this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true })) }
}
