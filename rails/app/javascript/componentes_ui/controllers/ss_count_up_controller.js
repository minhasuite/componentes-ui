import { Controller } from "@hotwired/stimulus"
import { inView } from "componentes_ui/controllers/ss_in_view_controller"
import { ssNumber, ssMoney, ssParseNumber, ssSplitCents } from "componentes_ui/controllers/ss_intl"

// Número que conta ao entrar na tela (Ss::CountUpComponent). Menos movimento: fica no valor final.
// Trocar o valor (data-ss-count-up-value-value, por JS ou morph do Turbo) anima a troca:
// conta do valor antigo ao novo ou, com roll (data-ss-count-up-roll-value), rola os
// dígitos como caça-níquel e assenta com mola (sobe se aumentou, desce se caiu).
//
// Modo "vigia" (Ss::PriceBoardComponent): data-ss-count-up-watch-value="td.num" no
// container; quando o texto de uma célula muda (morph, stream, JS), ela rola.
//
// A rolagem também serve solta: import { ssRoll } from "componentes_ui/controllers/ss_count_up_controller"
//   ssRoll(el, "R$ 10,00", "R$ 12,50")   (dir: 1 sobe, -1 desce; sem dir, compara os números)

const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches
const SPRING_FALLBACK = "cubic-bezier(.34, 1.56, .64, 1)"
let springEasing = null
function spring() {
  if (springEasing) return springEasing
  const v = getComputedStyle(document.documentElement).getPropertyValue("--ss-bounce").trim()
  springEasing = v && CSS.supports("transition-timing-function", v) ? v : SPRING_FALLBACK
  return springEasing
}

// "R$ 1.234,50" → 1234.5 (NaN se não tem número), no formato do <html lang>.
export function parseNumber(text) {
  return ssParseNumber(text)
}

// Põe em `parent` o texto `to`, com as posições que mudaram (alinhadas pela direita) rolando.
function appendRolled(parent, from, to, dir, anims) {
  const n = Math.max(from.length, to.length)
  const a = from.padStart(n, "\u0000")
  const b = to.padStart(n, "\u0000")
  let changed = 0
  for (let i = 0; i < n; i++) {
    const oc = a[i] === "\u0000" ? "" : a[i]
    const nc = b[i] === "\u0000" ? "" : b[i]
    if (oc === nc) { if (nc) parent.append(nc); continue }
    const cell = document.createElement("span")
    cell.className = "ss-roll"
    const o = document.createElement("span")
    o.className = "ss-roll-old"
    o.textContent = oc
    const nw = document.createElement("span")
    nw.className = "ss-roll-new"
    nw.textContent = nc
    cell.append(o, nw)
    parent.append(cell)
    const delay = (n - 1 - i) * 35 // da direita para a esquerda, como um contador
    changed++
    anims.push(o.animate([{ transform: "translateY(0)", opacity: 1 }, { transform: `translateY(${-dir * 100}%)`, opacity: 0 }],
                         { duration: 260, delay, easing: "cubic-bezier(.4, 0, 1, 1)", fill: "both" }))
    anims.push(nw.animate([{ transform: `translateY(${dir * 100}%)`, opacity: 0 }, { transform: "translateY(0)", opacity: 1, offset: 0.35 }, { transform: "translateY(0)", opacity: 1 }],
                          { duration: 620, delay: delay + 40, easing: spring(), fill: "both" }))
  }
  return changed
}

// Rola o texto de `el` de `from` para `to`; `done` recebe o elemento ao assentar.
export function ssRoll(el, from, to, { dir, money = false, done } = {}) {
  from = String(from ?? "")
  to = String(to ?? "")
  const token = (el.__ssRoll = (el.__ssRoll || 0) + 1)
  const finish = () => { if (el.__ssRoll === token) done ? done(el) : (el.textContent = to) }
  if (reduced() || from === to || !el.animate) return finish()
  if (dir === undefined) { const d = parseNumber(to) - parseNumber(from); dir = d < 0 ? -1 : 1 }
  const anims = []
  el.textContent = ""
  if (money) {
    // Mantém os centavos menores: R$ 1.234<small>,56</small> (separador do idioma).
    const [fm, fc] = ssSplitCents(from)
    const [tm, tc, tt] = ssSplitCents(to)
    appendRolled(el, fm, tm, dir, anims)
    if (tc || fc) { const small = document.createElement("small"); appendRolled(small, fc, tc, dir, anims); el.append(small) }
    if (tt) el.append(tt)
  } else {
    appendRolled(el, from, to, dir, anims)
  }
  Promise.all(anims.map((a) => a.finished.catch(() => {}))).then(finish)
}

export default class extends Controller {
  static targets = ["out"]
  static values = { value: Number, decimals: Number, format: String, duration: { type: Number, default: 900 }, roll: Boolean, watch: String,
                    currency: { type: String, default: "BRL" } }

  connect() {
    if (this.watchValue) return this.watch()
    this.shown = this.valueValue
    if (reduced()) { this.started = true; return }
    this.paint(0)
    this.stop = inView(this.element, { onEnter: () => { this.started = true; this.run(0, this.valueValue) } })
  }

  disconnect() { this.stop?.(); this.observer?.disconnect(); cancelAnimationFrame(this.frame) }

  // Valor novo depois de começar: anima do que está na tela até ele.
  valueValueChanged(value, previous) {
    if (this.watchValue || !this.started || previous === undefined || value === this.shown) return
    const from = this.shown
    this.updateSr()
    if (reduced()) return this.paint(value)
    cancelAnimationFrame(this.frame)
    if (this.rollValue && this.hasOutTarget) {
      this.shown = value
      const el = this.outTarget.firstElementChild || this.outTarget
      ssRoll(el, this.format(from), this.format(value), { dir: value < from ? -1 : 1, money: this.formatValue === "money", done: () => this.paint(value) })
    } else {
      this.run(from, value, Math.min(this.durationValue, 700))
    }
  }

  run(from, to, duration = this.durationValue) {
    const start = performance.now()
    const step = (now) => {
      const t = Math.min(1, (now - start) / duration)
      const eased = 1 - Math.pow(1 - t, 3)
      this.paint(from + (to - from) * eased)
      if (t < 1) this.frame = requestAnimationFrame(step)
    }
    this.frame = requestAnimationFrame(step)
  }

  format(v) {
    // Intl com o idioma da página (pt-BR de reserva) e a moeda do componente.
    if (this.formatValue === "money") return ssMoney(v, this.currencyValue, undefined, this.decimalsValue)
    const n = ssNumber(v, this.decimalsValue)
    return this.formatValue === "percent" ? `${n}%` : n
  }

  paint(v) {
    this.shown = v
    if (!this.hasOutTarget) return
    const el = this.outTarget.firstElementChild || this.outTarget
    const text = this.format(v)
    if (this.formatValue === "money") {
      const [main, cents, tail] = ssSplitCents(text)
      el.innerHTML = ""
      el.append(main)
      if (cents) { const small = document.createElement("small"); small.textContent = cents; el.append(small) }
      if (tail) el.append(tail)
    } else {
      el.textContent = text
    }
  }

  updateSr() {
    const sr = this.element.querySelector(":scope > .ss-sr")
    if (sr) sr.textContent = this.format(this.valueValue)
  }

  // Modo vigia: cada célula que trocar de texto rola do antigo para o novo.
  watch() {
    const cells = () => this.element.querySelectorAll(this.watchValue)
    const last = new WeakMap()
    cells().forEach((c) => last.set(c, c.textContent))
    this.observer = new MutationObserver(() => {
      cells().forEach((c) => {
        if (c.dataset.rolling === "1") return
        const now = c.textContent
        const before = last.get(c)
        last.set(c, now)
        if (before === undefined || before === now) return
        c.dataset.rolling = "1"
        ssRoll(c, before, now, { done: (el) => { el.textContent = now; delete el.dataset.rolling } })
      })
    })
    this.observer.observe(this.element, { subtree: true, childList: true, characterData: true })
  }
}
