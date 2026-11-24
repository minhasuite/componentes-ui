import { Controller } from "@hotwired/stimulus"

// Ss::AssistantComponent (v1.9): atalhos que escrevem no campo e enviam, e a resposta pendente que se busca sozinha.
// Cada bolha pendente (data-ss-assistant-target="pending" data-url="…") pergunta a URL a cada every ms (Accept
// text/html; pausa com a aba escondida): 204 ou corpo vazio = ainda pensando; HTML = troca a bolha (se vier outra
// pendente, ela continua). Depois de max tentativas, a bolha vira o erro (failed).
export default class extends Controller {
  static targets = ["pending"]
  static values = { every: { type: Number, default: 2000 }, max: { type: Number, default: 90 }, failed: String }

  connect() {
    this.timers = new Map()
    this.onVisible = () => { if (!document.hidden) this.pendingTargets.forEach((el) => this.check(el)) }
    document.addEventListener("visibilitychange", this.onVisible)
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.onVisible)
    this.timers.forEach((t) => clearTimeout(t))
    this.timers.clear()
  }

  pendingTargetConnected(el) {
    if (!el.dataset.url) return
    el.dataset.tries = el.dataset.tries || "0"
    this.schedule(el)
  }

  pendingTargetDisconnected(el) {
    clearTimeout(this.timers.get(el))
    this.timers.delete(el)
  }

  schedule(el) {
    clearTimeout(this.timers.get(el))
    this.timers.set(el, setTimeout(() => this.check(el), this.everyValue))
  }

  async check(el) {
    if (!el.isConnected || el.dataset.busy) return
    if (document.hidden) { this.schedule(el); return }
    const tries = Number(el.dataset.tries || 0) + 1
    el.dataset.tries = String(tries)
    el.dataset.busy = "1"
    try {
      const r = await fetch(el.dataset.url, { headers: { Accept: "text/html" }, credentials: "same-origin" })
      const html = r.status === 204 || !r.ok ? "" : (await r.text()).trim()
      if (html) {
        el.outerHTML = html
        return
      }
    } catch (_) {
      // Rede caiu: tenta de novo no próximo ciclo.
    } finally {
      delete el.dataset.busy
    }
    if (tries >= this.maxValue) this.fail(el)
    else this.schedule(el)
  }

  fail(el) {
    const b = document.createElement("div")
    b.className = "ss-bubble is-ai is-failed"
    b.dataset.from = "ai"
    const p = document.createElement("p")
    p.textContent = this.failedValue || "Não deu para responder agora."
    b.append(p)
    el.replaceWith(b)
  }

  // Atalho: escreve o prompt no campo da conversa e envia (o ss-chat põe a bolha e o "pensando").
  pick({ params: { prompt } }) {
    const input = this.element.querySelector(".ss-chat-input")
    const form = this.element.querySelector(".ss-chat-form")
    if (!input || !form || input.disabled || !prompt) return
    input.value = prompt
    input.dispatchEvent(new Event("input", { bubbles: true }))
    form.requestSubmit()
  }
}
