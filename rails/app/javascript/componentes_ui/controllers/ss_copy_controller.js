import { Controller } from "@hotwired/stimulus"

// Copiar (Ss::QrCardComponent e afins): copia o texto e mostra "Copiado" por 2 s.
//   <div data-controller="ss-copy" data-ss-copy-text-value="…"><button data-action="ss-copy#copy" data-ss-copy-target="button">
export default class extends Controller {
  static targets = ["button", "label"]
  static values = { text: String, done: { type: String, default: "Copiado!" } }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
    } catch (_) {
      const input = this.element.querySelector("input")
      if (input) { input.select(); document.execCommand?.("copy") }
    }
    const label = this.hasLabelTarget ? this.labelTarget : null
    if (!label) return
    this.original ??= label.textContent
    label.textContent = this.doneValue
    this.element.classList.add("is-copied")
    clearTimeout(this.timer)
    this.timer = setTimeout(() => { label.textContent = this.original; this.element.classList.remove("is-copied") }, 2000)
  }

  select(event) { event.target.select() }
}
