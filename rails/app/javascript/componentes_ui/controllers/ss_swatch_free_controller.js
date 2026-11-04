import { Controller } from "@hotwired/stimulus"

// Ficha "Personalizada" do Ss::SwatchPickerComponent(free: true): o <input type=color>
// cobre a ficha; ao escolher, o radio passa a valer o hex e fica marcado (o change
// borbulha para o form e para o anel do ss-indicator). Teclado: Enter/Espaço no radio
// marcado abre o seletor.
export default class extends Controller {
  static targets = ["radio", "color"]

  connect() {
    this.onKey = (e) => {
      if ((e.key === "Enter" || e.key === " ") && this.radioTarget.checked) {
        e.preventDefault()
        if (this.colorTarget.showPicker) this.colorTarget.showPicker(); else this.colorTarget.click()
      }
    }
    this.radioTarget.addEventListener("keydown", this.onKey)
  }

  disconnect() { this.radioTarget.removeEventListener("keydown", this.onKey) }

  pick() {
    const hex = this.colorTarget.value
    this.element.style.setProperty("--c", hex)
    this.element.classList.add("is-set")
    this.radioTarget.value = hex
    if (!this.radioTarget.checked) {
      this.radioTarget.checked = true
      this.radioTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }
}
