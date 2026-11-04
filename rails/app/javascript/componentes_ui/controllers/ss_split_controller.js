import { Controller } from "@hotwired/stimulus"
import { ssMoney } from "componentes_ui/controllers/ss_intl"

// Divisão que soma 100%: mexer num slider redistribui o resto nos outros, na proporção deles.
export default class extends Controller {
  static targets = ["slider", "out", "seg"]
  // currency: moeda do componente; o valor sai no idioma do <html lang>.
  static values = { total: Number, currency: { type: String, default: "BRL" } }

  connect() { this.exact = this.sliderTargets.map((s) => Number(s.value)) }

  // Guarda as partes sem arredondar (this.exact) para os passos pequenos não acumularem erro.
  move(e) {
    const i = this.sliderTargets.indexOf(e.target)
    const idx = this.exact.map((_, n) => n).filter((n) => n !== i)
    const v = Number(e.target.value)
    if (!idx.length) return this.render([100])
    const rest = 100 - v
    const sum = idx.reduce((a, n) => a + this.exact[n], 0)
    idx.forEach((n) => { this.exact[n] = sum > 0 ? (this.exact[n] * rest) / sum : rest / idx.length })
    this.exact[i] = v
    // inteiros que somam 100: piso + sobra pelo maior resto
    const next = this.exact.map((x, n) => (n === i ? v : Math.floor(x)))
    let left = 100 - next.reduce((a, b) => a + b, 0)
    idx.map((n) => [n, this.exact[n] - Math.floor(this.exact[n])]).sort((a, b) => b[1] - a[1])
      .forEach(([n]) => { if (left > 0) { next[n]++; left-- } })
    this.render(next)
  }

  render(vals) {
    vals.forEach((v, n) => {
      const s = this.sliderTargets[n]
      s.value = v; s.style.setProperty("--p", `${v}%`); s.setAttribute("aria-valuetext", `${v}%`)
      if (this.segTargets[n]) this.segTargets[n].style.width = `${v}%`
      const out = this.outTargets[n]
      if (out) {
        out.querySelector("b").textContent = `${v}%`
        const small = out.querySelector("small")
        if (small && this.totalValue) small.textContent = ssMoney(Math.round((this.totalValue * v) / 100) / 100, this.currencyValue)
      }
    })
    this.dispatch("change", { detail: { values: vals } })
  }
}
