import { Controller } from "@hotwired/stimulus"
import { ssMoney, ssFormat } from "componentes_ui/controllers/ss_intl"

// Ss::SplitSliderComponent (v1.9, par do SsSplitSlider). Mexer num range: com locked, redistribui o resto entre os
// outros na proporção deles (a mesma conta do Ruby e do Flutter, em centavos, a soma fecha o total); sem locked,
// cada um anda livre e o rodapé diz quanto falta ou sobra. Atualiza o valor mostrado, o aria-valuetext, o
// preenchimento da trilha (--p) e o campo escondido. Vibra de leve ao cruzar uma marca.
export function redistribute(values, index, value, total) {
  const v = Math.max(0, Math.min(total, value))
  const out = [...values]
  out[index] = v
  const others = values.map((_, i) => i).filter((i) => i !== index)
  if (!others.length) { out[index] = total; return out }
  const rest = total - v
  const sum = others.reduce((s, i) => s + values[i], 0)
  let used = 0
  for (const i of others) {
    const part = sum === 0 ? Math.floor(rest / others.length) : Math.floor((values[i] * rest) / sum)
    out[i] = part
    used += part
  }
  const order = [...others].sort((a, b) => out[b] - out[a])
  for (let k = 0; used < rest; k++, used++) out[order[k % order.length]]++
  return out
}

export default class extends Controller {
  static targets = ["range", "out", "field", "foot"]
  static values = { total: Number, locked: Boolean, step: { type: Number, default: 100 }, currency: String, totalText: String, missing: String, over: String }

  connect() { this.values = this.rangeTargets.map((r) => Number(r.value)) }

  move(e) {
    const i = Number(e.target.dataset.index)
    const total = this.totalValue
    const cents = Math.min(total, Math.round(Number(e.target.value) / this.stepValue) * this.stepValue)
    const mark = total / 8
    if (Math.floor(cents / mark) !== Math.floor(this.values[i] / mark)) navigator.vibrate?.(4)
    this.values = this.lockedValue ? redistribute(this.values, i, cents, total) : this.values.map((v, j) => (j === i ? cents : v))
    this.paint()
  }

  money(c) { return ssMoney(c / 100, this.currencyValue || "BRL") }

  paint() {
    const total = this.totalValue
    this.values.forEach((v, i) => {
      const r = this.rangeTargets[i]
      if (Number(r.value) !== v) r.value = v
      r.setAttribute("aria-valuetext", this.money(v))
      r.style.setProperty("--p", `${total ? (v * 100) / total : 0}%`)
      if (this.outTargets[i]) this.outTargets[i].textContent = this.money(v)
      if (this.fieldTargets[i]) this.fieldTargets[i].value = v
    })
    if (!this.hasFootTarget) return
    const diff = total - this.values.reduce((s, v) => s + v, 0)
    let text = ssFormat(this.totalTextValue, { amount: this.money(total) })
    if (!this.lockedValue && diff !== 0) text += ` · ${ssFormat(diff > 0 ? this.missingValue : this.overValue, { amount: this.money(Math.abs(diff)) })}`
    this.footTarget.textContent = text
  }
}
