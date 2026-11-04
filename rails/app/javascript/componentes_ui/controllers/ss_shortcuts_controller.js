import { Controller } from "@hotwired/stimulus"

// Atalhos (Ss::ShortcutsComponent): "?" abre a lista; sequências tipo "g p" (até 1 s
// entre as teclas) ou tecla única navegam (Turbo, se tiver). Ignora campos de texto.
export default class extends Controller {
  static targets = ["dialog"]
  static values = { bindings: Array }

  key(event) {
    if (event.defaultPrevented || event.ctrlKey || event.metaKey || event.altKey) return
    const t = event.target
    if (t.closest("input, textarea, select, [contenteditable=''], [contenteditable='true']")) return
    if (event.key === "?") {
      event.preventDefault()
      this.dialogTarget.open ? this.dialogTarget.close() : this.dialogTarget.showModal()
      return
    }
    if (this.dialogTarget.open) return
    const k = event.key.length === 1 ? event.key.toLowerCase() : null
    if (!k) return
    const seq = Date.now() - (this.lastAt || 0) < 1000 && this.last ? `${this.last} ${k}` : k
    const hit = this.bindingsValue.find((b) => b.keys === seq) || this.bindingsValue.find((b) => b.keys === k)
    this.last = k
    this.lastAt = Date.now()
    if (!hit) return
    event.preventDefault()
    this.last = null
    window.Turbo ? window.Turbo.visit(hit.url) : (location.href = hit.url)
  }

  open() { this.dialogTarget.showModal() }
  close() { this.dialogTarget.close() }
}
