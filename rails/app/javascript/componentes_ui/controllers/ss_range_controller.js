import { Controller } from "@hotwired/stimulus"

// Slider com o valor ao lado: atualiza o <output>, a parte preenchida (--p) e o aria-valuetext.
// Arrastando, marca data-dragging no input (o seletor cresce com mola e o valor ao lado também).
export default class extends Controller {
  static targets = ["input", "out"]
  static values = { format: { type: String, default: "%s" } }

  connect() {
    this.down = () => this.inputTarget.setAttribute("data-dragging", "")
    this.up = () => this.inputTarget.removeAttribute("data-dragging")
    this.inputTarget.addEventListener("pointerdown", this.down)
    ;["pointerup", "pointercancel", "lostpointercapture", "blur"].forEach((e) => this.inputTarget.addEventListener(e, this.up))
    window.addEventListener("pointerup", this.up)
  }

  disconnect() {
    this.inputTarget.removeEventListener("pointerdown", this.down)
    ;["pointerup", "pointercancel", "lostpointercapture", "blur"].forEach((e) => this.inputTarget.removeEventListener(e, this.up))
    window.removeEventListener("pointerup", this.up)
  }

  update() {
    const i = this.inputTarget
    const min = Number(i.min || 0), max = Number(i.max || 100)
    const p = max === min ? 0 : ((Number(i.value) - min) * 100) / (max - min)
    const text = this.formatValue.replace(/%[sd]/, i.value).replace("%%", "%")
    i.style.setProperty("--p", `${p}%`)
    i.setAttribute("aria-valuetext", text)
    if (this.hasOutTarget) this.outTarget.textContent = text
  }
}
