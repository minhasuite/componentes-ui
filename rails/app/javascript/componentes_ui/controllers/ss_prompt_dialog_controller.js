import { Controller } from "@hotwired/stimulus"

// Ss::PromptDialogComponent: pergunta de um campo só. Abre por qualquer
// [data-ss-prompt-open="<id>"] (data-ss-prompt-value troca o valor inicial) ou por JS:
//   document.getElementById(id).ssPrompt({ value, title }).then((texto) => …) // null = cancelou
// Com url (form de verdade) o envio segue normal (Turbo); sem url, a promessa recebe o texto.
let opener = null

export default class extends Controller {
  static targets = ["input", "ok", "title"]
  static values = { required: { type: Boolean, default: true } }

  connect() {
    this.initial = this.inputTarget.value
    this.defaultTitle = this.titleTarget.textContent
    this.element.ssPrompt = (opts = {}) => this.open(opts)
    if (!opener) {
      opener = (e) => {
        const btn = e.target.closest("[data-ss-prompt-open]")
        if (!btn) return
        const dlg = document.getElementById(btn.dataset.ssPromptOpen)
        if (!dlg?.ssPrompt) return
        e.preventDefault()
        dlg.ssPrompt({ value: btn.dataset.ssPromptValue })
      }
      document.addEventListener("click", opener)
    }
  }

  disconnect() {
    delete this.element.ssPrompt
    this.settle(null)
  }

  open({ value, title } = {}) {
    this.settle(null)
    this.inputTarget.value = value ?? this.initial
    this.titleTarget.textContent = title ?? this.defaultTitle
    this.sync()
    if (!this.element.open) this.element.showModal()
    this.inputTarget.focus()
    this.inputTarget.select()
    return new Promise((resolve) => { this.resolver = resolve })
  }

  sync() {
    if (this.requiredValue) this.okTarget.disabled = this.inputTarget.value.trim() === ""
  }

  submit(e) {
    const text = this.inputTarget.value.trim()
    if (this.requiredValue && !text) { e.preventDefault(); return }
    if (this.element.querySelector("form[method=dialog]")) {
      e.preventDefault()
      this.settle(text)
      this.element.close("ok")
    } else {
      this.settle(text) // form de verdade: o Turbo envia
    }
  }

  cancel() { this.element.close("cancel") }

  closed() { this.settle(null) }

  backdrop(e) { if (e.target === this.element) this.element.close("cancel") }

  settle(answer) {
    const r = this.resolver
    this.resolver = null
    r?.(answer)
  }
}
