import { Controller } from "@hotwired/stimulus"

// Ajuda da moldura (Ss::HelpMenuComponent): ao abrir "Novidades" (em outra aba), apaga o ponto do botão e o selo
// "2 novas" desta página na hora, sem esperar recarregar (quem grava o "visto" é o servidor, no link). Qualquer
// linha que abre fora fecha o popover.
export default class extends Controller {
  static targets = ["button", "dot", "badge", "panel"]
  static values = { label: String }

  seen() {
    this.dotTargets.forEach((d) => d.remove())
    this.badgeTargets.forEach((b) => b.remove())
    if (this.hasButtonTarget && this.labelValue) this.buttonTarget.setAttribute("aria-label", this.labelValue)
    this.close()
  }

  close() {
    if (!this.hasPanelTarget) return
    try { this.panelTarget.hidePopover() } catch (_) {}
  }
}
