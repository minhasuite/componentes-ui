import { Controller } from "@hotwired/stimulus"

// Ss::VerticalSliderComponent (v1.10, par do SsVerticalSlider). O <input type=range> em pé (writing-mode no
// CSS) recebe arrasto, clique, setas e o leitor de tela; aqui só se copia o valor para o desenho: --f (0 a 1)
// no elemento, o texto do seletor e o aria-valuetext ("21,5°").
export default class extends Controller {
  static targets = ["input", "out"]
  static values = { suffix: String, precision: Number, locale: String }

  input() {
    const i = this.inputTarget
    const min = Number(i.min), max = Number(i.max), v = Number(i.value)
    this.element.style.setProperty("--f", max === min ? 0 : (v - min) / (max - min))
    const fmt = new Intl.NumberFormat(this.localeValue || undefined, { minimumFractionDigits: this.precisionValue, maximumFractionDigits: this.precisionValue })
    const text = fmt.format(v) + this.suffixValue
    if (this.hasOutTarget) this.outTarget.textContent = text
    i.setAttribute("aria-valuetext", text)
  }
}
