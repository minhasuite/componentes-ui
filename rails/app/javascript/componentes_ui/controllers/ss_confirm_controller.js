import { Controller } from "@hotwired/stimulus"

// Exclusão confirmada (Ss::ConfirmDangerComponent): o botão só libera quando o
// texto digitado é igual ao nome (sem diferença de maiúsculas e espaços nas pontas).
// Enter com o nome errado balança o campo (não envia); o botão "destrava" com mola (CSS).
export default class extends Controller {
  static targets = ["dialog", "input", "submit"]
  static values = { name: String }

  open() {
    this.dialogTarget.showModal()
    this.inputTarget.focus()
  }

  close() { this.dialogTarget.close() }

  check() {
    const ok = this.inputTarget.value.trim().toLocaleLowerCase("pt-BR") === this.nameValue.trim().toLocaleLowerCase("pt-BR")
    this.submitTarget.disabled = !ok
  }

  // Enter com o botão travado: um "não" curto no campo.
  guard(event) {
    if (!this.submitTarget.disabled) return
    event.preventDefault()
    if (matchMedia("(prefers-reduced-motion: reduce)").matches || !this.inputTarget.animate) return
    this.inputTarget.animate([{ transform: "translateX(0)" }, { transform: "translateX(-7px)" }, { transform: "translateX(6px)" },
                              { transform: "translateX(-4px)" }, { transform: "translateX(2px)" }, { transform: "translateX(0)" }],
                             { duration: 380, easing: "ease-out" })
  }

  reset() {
    this.inputTarget.value = ""
    this.submitTarget.disabled = true
  }
}
