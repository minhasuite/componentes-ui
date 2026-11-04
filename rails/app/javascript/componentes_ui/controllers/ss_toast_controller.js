import { Controller } from "@hotwired/stimulus"

// Aviso da pilha (Ss::ToastComponent): some sozinho, pausa com o mouse/foco,
// fecha no ×. O anel do .ss-toast-timer pausa junto (animation-play-state).
// Movimento: entra com mola (CSS); arrastar para o lado segue o dedo e, passado
// o limite (ou num peteleco), sai voando; senão volta com mola. Quando um aviso
// entra ou sai, os vizinhos deslizam para o lugar novo (FLIP) em vez de pular.
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches
const SPRING = "cubic-bezier(.34, 1.56, .64, 1)"
const spring = () => {
  const v = getComputedStyle(document.documentElement).getPropertyValue("--ss-bounce").trim()
  return v && CSS.supports("transition-timing-function", v) ? v : SPRING
}
const lastTop = new WeakMap() // aviso → último top medido (para o FLIP)

// Desliza os avisos de `stack` da posição antiga para a nova.
function reflow(stack, skip) {
  if (!stack) return
  const toasts = [...stack.children].filter((t) => t.classList.contains("ss-toast") && t !== skip)
  toasts.forEach((t) => {
    const top = t.getBoundingClientRect().top
    const before = lastTop.get(t)
    lastTop.set(t, top)
    if (before === undefined || reduced() || Math.abs(before - top) < 1 || !t.animate) return
    t.animate([{ transform: `translateY(${before - top}px)` }, { transform: "translateY(0)" }], { duration: 480, easing: spring(), composite: "add" })
  })
}

export default class extends Controller {
  static targets = ["timer"]
  static values = { duration: { type: Number, default: 5000 }, sticky: Boolean }

  connect() {
    this.stack = this.element.parentElement
    lastTop.set(this.element, this.element.getBoundingClientRect().top)
    reflow(this.stack, this.element)
    this.onDown = (e) => this.down(e)
    this.element.addEventListener("pointerdown", this.onDown)
    if (this.stickyValue) return
    this.left = this.durationValue
    this.resume()
  }

  disconnect() {
    clearTimeout(this.timeout)
    clearInterval(this.tick)
    this.element.removeEventListener("pointerdown", this.onDown)
  }

  pause() {
    if (this.stickyValue || !this.started) return
    clearTimeout(this.timeout)
    clearInterval(this.tick)
    this.left -= Date.now() - this.started
    this.started = null
    this.element.classList.add("is-paused")
  }

  resume() {
    if (this.stickyValue || this.started || this.dragging) return
    this.element.classList.remove("is-paused")
    this.started = Date.now()
    this.timeout = setTimeout(() => this.close(), Math.max(this.left, 0))
    if (this.hasTimerTarget) {
      this.tick = setInterval(() => {
        const s = Math.ceil((this.left - (Date.now() - this.started)) / 1000)
        this.timerTarget.textContent = Math.max(s, 0)
      }, 250)
    }
  }

  close() {
    if (this.closing) return
    this.closing = true
    clearTimeout(this.timeout)
    clearInterval(this.tick)
    if (reduced()) return this.remove()
    this.element.classList.add("is-leaving")
    this.element.addEventListener("animationend", () => this.remove(), { once: true })
    setTimeout(() => this.remove(), 400)
  }

  remove() {
    if (!this.element.isConnected) return
    const stack = this.stack
    this.element.remove()
    reflow(stack)
  }

  // ── Arrastar para dispensar ──
  down(e) {
    if (e.button !== 0 || e.target.closest("a, button, input, form") || reduced() || this.closing) return
    this.dragging = true
    this.x0 = e.clientX
    this.dx = 0
    this.samples = [[e.timeStamp, e.clientX]]
    this.pause()
    this.element.setPointerCapture(e.pointerId)
    this.element.classList.add("is-dragging")
    this.onMove = (ev) => this.move(ev)
    this.onUp = (ev) => this.up(ev)
    this.element.addEventListener("pointermove", this.onMove)
    this.element.addEventListener("pointerup", this.onUp)
    this.element.addEventListener("pointercancel", this.onUp)
  }

  move(e) {
    this.dx = e.clientX - this.x0
    this.samples.push([e.timeStamp, e.clientX])
    if (this.samples.length > 5) this.samples.shift()
    const w = this.element.offsetWidth
    // Para a esquerda (para dentro da tela) resiste; para a direita segue o dedo.
    const x = this.dx < 0 ? this.dx * 0.35 : this.dx
    this.element.style.transform = `translateX(${x}px) rotate(${(x / w) * 4}deg)`
    this.element.style.opacity = String(Math.max(0.2, 1 - Math.abs(x) / (w * 1.1)))
  }

  up() {
    this.element.removeEventListener("pointermove", this.onMove)
    this.element.removeEventListener("pointerup", this.onUp)
    this.element.removeEventListener("pointercancel", this.onUp)
    this.element.classList.remove("is-dragging")
    this.dragging = false
    const [t0, x0] = this.samples[0]
    const [t1, x1] = this.samples[this.samples.length - 1]
    const v = (x1 - x0) / Math.max(t1 - t0, 1) // px/ms
    const w = this.element.offsetWidth
    const from = { transform: this.element.style.transform || "none", opacity: this.element.style.opacity || 1 }
    this.element.style.transform = ""
    this.element.style.opacity = ""
    if (Math.abs(this.dx) < 3) return this.resume()
    if (this.dx > w * 0.35 || v > 0.5 || this.dx < -w * 0.6 || v < -0.9) {
      // Peteleco: sai voando no sentido do gesto.
      const dir = this.dx + v * 100 < 0 ? -1 : 1
      this.closing = true
      clearTimeout(this.timeout)
      const a = this.element.animate([from, { transform: `translateX(${dir * (w + 80)}px) rotate(${dir * 6}deg)`, opacity: 0 }],
                                     { duration: 220, easing: "cubic-bezier(.2, .6, .4, 1)", fill: "forwards" })
      a.finished.then(() => this.remove(), () => this.remove())
    } else {
      // Não passou do limite: volta com mola.
      this.element.animate([from, { transform: "none", opacity: 1 }], { duration: 520, easing: spring() })
      this.resume()
    }
  }
}
