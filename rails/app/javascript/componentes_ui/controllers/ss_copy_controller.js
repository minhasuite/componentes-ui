import { Controller } from "@hotwired/stimulus"

// Copiar (Ss::QrCardComponent e afins): copia o texto e mostra "Copiado" por 2 s.
//   <div data-controller="ss-copy" data-ss-copy-text-value="…"><button data-action="ss-copy#copy" data-ss-copy-target="button">
// v0.10.2: sem text-value, copia o target "source" (o value do input/textarea, ou o texto do
// elemento): <input readonly data-ss-copy-target="source" data-action="focus->ss-copy#select">.
// O texto do label volta sozinho; .is-copied fica 2 s no elemento do controller.
export default class extends Controller {
  static targets = ["button", "label", "source"]
  static values = { text: String, done: { type: String, default: "Copiado!" } }

  get text() {
    if (this.textValue || !this.hasSourceTarget) return this.textValue
    const s = this.sourceTarget
    return "value" in s && s.tagName !== "BUTTON" ? s.value : s.textContent
  }

  async copy() {
    if (this.hasSourceTarget && this.sourceTarget.select) this.sourceTarget.select()
    try {
      await navigator.clipboard.writeText(this.text)
    } catch (_) {
      const input = this.hasSourceTarget ? this.sourceTarget : this.element.querySelector("input")
      if (input) { input.select(); document.execCommand?.("copy") }
    }
    const label = this.hasLabelTarget ? this.labelTarget : null
    if (label) {
      this.original ??= label.textContent
      label.textContent = this.doneValue
    }
    this.element.classList.add("is-copied")
    clearTimeout(this.timer)
    this.timer = setTimeout(() => { if (label) label.textContent = this.original; this.element.classList.remove("is-copied") }, 2000)
  }

  select(event) { event.target.select() }
}
