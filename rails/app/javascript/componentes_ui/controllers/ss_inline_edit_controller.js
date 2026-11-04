import { Controller } from "@hotwired/stimulus"

// Edição no lugar: clicar no valor mostra o campo; Enter salva (form com Turbo), Esc cancela,
// sair do campo salva se mudou. Sem url (remote=false) só troca o texto e dispara ss-inline-edit:save.
export default class extends Controller {
  static targets = ["view", "text", "form", "input"]
  static values = { remote: Boolean }

  edit() {
    this.original = this.inputTarget.value
    this.viewTarget.hidden = true
    this.formTarget.hidden = false
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  key(e) {
    if (e.key === "Escape") { e.preventDefault(); this.cancel() }
  }

  blur() {
    if (this.saving || this.formTarget.hidden) return
    if (this.inputTarget.value === this.original) this.cancel()
    else this.formTarget.requestSubmit()
  }

  cancel() {
    this.inputTarget.value = this.original ?? this.inputTarget.value
    this.element.classList.remove("is-invalid")
    this.close()
  }

  submit(e) {
    const value = this.inputTarget.value
    if (value === this.original) { e.preventDefault(); return this.close() }
    if (!this.remoteValue) {
      e.preventDefault()
      this.apply(value)
      this.dispatch("save", { detail: { value } })
      return
    }
    this.saving = true
    this.element.setAttribute("aria-busy", "true")
  }

  done(e) {
    this.saving = false
    this.element.removeAttribute("aria-busy")
    if (e.detail.success) { this.element.classList.remove("is-invalid"); this.apply(this.inputTarget.value) }
    else { this.element.classList.add("is-invalid"); this.inputTarget.focus() }
  }

  apply(value) {
    this.textTarget.textContent = value
    const label = this.inputTarget.getAttribute("aria-label")
    this.viewTarget.setAttribute("aria-label", `Editar ${label}: ${value}`)
    this.original = value
    this.close()
  }

  close() {
    this.formTarget.hidden = true
    this.viewTarget.hidden = false
    this.viewTarget.focus()
  }
}
