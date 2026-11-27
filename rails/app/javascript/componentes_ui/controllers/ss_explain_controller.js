import { Controller } from "@hotwired/stimulus"

// v1.13.0 (Ss::ExplainComponent, par do SsExplain): o "Explicar com IA" do popover de um valor. Pede a explicação ao
// produto (url-value, POST com o token do Rails, Accept JSON) e espera { text: "…" }. Enquanto pensa, os pontinhos e
// "Cancelar" (AbortController); depois o texto (região viva) com a nota de conferir; erro: a frase e "Tentar de novo".
// O estado fica em data-state no alvo "ai": idle | thinking | done | error.
export default class extends Controller {
  static targets = ["ai", "text"]
  static values = { url: String, method: { type: String, default: "POST" } }

  disconnect() { this.request?.abort() }

  async ask() {
    if (!this.urlValue) return
    this.request?.abort()
    const request = (this.request = new AbortController())
    this.state("thinking")
    try {
      const token = document.querySelector("meta[name=csrf-token]")?.content
      const res = await fetch(this.urlValue, {
        method: this.methodValue, signal: request.signal, credentials: "same-origin",
        headers: { Accept: "application/json", ...(token ? { "X-CSRF-Token": token } : {}) }
      })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const body = await res.json()
      if (request.signal.aborted) return
      this.textTarget.textContent = body.text ?? ""
      this.state("done")
      this.dispatch("answered", { prefix: "ss-explain", detail: { text: body.text } })
    } catch (e) {
      if (request.signal.aborted) return
      this.state("error")
    }
  }

  cancel() {
    this.request?.abort()
    this.request = null
    this.state("idle")
    this.dispatch("cancelled", { prefix: "ss-explain" })
  }

  state(s) { if (this.hasAiTarget) this.aiTarget.dataset.state = s }
}
