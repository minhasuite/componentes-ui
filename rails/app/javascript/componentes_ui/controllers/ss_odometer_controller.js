import { Controller } from "@hotwired/stimulus"
import { inView } from "componentes_ui/controllers/ss_in_view_controller"
import { ssParseNumber } from "componentes_ui/controllers/ss_intl"

// Ss::OdometerComponent (v1.9, par do SsOdometer). Cada dígito é uma .ss-odo-col com o rolo 0–9 três vezes;
// --pos é a linha mostrada (em repouso, no 2º rolo: 10 + dígito). Subindo, o rolo vai para a frente (até o 3º
// rolo se der a volta); descendo, para trás (até o 1º). Assentou: volta ao 2º sem animar. --k é a casa contada
// da direita (atraso da cascata). Mudou data-ss-odometer-text-value: rola do texto antigo para o novo.
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches
const DIGIT = /\d/

export default class extends Controller {
  static targets = ["out", "sr"]
  static values = { text: String, rollIn: Boolean, separator: { type: String, default: "," } }

  connect() {
    this.shown = this.textValue
    if (this.rollInValue && !reduced()) {
      const zero = this.textValue.replace(/\d/g, "0")
      this.paint(zero, zero, false)
      this.shown = zero
      this.stop = inView(this.element, { onEnter: () => this.roll(this.shown, this.textValue) })
    }
  }

  disconnect() { this.stop?.(); clearTimeout(this.timer) }

  textValueChanged(value) {
    if (this.shown === undefined || value === this.shown) return
    if (this.hasSrTarget) this.srTarget.textContent = value
    this.roll(this.shown, value)
  }

  roll(from, to) {
    this.shown = to
    if (reduced()) return this.paint(to, to, false)
    this.paint(from, to, true)
  }

  split(text) {
    const i = text.lastIndexOf(this.separatorValue)
    if (i < 0 || !/^\d{2}(\D*)$/.test(text.slice(i + 1))) return [text, ""]
    return [text.slice(0, i) + text.slice(i + 3), text.slice(i, i + 3)]
  }

  // Monta o número `to`; com animate, cada casa parte do dígito de `from` na mesma casa (contada da direita).
  paint(from, to, animate) {
    if (!this.hasOutTarget) return
    const up = !(ssParseNumber(to) < ssParseNumber(from))
    const old = [...from].filter((c) => DIGIT.test(c)).reverse()
    const [main, cents] = this.split(to)
    let k = [...(main + cents)].filter((c) => DIGIT.test(c)).length
    const cols = []
    const build = (str, parent) => {
      for (const ch of str) {
        if (!DIGIT.test(ch)) { const s = document.createElement("span"); s.className = "ss-odo-ch"; s.textContent = ch; parent.append(s); continue }
        k--
        const col = document.createElement("span")
        col.className = "ss-odo-col"
        col.style.setProperty("--k", k)
        const reel = document.createElement("span")
        reel.className = "ss-odo-reel"
        reel.textContent = "0123456789".repeat(3)
        col.append(reel)
        const d = Number(ch), o = old[k]
        const start = o === undefined ? 10 + d : 10 + Number(o)
        let end = 10 + d
        if (o !== undefined && Number(o) !== d) end = up ? (d > Number(o) ? 10 + d : 20 + d) : (d < Number(o) ? 10 + d : d)
        col.style.setProperty("--pos", animate ? start : end)
        if (animate && o === undefined) col.classList.add("is-new")
        cols.push([col, end, d])
        parent.append(col)
      }
    }
    const out = this.outTarget
    out.textContent = ""
    build(main, out)
    if (cents) { const small = document.createElement("small"); small.className = "ss-odo-cents"; build(cents, small); out.append(small) }
    if (!animate) return
    void out.offsetWidth // o navegador pinta a partida antes de rolar
    this.element.classList.add("is-rolling")
    cols.forEach(([col, end]) => col.style.setProperty("--pos", end))
    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      this.element.classList.remove("is-rolling")
      cols.forEach(([col, , d]) => { col.style.setProperty("--pos", 10 + d); col.classList.remove("is-new") })
    }, 620 + 35 * cols.length)
  }
}
