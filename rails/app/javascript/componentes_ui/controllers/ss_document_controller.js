import { Controller } from "@hotwired/stimulus"
import { ssAlnum, ssDocumentKind, ssDocumentValid } from "componentes_ui/controllers/ss_br"

// v1.12.0 (f.ss_document, par do SsDocumentField): CPF ou CNPJ (o alfanumérico também; a máscara é a do ss-mask):
// detecta o tipo, confere os dígitos (setCustomValidity) e, com url-value ("/cnpj/%{cnpj}", JSON { name }), mostra
// a razão social embaixo. kind-value "cpf"/"cnpj" aceita um só.
export default class extends Controller {
  static targets = ["input", "out"]
  static values = { texts: Object, kind: String, url: String }

  connect() { this.seq = 0; if (this.inputTarget.value) this.check() }

  say(text, tone = "") {
    this.outTarget.hidden = !text
    this.outTarget.textContent = text || ""
    this.outTarget.classList.toggle("is-warn", tone === "warn")
    this.outTarget.classList.toggle("is-ok", tone === "ok")
  }

  async check() {
    const raw = ssAlnum(this.inputTarget.value)
    const t = this.textsValue
    const kind = ssDocumentKind(raw)
    const only = ["cpf", "cnpj"].includes(this.kindValue) ? this.kindValue : null
    const complete = raw.length === 11 || raw.length === 14
    let err = ""
    if (raw && complete) {
      if (only && kind !== only) err = t[only]
      else if (!ssDocumentValid(raw)) err = t[kind]
    } else if (raw && raw.length > 14) err = t[kind]
    this.inputTarget.setCustomValidity(err)
    const ok = complete && !err
    if (!ok || kind !== "cnpj" || !this.urlValue) { this.last = null; this.say(""); return }
    if (raw === this.last) return
    this.last = raw
    const me = ++this.seq
    this.say(t.looking)
    try {
      const r = await fetch(this.urlValue.replace("%{cnpj}", raw), { headers: { Accept: "application/json" } })
      if (me !== this.seq) return
      const j = r.ok ? await r.json().catch(() => null) : null
      if (j?.name) this.say(j.name, "ok")
      else this.say(t.not_found, "warn")
    } catch (_) {
      if (me === this.seq) this.say("")
    }
  }

  leave() {
    const raw = ssAlnum(this.inputTarget.value)
    if (raw && raw.length !== 11 && raw.length !== 14) {
      const t = this.textsValue
      this.inputTarget.setCustomValidity(t[ssDocumentKind(raw)] || t.cpf)
    }
  }
}
