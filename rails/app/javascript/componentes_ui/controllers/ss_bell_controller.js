import { Controller } from "@hotwired/stimulus"

// Sino de avisos (Ss::NotificationBellComponent, v0.25): mantém o contador em dia perguntando ao servidor
// (url → JSON { count }) a cada `every` ms, com a aba visível, ao voltar para a aba e ao abrir o painel; ao
// reabrir o painel, recarrega a lista (o <turbo-frame> lazy carrega sozinho na primeira vez).
// Dispara "ss-bell:change" com { count } quando o número muda (ex. o selo do ícone da PWA).
export default class extends Controller {
  static targets = ["count", "button", "frame"]
  static values = { url: String, every: { type: Number, default: 60000 }, label: String, unread: String }

  connect() {
    this.onVisible = () => { if (!document.hidden) this.refresh() }
    document.addEventListener("visibilitychange", this.onVisible)
    if (this.urlValue && this.everyValue > 0) this.timer = setInterval(() => this.refresh(), this.everyValue)
  }

  disconnect() {
    clearInterval(this.timer)
    document.removeEventListener("visibilitychange", this.onVisible)
  }

  toggled(event) {
    if (event.newState !== "open") return
    if (this.hasFrameTarget && this.opened && typeof this.frameTarget.reload === "function") this.frameTarget.reload()
    this.opened = true
    this.refresh()
  }

  async refresh() {
    if (!this.urlValue || this.busy || document.hidden) return
    this.busy = true
    try {
      const r = await fetch(this.urlValue, { headers: { Accept: "application/json" }, credentials: "same-origin" })
      if (r.ok) this.set((await r.json()).count)
    } catch (_) {
      // rede caiu: tenta de novo na próxima volta
    } finally { this.busy = false }
  }

  set(value) {
    const n = Math.max(0, parseInt(value, 10) || 0)
    const text = n > 99 ? "99+" : String(n)
    if (!this.hasCountTarget) return
    const changed = this.countTarget.textContent !== text
    this.countTarget.textContent = text
    this.countTarget.hidden = n === 0
    if (this.hasButtonTarget) this.buttonTarget.setAttribute("aria-label", n > 0 ? this.unreadValue.replace("%{count}", text) : this.labelValue)
    if (changed) this.dispatch("change", { detail: { count: n } })
  }
}
