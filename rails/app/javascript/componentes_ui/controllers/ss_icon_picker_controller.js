import { Controller } from "@hotwired/stimulus"

// Seletor de ícone (Ss::IconPickerComponent): busca sem acento, escolha com clique ou teclado
// (setas andam na grade, Enter/Espaço escolhem) e o nome vai no input hidden (com "change").
const norm = (s) => s.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[-_]/g, " ").trim()

export default class extends Controller {
  static targets = ["input", "query", "empty"]

  get cells() { return [...this.element.querySelectorAll(".ss-iconpick-cell")] }
  get visible() { return this.cells.filter((c) => !c.hidden) }

  filter() {
    const q = norm(this.queryTarget.value)
    let n = 0
    for (const c of this.cells) {
      // "Sem ícone" só aparece sem busca.
      const show = q ? c.dataset.name !== "" && c.dataset.search.includes(q) : true
      c.hidden = !show
      if (show && c.dataset.name !== "") n++
    }
    const vazio = q && n === 0
    this.emptyTarget.hidden = !vazio
    if (vazio) this.emptyTarget.textContent = this.emptyTarget.dataset.template.replace("%{q}", this.queryTarget.value.trim())
  }

  pick(e) { this.select(e.currentTarget) }

  select(cell) {
    for (const c of this.cells) {
      c.setAttribute("aria-checked", c === cell)
      c.tabIndex = c === cell ? 0 : -1
    }
    this.inputTarget.value = cell.dataset.name
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  keydown(e) {
    const cells = this.visible
    const i = cells.indexOf(document.activeElement)
    if (i < 0) return
    // Colunas = quantas células estão na mesma linha da primeira.
    const cols = cells.filter((c) => c.offsetTop === cells[0].offsetTop).length || 1
    const step = { ArrowRight: 1, ArrowLeft: -1, ArrowDown: cols, ArrowUp: -cols, Home: -i, End: cells.length - 1 - i }[e.key]
    if (step === undefined) return
    e.preventDefault()
    const next = cells[Math.min(cells.length - 1, Math.max(0, i + step))]
    next.focus()
    this.select(next)
  }
}
