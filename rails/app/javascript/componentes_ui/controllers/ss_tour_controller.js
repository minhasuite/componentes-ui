import { Controller } from "@hotwired/stimulus"

// Tour guiado (Ss::TourComponent): escurece a tela com recorte no alvo
// [data-tour-step="<target>"], balão com passo n/total; lembra que viu no navegador.
// Movimento: recorte e balão ficam em coordenadas da página (top/left com mola entre
// os passos) e a rolagem só desloca (--sx/--sy, sem transição): o foco pula de um
// alvo ao outro com mola enquanto a página rola, em vez de "perseguir" a rolagem.
export default class extends Controller {
  static targets = ["layer", "hole", "pop", "count", "title", "text", "next", "back", "skip"]
  static values = { key: String, steps: Array, autostart: Boolean }

  connect() {
    this.onResize = () => this.position()
    this.onScroll = (e) => (e.target === document || e.target === document.documentElement ? this.scrolled() : this.position())
    this.onKey = (e) => { if (e.key === "Escape") this.finish() }
    let seen = false
    try { seen = localStorage.getItem(this.keyValue) === "1" } catch (_) {}
    if (this.autostartValue && !seen) requestAnimationFrame(() => this.start())
  }

  disconnect() { this.teardown() }

  start() {
    this.steps = this.stepsValue.filter((s) => document.querySelector(`[data-tour-step="${s.target}"]`))
    if (!this.steps.length) return
    this.returnFocus = document.activeElement
    this.layerTarget.hidden = false
    this.layerTarget.classList.add("is-first")
    this.scrolled()
    addEventListener("resize", this.onResize)
    addEventListener("scroll", this.onScroll, true)
    document.addEventListener("keydown", this.onKey)
    this.show(0)
  }

  next() { this.index < this.steps.length - 1 ? this.show(this.index + 1) : this.finish() }
  prev() { if (this.index > 0) this.show(this.index - 1) }

  show(i) {
    this.index = i
    const step = this.steps[i]
    this.target = document.querySelector(`[data-tour-step="${step.target}"]`)
    const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches
    this.target.scrollIntoView({ block: "center", behavior: reduce ? "auto" : "smooth" })
    this.countTarget.textContent = `${i + 1} de ${this.steps.length}`
    this.titleTarget.textContent = step.title || ""
    this.textTarget.textContent = step.text || ""
    this.backTarget.hidden = i === 0
    this.nextTarget.textContent = i === this.steps.length - 1 ? "Concluir" : "Próximo"
    this.skipTarget.hidden = i === this.steps.length - 1
    this.position()
    setTimeout(() => this.position(), reduce ? 0 : 350)
    this.popTarget.focus({ preventScroll: true })
  }

  // Rolagem: só o deslocamento muda (sem mola), o recorte acompanha a página.
  scrolled() {
    if (!this.hasLayerTarget) return
    this.layerTarget.style.setProperty("--sx", scrollX)
    this.layerTarget.style.setProperty("--sy", scrollY)
  }

  position() {
    if (!this.target || this.layerTarget.hidden) return
    this.scrolled()
    const r = this.target.getBoundingClientRect()
    const pad = 8
    const sx = scrollX
    const sy = scrollY
    Object.assign(this.holeTarget.style, { top: `${r.top + sy - pad}px`, left: `${r.left + sx - pad}px`, width: `${r.width + pad * 2}px`, height: `${r.height + pad * 2}px` })
    const pop = this.popTarget
    const pw = pop.offsetWidth
    const ph = pop.offsetHeight
    let top = r.bottom + pad + 12
    if (top + ph > innerHeight - 12) top = Math.max(12, r.top - pad - 12 - ph)
    const left = Math.max(12, Math.min(r.left, innerWidth - pw - 12))
    Object.assign(pop.style, { top: `${top + sy}px`, left: `${left + sx}px` })
    // 1º passo: aparece no lugar (sem vir voando do canto); dali em diante, mola.
    if (this.layerTarget.classList.contains("is-first")) requestAnimationFrame(() => requestAnimationFrame(() => this.layerTarget.classList.remove("is-first")))
  }

  finish() {
    try { localStorage.setItem(this.keyValue, "1") } catch (_) {}
    this.teardown()
    this.returnFocus?.focus?.()
  }

  teardown() {
    if (this.hasLayerTarget) this.layerTarget.hidden = true
    removeEventListener("resize", this.onResize)
    removeEventListener("scroll", this.onScroll, true)
    document.removeEventListener("keydown", this.onKey)
  }
}
