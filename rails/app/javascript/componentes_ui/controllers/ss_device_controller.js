import { Controller } from "@hotwired/stimulus"

// Tile de aparelho com ⋯ (Ss::DeviceTileComponent more_url:, v0.10.3). O menu de contexto do
// tile (clique direito; toque longo no celular) segue o ⋯, como o onLongPress do app. Dentro
// de um campo ou do próprio ⋯, o menu do navegador continua.
export default class extends Controller {
  static targets = ["more"]

  more(e) {
    if (!this.hasMoreTarget || e.target.closest("input, textarea, select, .ss-device-more, .ss-device-foot")) return
    e.preventDefault()
    navigator.vibrate?.(15)
    this.moreTarget.click()
  }
}
