import { Controller } from "@hotwired/stimulus"

// v1.13.0 (Ss::ContinueOnComponent, par do SsContinueOn): com url-value (o endpoint do produto) e form-value (o id do
// formulário com o rascunho), ao abrir manda o FormData (POST, com o token do Rails) e troca o link e o QR pelo que
// voltar ({ url:, svg: }, o Ss::ContinueOnComponent.payload). Sem url-value, o link do servidor fica como está.
export default class extends Controller {
  static targets = ["qr", "link", "note"]
  static values = { url: String, form: String, long: { type: Number, default: 300 } }

  async refresh() {
    if (!this.urlValue) return
    const form = this.formValue ? document.getElementById(this.formValue) : null
    const token = document.querySelector("meta[name=csrf-token]")?.content
    try {
      const res = await fetch(this.urlValue, {
        method: "POST", credentials: "same-origin", body: form ? new FormData(form) : null,
        headers: { Accept: "application/json", ...(token ? { "X-CSRF-Token": token } : {}) }
      })
      if (!res.ok) return
      const { url, svg } = await res.json()
      if (url && this.hasLinkTarget) this.linkTarget.value = url
      if (svg && this.hasQrTarget) this.qrTarget.innerHTML = svg
      if (this.hasNoteTarget) this.noteTarget.hidden = !(url && url.length > this.longValue)
      this.dispatch("refreshed", { prefix: "ss-continue-on", detail: { url } })
    } catch (_) {}
  }
}
