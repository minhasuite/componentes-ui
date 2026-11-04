import { Controller } from "@hotwired/stimulus"

// Marca no menu (a[href="#id"]) a seção que está na tela (Ss::SettingsLayoutComponent).
export default class extends Controller {
  connect() {
    this.links = [...this.element.querySelectorAll('nav a[href^="#"]')]
    const sections = this.links.map((a) => document.getElementById(a.hash.slice(1))).filter(Boolean)
    if (!sections.length || !("IntersectionObserver" in window)) return
    this.io = new IntersectionObserver((entries) => {
      const seen = entries.filter((e) => e.isIntersecting).sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0]
      if (seen) this.mark(seen.target.id)
    }, { rootMargin: "-10% 0px -60% 0px" })
    sections.forEach((s) => this.io.observe(s))
  }

  disconnect() { this.io?.disconnect() }

  mark(id) {
    this.links.forEach((a) => (a.hash === `#${id}` ? a.setAttribute("aria-current", "true") : a.removeAttribute("aria-current")))
  }
}
