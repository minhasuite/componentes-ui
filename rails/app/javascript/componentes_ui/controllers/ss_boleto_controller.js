import { Controller } from "@hotwired/stimulus"
import { ssBoleto, ssBoletoLineFromBarcode, ssDigits, ssFormatBoleto } from "componentes_ui/controllers/ss_br"
import { ssFormat, ssLang, ssMoney } from "componentes_ui/controllers/ss_intl"

// v1.12.0 (f.ss_boleto, par do SsBoletoField): a máscara da linha digitável (47 bancário em 5 blocos, 48 conta de
// consumo em 4; colar o código de barras de 44 vira a linha), os dígitos verificadores pelo setCustomValidity e, com
// a linha completa e certa, o tipo, o valor e o vencimento embaixo (vencido em âmbar).
export default class extends Controller {
  static targets = ["input", "out"]
  static values = { texts: Object }

  connect() { if (this.inputTarget.value) this.check() }

  format() {
    const el = this.inputTarget
    let d = ssDigits(el.value)
    const barcode = d.length === 44 && ssBoletoLineFromBarcode(d)
    if (barcode) d = barcode
    const out = ssFormatBoleto(d)
    if (out === el.value) return
    const end = el.selectionEnd ?? el.value.length
    const before = ssDigits(el.value.slice(0, end)).length
    el.value = out
    let pos = 0
    for (let n = 0; pos < out.length && n < before; pos++) if (/\d/.test(out[pos])) n++
    if (document.activeElement === el) el.setSelectionRange(barcode ? out.length : pos, barcode ? out.length : pos)
  }

  date(iso) {
    const [y, m, d] = iso.split("-").map(Number)
    return new Intl.DateTimeFormat(ssLang(), { day: "2-digit", month: "2-digit", year: "numeric", timeZone: "UTC" }).format(new Date(Date.UTC(y, m - 1, d)))
  }

  check() {
    this.format()
    const t = this.textsValue
    const d = ssDigits(this.inputTarget.value)
    const full = d.length === 47 || (d.length === 48 && d.startsWith("8"))
    const b = full ? ssBoleto(d) : null
    this.inputTarget.setCustomValidity(!d ? "" : !full ? t.incomplete : b.valid ? "" : t.invalid)
    const ok = b && b.valid
    this.outTarget.hidden = !ok
    this.outTarget.classList.remove("is-warn")
    if (!ok) { this.outTarget.textContent = ""; return }
    const partes = [b.amountCents ? ssMoney(b.amountCents / 100, t.currency) : t.no_amount]
    if (b.dueDate) {
      const hoje = new Date().toISOString().slice(0, 10)
      const vencido = b.dueDate < hoje
      partes.push(ssFormat(vencido ? t.overdue : t.due, { date: this.date(b.dueDate) }))
      this.outTarget.classList.toggle("is-warn", vencido)
    } else if (b.kind === "bank") partes.push(t.no_due)
    this.outTarget.innerHTML = `<span class="ss-badge ss-badge-success"></span> <span></span>`
    this.outTarget.children[0].textContent = b.kind === "bank" ? t.bank : t.collection
    this.outTarget.children[1].textContent = partes.join(" · ")
  }

  leave() {}
}
