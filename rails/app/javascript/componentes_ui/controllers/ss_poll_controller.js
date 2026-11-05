import { Controller } from "@hotwired/stimulus"

// Pergunta ao servidor de tempos em tempos (v0.10.2): login por QR, varredura, instalação.
// A resposta JSON manda: { url } abre a página (e para), { error } para e mostra o texto no
// [role=status] de dentro, { status } só atualiza o texto. Pausa com a aba escondida.
//   <div data-controller="ss-poll" data-ss-poll-url-value="/login/qr/abc" data-ss-poll-every-value="3000">
//     <p role="status"></p>
export default class extends Controller {
  static values = { url: String, every: { type: Number, default: 3000 } }

  connect() { this.timer = setInterval(() => this.check(), this.everyValue) }
  disconnect() { this.stop() }

  stop() { clearInterval(this.timer); this.timer = null }

  async check() {
    if (this.busy || document.hidden) return
    this.busy = true
    try {
      const r = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      const j = r.ok ? await r.json() : {}
      const status = this.element.querySelector("[role=status]")
      if (j.url) {
        this.stop()
        this.dispatch("done", { prefix: "ss-poll", detail: j })
        window.Turbo ? window.Turbo.visit(j.url) : (window.location.href = j.url)
      } else if (j.error) {
        this.stop()
        if (status) status.textContent = j.error
        this.dispatch("error", { prefix: "ss-poll", detail: j })
      } else if (j.status && status) {
        status.textContent = j.status
      }
    } catch (_) {
      // rede caiu: tenta de novo na próxima volta
    } finally { this.busy = false }
  }
}
