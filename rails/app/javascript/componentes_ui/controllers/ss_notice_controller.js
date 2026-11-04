import { Controller } from "@hotwired/stimulus"

// Aviso com ações (Ss::NoticeCardComponent, dismissible: true sem URL): o X tira o aviso da tela
// com uma saída curta e dispara "ss-notice:dismiss" (cancelável) para o app lembrar.
export default class extends Controller {
  dismiss() {
    const ev = this.dispatch("dismiss", { prefix: "ss-notice", cancelable: true })
    if (ev.defaultPrevented) return
    const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches
    if (reduce) return this.element.remove()
    this.element.classList.add("is-leaving")
    this.element.addEventListener("animationend", () => this.element.remove(), { once: true })
  }
}
