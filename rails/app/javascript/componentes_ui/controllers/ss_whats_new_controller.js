import { Controller } from "@hotwired/stimulus"
import { ssFormat } from "componentes_ui/controllers/ss_intl"

// Novidades (Ss::WhatsNewComponent): ponto no sino e selo "novo" nos itens que a
// pessoa ainda não viu; abrir o painel marca tudo como visto no navegador.
export default class extends Controller {
  static targets = ["bell", "dot", "srdot", "item", "badge"]
  static values = { key: String, unseenLabel: { type: String, default: ", %{count} não vistas" } }

  connect() {
    let seen = []
    try { seen = JSON.parse(localStorage.getItem(this.keyValue) || "[]") } catch (_) {}
    this.seenIds = new Set(seen)
    const unseen = this.itemTargets.filter((li) => !this.seenIds.has(li.dataset.id))
    unseen.forEach((li) => { const b = li.querySelector("[data-ss-whats-new-target='badge']"); if (b) b.hidden = false })
    this.dotTarget.hidden = unseen.length === 0
    this.srdotTarget.textContent = unseen.length ? ssFormat(this.unseenLabelValue, { count: unseen.length }) : ""
  }

  seen(event) {
    if (event.newState !== "open") return
    this.dotTarget.hidden = true
    this.srdotTarget.textContent = ""
    try { localStorage.setItem(this.keyValue, JSON.stringify(this.itemTargets.map((li) => li.dataset.id))) } catch (_) {}
  }
}
