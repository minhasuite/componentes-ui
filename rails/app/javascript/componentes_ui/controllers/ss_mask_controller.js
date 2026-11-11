import { Controller } from "@hotwired/stimulus"

// Máscara brasileira enquanto digita (v0.20, par do SsMask do Flutter, mesma conta):
// f.ss_text_field :documento, mask: :document  → CPF 000.000.000-00 ou, com 12+ caracteres ou letra,
//   CNPJ 00.000.000/0000-00 (o CNPJ alfanumérico entra: letras em maiúscula nas 12 primeiras posições);
// mask: :phone → (00) 0000-0000 / (00) 00000-0000; mask: :cep → 00000-000.
// O cursor fica depois do mesmo número de caracteres que contam. O valor vai formatado no form
// (o app tira a pontuação no servidor). Valor que já vem do servidor é formatado ao conectar.
export default class extends Controller {
  static values = { kind: String }

  connect() { if (this.element.value) this.format() }

  significant(ch) { return this.kindValue === "document" ? /[0-9a-z]/i.test(ch) : /\d/.test(ch) }

  unmask(text) { return [...text].filter((ch) => this.significant(ch)).join("").toUpperCase() }

  apply(text) {
    let raw = this.unmask(text)
    const join = (s, cuts, seps) => [...s].map((ch, i) => (cuts.includes(i) ? seps[cuts.indexOf(i)] : "") + ch).join("")
    switch (this.kindValue) {
      case "cep": return join(raw.slice(0, 8), [5], ["-"])
      case "phone": {
        raw = raw.slice(0, 11)
        if (!raw) return ""
        if (raw.length <= 2) return `(${raw}`
        return `(${raw.slice(0, 2)}) ${join(raw.slice(2), [raw.length <= 10 ? 4 : 5], ["-"])}`
      }
      case "document": {
        const cnpj = raw.length > 11 || /[A-Z]/.test(raw)
        if (!cnpj) return join(raw, [3, 6, 9], [".", ".", "-"])
        raw = raw.slice(0, 14)
        if (raw.length > 12) raw = raw.slice(0, 12) + raw.slice(12).replace(/\D/g, "")
        return join(raw, [2, 5, 8, 12], [".", ".", "/", "-"])
      }
      default: return text
    }
  }

  format() {
    const el = this.element
    const end = el.selectionEnd ?? el.value.length
    const before = this.unmask(el.value.slice(0, end)).length
    const out = this.apply(el.value)
    if (out === el.value) return
    el.value = out
    let pos = 0
    for (let n = 0; pos < out.length && n < before; pos++) if (this.significant(out[pos])) n++
    if (document.activeElement === el) el.setSelectionRange(pos, pos)
  }
}
