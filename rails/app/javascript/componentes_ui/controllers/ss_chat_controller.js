import { Controller } from "@hotwired/stimulus"

// Ss::ChatComponent (v0.15): rola para a última mensagem, Enter envia (Shift+Enter quebra
// linha), o campo cresce até 6 linhas, a bolha da pessoa entra na hora (echo) e o "pensando"
// fica até chegar mensagem do assistente no log (ou o envio falhar).
export default class extends Controller {
  static targets = ["log", "thinking", "input", "send", "form", "empty"]
  static values = { echo: { type: Boolean, default: true }, thinking: Boolean }

  connect() {
    this.observer = new MutationObserver((list) => this.added(list))
    if (this.hasLogTarget) this.observer.observe(this.logTarget, { childList: true, subtree: true })
    this.scroll(false)
  }

  disconnect() { this.observer?.disconnect() }

  key(e) {
    if (e.key !== "Enter" || e.shiftKey || e.isComposing) return
    e.preventDefault()
    if (this.inputTarget.value.trim()) this.formTarget.requestSubmit()
  }

  grow() {
    const el = this.inputTarget
    el.style.height = "auto"
    el.style.height = `${Math.min(el.scrollHeight, parseFloat(getComputedStyle(el).lineHeight || "20") * 6 + 24)}px`
  }

  sending(e) {
    const text = this.inputTarget.value.trim()
    if (!text) { e.preventDefault(); return }
    if (this.echoValue) {
      const b = document.createElement("div")
      b.className = "ss-bubble is-me"
      b.dataset.from = "me"
      b.dataset.echo = ""
      text.split(/\n{2,}/).forEach((p) => { const el = document.createElement("p"); el.textContent = p; b.append(el) })
      this.emptyTargets.forEach((x) => x.remove())
      this.logTarget.append(b)
    }
    this.think(true)
    // O valor vai no corpo do envio (já montado); limpa depois que o Turbo leu o form.
    requestAnimationFrame(() => { this.inputTarget.value = ""; this.grow() })
  }

  sent(e) { if (!e.detail?.success) this.think(false) }

  added(list) {
    const ai = list.some((m) => [...m.addedNodes].some((n) => n.nodeType === 1 && !n.matches?.("[data-echo], .is-me") &&
      (n.matches?.(".ss-bubble, .ss-chat-action") || n.querySelector?.(".ss-bubble:not(.is-me), .ss-chat-action"))))
    if (ai) this.think(false)
    this.scroll(true)
  }

  think(on) {
    if (!this.hasThinkingTarget) return
    this.thinkingTarget.hidden = !on
    if (this.hasSendTarget) this.sendTarget.toggleAttribute("aria-busy", on)
    if (on) this.scroll(true)
  }

  scroll(smooth) {
    if (!this.hasLogTarget) return
    const el = this.logTarget
    const behavior = smooth && !matchMedia("(prefers-reduced-motion: reduce)").matches ? "smooth" : "auto"
    requestAnimationFrame(() => {
      el.scrollTo?.({ top: el.scrollHeight, behavior })
      if (this.hasThinkingTarget && !this.thinkingTarget.hidden) this.thinkingTarget.scrollIntoView?.({ block: "nearest", behavior })
    })
  }
}
