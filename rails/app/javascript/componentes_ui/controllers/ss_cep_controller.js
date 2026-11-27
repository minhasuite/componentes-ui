import { Controller } from "@hotwired/stimulus"
import { ssCepValid, ssDigits } from "componentes_ui/controllers/ss_br"

// v1.12.0 (f.ss_cep, par do SsCepField): com os 8 dígitos, busca o endereço no endpoint do produto (url-value com
// %{cep}; JSON { street, district, city, state }) e preenche os campos ligados (fill-value: { street: "id" … }).
// Não achou (404 ou corpo vazio) ou falhou: diz embaixo e deixa preencher à mão. Resposta velha não passa por cima
// da nova. Dispara ss-cep:found { address }.
export default class extends Controller {
  static targets = ["input", "out"]
  static values = { texts: Object, url: String, fill: Object }

  connect() { this.seq = 0 }

  say(text, tone = "") {
    this.outTarget.hidden = !text
    this.outTarget.textContent = text || ""
    this.outTarget.classList.toggle("is-warn", tone === "warn")
    this.outTarget.classList.toggle("is-ok", tone === "ok")
  }

  async check() {
    const d = ssDigits(this.inputTarget.value)
    const t = this.textsValue
    this.inputTarget.setCustomValidity(d && d.length === 8 && !ssCepValid(d) ? t.invalid : "")
    if (d.length !== 8 || !ssCepValid(d)) { this.last = null; this.say(""); return }
    if (!this.urlValue || d === this.last) return
    this.last = d
    const me = ++this.seq
    this.say(t.looking)
    this.element.setAttribute("aria-busy", "true")
    try {
      const r = await fetch(this.urlValue.replace("%{cep}", d), { headers: { Accept: "application/json" } })
      if (me !== this.seq) return
      const a = r.ok ? await r.json().catch(() => null) : null
      if (r.status !== 404 && !r.ok) throw new Error(String(r.status))
      if (!a || !Object.keys(a).length) { this.say(t.not_found, "warn"); return }
      for (const [k, id] of Object.entries(this.fillValue || {})) {
        const el = document.getElementById(id)
        if (el && a[k]) { el.value = a[k]; el.dispatchEvent(new Event("input", { bubbles: true })) }
      }
      this.say([a.street, a.district, [a.city, a.state].filter(Boolean).join("/")].filter(Boolean).join(" · "), "ok")
      this.dispatch("found", { detail: { address: a } })
    } catch (_) {
      if (me === this.seq) this.say(t.error, "warn")
    } finally {
      if (me === this.seq) this.element.removeAttribute("aria-busy")
    }
  }

  leave() {}
}
