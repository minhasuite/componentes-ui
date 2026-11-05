import { Controller } from "@hotwired/stimulus"

// Envia o formulário sozinho um pouco depois de parar de digitar ou ao mudar um campo
// (v0.10.2): filtro que vai ao servidor, testador ao vivo. delay 0 envia na hora.
//   <form data-controller="ss-autosubmit" data-action="input->ss-autosubmit#queue change->ss-autosubmit#now">
export default class extends Controller {
  static values = { delay: { type: Number, default: 400 } }

  queue() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.submit(), this.delayValue)
  }

  now() {
    clearTimeout(this.timer)
    this.submit()
  }

  submit() {
    const form = this.element.tagName === "FORM" ? this.element : this.element.closest("form")
    form?.requestSubmit()
  }

  disconnect() { clearTimeout(this.timer) }
}
