import { Controller } from "@hotwired/stimulus"

// Controle remoto (Ss::DPadComponent): cada tecla dispara "ss-dpad:key" (detail: { key }); com
// url, o button_to também manda o formulário. Com foco no controle, setas, Enter e Esc apertam
// a tecla certa (o mesmo que clicar nela, com o afundar da mola). detail.value é o nome que o
// app deu à tecla (keys:) ou o do botão extra (extra_buttons:); sem isso, igual ao key.
const KEYS = { ArrowUp: "up", ArrowDown: "down", ArrowLeft: "left", ArrowRight: "right", Enter: "ok", Escape: "back" }

export default class extends Controller {
  press(e) {
    const key = e.currentTarget.dataset.key
    const value = e.currentTarget.dataset.value || key
    this.dispatch("key", { prefix: "ss-dpad", detail: { key, value } })
  }

  keydown(e) {
    const key = KEYS[e.key]
    // Enter num botão já clica nele; só a seta/Esc ou Enter no próprio controle passam por aqui.
    if (!key || (e.key === "Enter" && e.target !== this.element)) return
    const btn = this.element.querySelector(`[data-key="${key}"]`)
    if (!btn || btn.disabled) return
    e.preventDefault()
    btn.classList.add("is-pressed")
    setTimeout(() => btn.classList.remove("is-pressed"), 140)
    btn.click()
  }
}
