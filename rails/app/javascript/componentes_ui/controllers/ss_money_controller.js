import { Controller } from "@hotwired/stimulus"
import { ssMoney, ssSplitCents, ssAmountExpression, ssIsExpression } from "componentes_ui/controllers/ss_intl"

// Dinheiro como caixa: os dígitos entram pela direita; o hidden guarda os centavos inteiros.
// Moeda do componente (currency, padrão BRL) e formato do <html lang> (Intl).
// v0.15: signed=false trava o sinal; expression=true aceita conta ("45+12,50"): o resultado
// aparece embaixo ("= R$ 57,50"), vai para o hidden e, ao sair do campo, vira o texto.
export default class extends Controller {
  static targets = ["input", "view", "hidden", "result"]
  static values = { currency: { type: String, default: "BRL" }, signed: { type: Boolean, default: true },
                    expression: Boolean, invalid: { type: String, default: "Conta ou valor inválido" } }

  format() {
    if (this.expressionValue) return this.evaluate()
    const digits = this.inputTarget.value.replace(/\D/g, "").replace(/^0+/, "").slice(0, 13)
    const neg = this.signedValue && this.inputTarget.value.trim().startsWith("-")
    if (!digits) { this.inputTarget.value = ""; this.hiddenTarget.value = ""; this.viewTarget.replaceChildren(); return this.changed() }
    const cents = BigInt(digits)
    // Até 13 dígitos cabe sem perda no Number (< 2^53).
    const text = `${neg ? "-" : ""}${ssMoney(Number(cents) / 100, this.currencyValue)}`
    this.inputTarget.value = text
    this.hiddenTarget.value = `${neg ? "-" : ""}${cents}`
    this.viewTarget.replaceChildren(this.amount(text))
    this.toEnd()
    this.changed()
  }

  // Modo conta: o texto fica como a pessoa digitou; o hidden e o "= R$ …" acompanham.
  evaluate() {
    const raw = this.inputTarget.value
    const text = raw.replace(/^\s*(R\$|US\$|€|£|\$)\s*/, "")
    const cents = text.trim() ? ssAmountExpression(text) : null
    const ok = !text.trim() || (cents !== null && (this.signedValue || cents >= 0))
    this.inputTarget.setCustomValidity(ok ? "" : this.invalidValue)
    this.inputTarget.toggleAttribute("aria-invalid", !ok)
    this.hiddenTarget.value = ok && cents !== null ? String(cents) : ""
    if (this.hasResultTarget) {
      this.resultTarget.replaceChildren()
      if (cents !== null && ok && ssIsExpression(text)) this.resultTarget.append("= ", this.amount(ssMoney(cents / 100, this.currencyValue)))
      else if (!ok) this.resultTarget.textContent = this.invalidValue
    }
    this.changed()
  }

  // Saiu do campo com conta válida: o texto vira o valor formatado.
  settle() {
    const cents = this.hiddenTarget.value
    if (cents === "" || !ssIsExpression(this.inputTarget.value)) return
    this.inputTarget.value = ssMoney(Number(cents) / 100, this.currencyValue)
    if (this.hasResultTarget) this.resultTarget.replaceChildren()
  }

  key(e) {
    if (this.expressionValue) {
      if (e.key === "Enter") this.settle()
      return
    }
    if (e.key !== "-") return
    e.preventDefault()
    if (!this.signedValue) return
    const v = this.inputTarget.value
    this.inputTarget.value = v.startsWith("-") ? v.slice(1) : `-${v}`
    this.format()
  }

  amount(text) {
    const [main, c, tail] = ssSplitCents(text)
    const small = document.createElement("small"); small.textContent = c
    const amount = document.createElement("span"); amount.className = "ss-amount"
    amount.append(main, small, tail)
    return amount
  }

  toEnd() { const n = this.inputTarget.value.length; requestAnimationFrame(() => this.inputTarget.setSelectionRange?.(n, n)) }

  changed() { this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true })) }
}
