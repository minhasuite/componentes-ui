import { Controller } from "@hotwired/stimulus"
import { ssMoney, ssSplitCents } from "componentes_ui/controllers/ss_intl"

// Dinheiro como caixa: os dígitos entram pela direita; o hidden guarda os centavos inteiros.
// Moeda do componente (currency, padrão BRL) e formato do <html lang> (Intl).
export default class extends Controller {
  static targets = ["input", "view", "hidden"]
  static values = { currency: { type: String, default: "BRL" } }

  format() {
    const digits = this.inputTarget.value.replace(/\D/g, "").replace(/^0+/, "").slice(0, 13)
    const neg = this.inputTarget.value.trim().startsWith("-")
    if (!digits) { this.inputTarget.value = ""; this.hiddenTarget.value = ""; this.viewTarget.replaceChildren(); return this.changed() }
    const cents = BigInt(digits)
    // Até 13 dígitos cabe sem perda no Number (< 2^53).
    const text = `${neg ? "-" : ""}${ssMoney(Number(cents) / 100, this.currencyValue)}`
    this.inputTarget.value = text
    this.hiddenTarget.value = `${neg ? "-" : ""}${cents}`
    const [main, c, tail] = ssSplitCents(text)
    const small = document.createElement("small"); small.textContent = c
    const amount = document.createElement("span"); amount.className = "ss-amount"
    amount.append(main, small, tail)
    this.viewTarget.replaceChildren(amount)
    this.toEnd()
    this.changed()
  }

  key(e) { if (e.key === "-") { e.preventDefault(); const v = this.inputTarget.value; this.inputTarget.value = v.startsWith("-") ? v.slice(1) : `-${v}`; this.format() } }

  toEnd() { const n = this.inputTarget.value.length; requestAnimationFrame(() => this.inputTarget.setSelectionRange?.(n, n)) }

  changed() { this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true })) }
}
