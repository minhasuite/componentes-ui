import { Controller } from "@hotwired/stimulus"

// Novidades (Ss::WhatsNewComponent): ponto no sino e selo "novo" nos itens que a
// pessoa ainda não viu; abrir o painel marca tudo como visto no navegador.
export default class extends Controller {
  static targets = ["bell", "dot", "srdot", "item", "badge"]
  static values = { key: String }

  connect() {
    let seen = []
    try { seen = JSON.parse(localStorage.getItem(this.keyValue) || "[]") } catch (_) {}
    this.seenIds = new Set(seen)
    const unseen = this.itemTargets.filter((li) => !this.seenIds.has(li.dataset.id))
    unseen.forEach((li) => { const b = li.querySelector("[data-ss-whats-new-target='badge']"); if (b) b.hidden = false })
    this.dotTarget.hidden = unseen.length === 0
    this.srdotTarget.textContent = unseen.length ? `, ${unseen.length} não vistas` : ""
  }

  seen(event) {
    if (event.newState !== "open") return
    this.dotTarget.hidden = true
    this.srdotTarget.textContent = ""
    try { localStorage.setItem(this.keyValue, JSON.stringify(this.itemTargets.map((li) => li.dataset.id))) } catch (_) {}
  }
}
