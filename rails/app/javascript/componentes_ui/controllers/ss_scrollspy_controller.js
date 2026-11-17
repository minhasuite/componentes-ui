import { Controller } from "@hotwired/stimulus"

// Marca no menu (a[href="#id"]) a seção que está na tela (Ss::SettingsLayoutComponent).
// v1.4.1: a seção atual é a última cujo topo já passou da linha de leitura (30% da altura da janela, no máximo
// 200 px); no fim da página, a última. Antes valia a primeira seção visível numa faixa, e a de cima, ainda com a
// borda à vista, ganhava da que estava no meio da tela (ex.: recarregar em #vendas marcava "Plano").
// Recarregar com a âncora (#secao) marca a dela; clicar no menu marca na hora.
export default class extends Controller {
  connect() {
    this.links = [...this.element.querySelectorAll('nav a[href^="#"]')]
    this.sections = this.links.map((a) => document.getElementById(decodeURIComponent(a.hash.slice(1)))).filter(Boolean)
    if (!this.sections.length) return
    this.queue = this.queue.bind(this)
    this.pick = this.pick.bind(this)
    document.addEventListener("scroll", this.queue, { capture: true, passive: true })
    window.addEventListener("resize", this.queue)
    this.links.forEach((a) => a.addEventListener("click", this.pick))
    const fromHash = this.sections.find((s) => `#${s.id}` === decodeURIComponent(location.hash))
    if (fromHash) {
      this.mark(fromHash.id)
      this.hold()
    } else {
      this.update()
    }
  }

  disconnect() {
    document.removeEventListener("scroll", this.queue, { capture: true })
    window.removeEventListener("resize", this.queue)
    this.links?.forEach((a) => a.removeEventListener("click", this.pick))
    cancelAnimationFrame(this.frame)
  }

  // Clique no menu: marca já e espera a rolagem (suave) assentar antes de voltar a seguir a tela.
  pick(e) {
    const id = decodeURIComponent(e.currentTarget.hash.slice(1))
    if (!this.sections.some((s) => s.id === id)) return
    this.mark(id)
    this.hold()
  }

  hold() { this.heldUntil = performance.now() + 900 }

  queue() {
    if (this.frame) return
    this.frame = requestAnimationFrame(() => {
      this.frame = null
      if (performance.now() < (this.heldUntil || 0)) return
      this.update()
    })
  }

  update() {
    const line = Math.min(window.innerHeight * 0.3, 200)
    const doc = document.documentElement
    const atEnd = window.innerHeight + window.scrollY >= doc.scrollHeight - 2
    let current = this.sections[0]
    if (atEnd && doc.scrollHeight > window.innerHeight) current = this.sections[this.sections.length - 1]
    else this.sections.forEach((s) => { if (s.getBoundingClientRect().top <= line) current = s })
    this.mark(current.id)
  }

  mark(id) {
    this.links.forEach((a) => (a.hash === `#${id}` || decodeURIComponent(a.hash) === `#${id}` ? a.setAttribute("aria-current", "true") : a.removeAttribute("aria-current")))
  }
}
