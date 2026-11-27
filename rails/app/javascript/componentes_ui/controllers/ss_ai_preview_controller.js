import { Controller } from "@hotwired/stimulus"

// v1.13.0 (Ss::AiActionPreviewComponent, par do SsAiActionPreview): a contagem "2 de 3 marcadas" ao vivo, marcar e
// desmarcar todas e o Aplicar travado (com a frase) quando nenhuma alteração está marcada.
export default class extends Controller {
  static targets = ["box", "count", "apply", "none"]
  static values = { template: String, total: Number }

  connect() { this.update() }

  all() { this.set(true) }
  none() { this.set(false) }

  set(on) {
    this.boxTargets.forEach((b) => { b.checked = on })
    this.update()
  }

  update() {
    const n = this.boxTargets.filter((b) => b.checked).length
    if (this.hasCountTarget) this.countTarget.textContent = this.templateValue.replace("%{count}", n).replace("%{total}", this.totalValue)
    if (this.hasApplyTarget) this.applyTarget.disabled = n === 0
    if (this.hasNoneTarget) this.noneTarget.hidden = n !== 0
    this.dispatch("change", { prefix: "ss-ai-preview", detail: { selected: this.boxTargets.filter((b) => b.checked).map((b) => b.value) } })
  }
}
