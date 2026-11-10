import { Controller } from "@hotwired/stimulus"

// Ss::ChatActionComponent (v0.15): ao confirmar ou cancelar, os dois botões travam
// (aria-busy no cartão) até a resposta trocar o cartão pelo resultado.
export default class extends Controller {
  busy() {
    this.element.setAttribute("aria-busy", "true")
    requestAnimationFrame(() => this.element.querySelectorAll("button").forEach((b) => { b.disabled = true }))
  }
}
