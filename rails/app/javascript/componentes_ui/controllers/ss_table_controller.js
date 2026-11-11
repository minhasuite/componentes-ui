import { Controller } from "@hotwired/stimulus"

// Tabela de dados (Ss::DataTableComponent): densidade e colunas escondidas lembradas
// no navegador (chave "ss-table:<id>"), seleção em massa com a barra flutuante e
// linha expansível. v0.20: linha clicável (row_href:): clique na linha (fora de link, botão, campo,
// <summary>/<details> e da seleção de texto) ou Enter com o foco nela vai ao data-href; Ctrl/⌘ ou o
// botão do meio abrem em outra aba. Navega pelo Turbo quando ele existe.
export default class extends Controller {
  static targets = ["all", "check", "bar", "count"]
  static values = { key: String }

  connect() {
    const saved = this.load()
    if (saved.density) this.applyDensity(saved.density)
    this.hidden = new Set(saved.hidden || [])
    this.applyHidden()
    this.sync()
  }

  density({ params }) {
    this.applyDensity(params.density)
    this.save()
  }

  applyDensity(value) {
    this.element.dataset.density = value
    this.element.querySelectorAll("[data-ss-table-density-param]").forEach((b) =>
      b.setAttribute("aria-pressed", String(b.dataset.ssTableDensityParam === value)))
  }

  toggleColumn(event) {
    const key = event.target.dataset.colToggle
    event.target.checked ? this.hidden.delete(key) : this.hidden.add(key)
    this.applyHidden()
    this.save()
  }

  applyHidden() {
    this.element.querySelectorAll("[data-col]").forEach((el) => el.classList.toggle("is-hidden", this.hidden.has(el.dataset.col)))
    this.element.querySelectorAll("[data-col-toggle]").forEach((el) => { el.checked = !this.hidden.has(el.dataset.colToggle) })
  }

  toggleAll(event) {
    this.checkTargets.forEach((c) => { c.checked = event.target.checked })
    this.sync()
  }

  toggleRow() { this.sync() }

  clear() {
    this.checkTargets.forEach((c) => { c.checked = false })
    this.sync()
  }

  sync() {
    const n = this.checkTargets.filter((c) => c.checked).length
    this.checkTargets.forEach((c) => c.closest("tr")?.classList.toggle("is-selected", c.checked))
    if (this.hasAllTarget) {
      this.allTarget.checked = n > 0 && n === this.checkTargets.length
      this.allTarget.indeterminate = n > 0 && n < this.checkTargets.length
    }
    if (this.hasCountTarget) this.countTarget.textContent = n
    if (this.hasBarTarget) this.barTarget.hidden = n === 0
  }

  expand(event) {
    const button = event.currentTarget
    const open = button.getAttribute("aria-expanded") !== "true"
    button.setAttribute("aria-expanded", String(open))
    const row = document.getElementById(button.getAttribute("aria-controls"))
    if (row) row.hidden = !open
  }

  go(event) {
    const row = event.currentTarget
    if (event.type === "keydown") {
      if (event.key !== "Enter" || event.target !== row) return
    } else {
      if (event.target.closest("a, button, input, select, textarea, label, summary, details, [role=button], [data-ss-table-no-link]")) return
      if (window.getSelection?.().toString()) return
    }
    const href = row.dataset.href
    if (!href) return
    if (event.ctrlKey || event.metaKey || event.button === 1) { window.open(href, "_blank", "noopener"); return }
    if (window.Turbo?.visit) window.Turbo.visit(href, row.dataset.turboFrame ? { frame: row.dataset.turboFrame } : {})
    else window.location.assign(href)
  }

  load() {
    try { return JSON.parse(localStorage.getItem(`ss-table:${this.keyValue}`) || "{}") } catch (_) { return {} }
  }

  save() {
    try {
      localStorage.setItem(`ss-table:${this.keyValue}`, JSON.stringify({ density: this.element.dataset.density, hidden: [...this.hidden] }))
    } catch (_) {}
  }
}
