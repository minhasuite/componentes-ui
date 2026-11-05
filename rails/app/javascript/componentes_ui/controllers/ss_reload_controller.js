import { Controller } from "@hotwired/stimulus"

// Recarrega sozinho a cada N ms (v0.10.2): num <turbo-frame src> recarrega o quadro (log ao
// vivo, widget); em qualquer outro elemento recarrega a página com morph (app instalando).
// Pausa com a aba escondida e recarrega ao voltar se já passou do tempo.
//   <turbo-frame id="log" src="/log" class="ss-live" data-controller="ss-reload" data-ss-reload-every-value="5000">
export default class extends Controller {
  static values = { every: { type: Number, default: 5000 } }

  connect() {
    this.last = Date.now()
    this.timer = setInterval(() => this.tick(), this.everyValue)
    this.onVisible = () => { if (!document.hidden && Date.now() - this.last >= this.everyValue) this.tick() }
    document.addEventListener("visibilitychange", this.onVisible)
  }

  disconnect() {
    clearInterval(this.timer)
    document.removeEventListener("visibilitychange", this.onVisible)
  }

  tick() {
    if (document.hidden) return
    this.last = Date.now()
    if (this.element.tagName === "TURBO-FRAME" && this.element.reload) this.element.reload()
    else if (window.Turbo) window.Turbo.visit(window.location.href, { action: "replace" })
    else window.location.reload()
  }
}
