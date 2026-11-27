import { Controller } from "@hotwired/stimulus"
import { ssDetect, ssFormatNfeKey } from "componentes_ui/controllers/ss_br"
import { ssFormat, ssLang, ssMoney, ssNumber } from "componentes_ui/controllers/ss_intl"

// v1.12.0 (Ss::SmartPasteComponent, par do SsSmartPaste): o retorno ao vivo do colar inteligente. A cada mudança
// no campo, o ssDetect (o mesmo detector do Ruby e do Dart) diz o tipo e o controller monta o cartão igual ao do
// servidor: ícone, a frase ("Isso parece um boleto de R$ 123,45…"), o detalhe e as ações que o produto registrou
// para o tipo (actions-value). O botão "Colar" lê a área de transferência (precisa de permissão do navegador;
// sem ela, o botão some). Dispara ss-smart-paste:detected { match } no elemento.
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c])

export default class extends Controller {
  static targets = ["input", "result", "paste"]
  static values = { actions: Object, texts: Object, icons: Object, param: { type: String, default: "paste" }, token: String, today: String }

  connect() {
    if (this.hasPasteTarget && !navigator.clipboard?.readText) this.pasteTarget.hidden = true
  }

  async paste() {
    try {
      const t = await navigator.clipboard.readText()
      if (!t) return
      this.inputTarget.value = t
      this.detect()
      this.inputTarget.focus()
    } catch (_) {
      this.pasteTarget.hidden = true
      this.inputTarget.focus()
    }
  }

  detect() {
    const m = ssDetect(this.inputTarget.value, this.todayValue || null)
    this.resultTarget.innerHTML = m ? this.card(m) : `<p class="ss-smart-paste-empty">${esc(this.textsValue.empty)}</p>`
    this.dispatch("detected", { detail: { match: m } })
  }

  date(iso) {
    const [y, mo, d] = iso.split("-").map(Number)
    return new Intl.DateTimeFormat(ssLang(), { day: "2-digit", month: "2-digit", year: "numeric", timeZone: "UTC" }).format(new Date(Date.UTC(y, mo - 1, d)))
  }

  summary(m) {
    const t = this.textsValue
    const what = t.what?.[m.type]
    if (!m.valid && what) return ssFormat(t.invalid, { what })
    const f = m.fields
    const amount = f.amount_cents != null ? ssMoney(f.amount_cents / 100, t.currency) : null
    const iso = f.due_date || f.date
    const date = iso ? this.date(iso) : null
    let key = m.type
    if (m.type === "pix") key = amount ? "pix" : "pix_free"
    if (m.type === "boleto") key = amount && date ? "boleto" : amount ? "boleto_amount" : date ? "boleto_due" : "boleto_plain"
    return ssFormat(t.summary?.[key] ?? key, {
      amount: amount ?? "", date: date ?? "", name: f.name ?? "", value: f.display ?? m.value, model: f.model_name ?? "NF-e",
      uf: f.uf ?? "", number: f.number != null ? ssNumber(f.number) : "", domain: f.domain ?? "", count: String(f.length ?? m.text.length),
    })
  }

  card(m) {
    const t = this.textsValue
    // DV errado: sem ações (não oferece "Pagar" para um boleto que não confere).
    const list = m.valid ? [m.type, ...m.also].flatMap((ty) => this.actionsValue[ty] || []) : []
    const primary = Math.max(0, list.findIndex((a) => a.primary))
    const detail = m.type === "boleto" ? m.fields.display : m.type === "nfe" ? ssFormatNfeKey(m.value) : null
    const also = m.also.includes("pix_key") ? [t.pix_key, t.key_types?.[m.type]].filter(Boolean).join(" · ") : null
    const icon = this.iconsValue[m.valid ? m.type : "invalid"] || ""
    const actions = list.length
      ? `<div class="ss-paste-actions" role="group" aria-label="${esc(t.actions)}">${list.map((a, i) => this.action(a, m, i === primary)).join("")}</div>`
      : ""
    return `<div class="ss-card ss-paste-card" data-type="${esc(m.type)}" data-valid="${m.valid}">` +
      `<div class="ss-paste-head"><span class="ss-paste-icon" aria-hidden="true">${icon}</span><p class="ss-paste-summary">${esc(this.summary(m))}</p></div>` +
      (detail ? `<p class="ss-paste-detail num">${esc(detail)}</p>` : "") +
      (also ? `<span class="ss-badge ss-badge-muted ss-paste-also">${esc(also)}</span>` : "") +
      actions + "</div>"
  }

  action(a, m, primary) {
    const css = `ss-btn ss-btn-sm ${primary ? "ss-btn-primary" : "ss-btn-ghost"}`
    const icon = a.icon && this.iconsValue[`action:${a.icon}`] ? this.iconsValue[`action:${a.icon}`] : ""
    const body = `${icon}<span>${esc(a.label)}</span>`
    const href = (a.href || "").replaceAll("%{value}", encodeURIComponent(m.value)).replaceAll("%{type}", m.type)
    if ((a.method || "get") === "get") {
      return `<a class="${css}" href="${esc(href)}"${a.target ? ` target="${esc(a.target)}" rel="noopener"` : ""}>${body}</a>`
    }
    const p = this.paramValue
    const token = this.tokenValue || document.querySelector('meta[name="csrf-token"]')?.content || ""
    return `<form action="${esc(href)}" method="post" class="ss-paste-form">` +
      (a.method !== "post" ? `<input type="hidden" name="_method" value="${esc(a.method)}">` : "") +
      (token ? `<input type="hidden" name="authenticity_token" value="${esc(token)}">` : "") +
      `<input type="hidden" name="${esc(p)}[value]" value="${esc(m.value)}"><input type="hidden" name="${esc(p)}[type]" value="${esc(m.type)}">` +
      `<button type="submit" class="${css}">${body}</button></form>`
  }
}
