import { Controller } from "@hotwired/stimulus"
import { haptic } from "componentes_ui/controllers/ss_haptics_controller"

// v1.14.0 · Ss::SelectionBarComponent (par do SsSelectable + SsSelectionBar): as caixas dos itens
// ([data-ss-selection-target=item] ou .ss-select-item) e a barra que sobe com a mola (.is-in) quando há marcados.
// Shift + clique marca/desmarca o intervalo desde o último clicado; a caixa "todos" ([data-ss-selection-target=all])
// marca a página e fica indeterminada no meio; Esc limpa. O contador rola no odômetro (data-ss-odometer-text-value).
// As ações: <form> recebe um campo `name` por id marcado no envio; link leva os ids na query.
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

export default class extends Controller {
  static targets = ["item", "all", "bar", "count", "word"]
  static values = { name: { type: String, default: "ids[]" }, one: String, many: String }

  connect() {
    this.onClick = (e) => {
      const box = e.target.closest?.("input[type=checkbox]")
      if (!box || !this.element.contains(box)) return
      if (this.isAll(box)) return this.toggleAll(box.checked)
      if (!this.items.includes(box)) return
      if (e.shiftKey && this.last && this.last !== box) {
        const a = this.items.indexOf(this.last), b = this.items.indexOf(box)
        this.items.slice(Math.min(a, b), Math.max(a, b) + 1).forEach((i) => { i.checked = box.checked })
      }
      this.last = box
      haptic("selection")
      this.update()
    }
    this.onKey = (e) => { if (e.key === "Escape" && this.ids.length) { e.preventDefault(); this.clear() } }
    this.element.addEventListener("click", this.onClick)
    this.element.addEventListener("keydown", this.onKey)
    this.update(true)
  }

  disconnect() {
    this.element.removeEventListener("click", this.onClick)
    this.element.removeEventListener("keydown", this.onKey)
    clearTimeout(this.hideTimer)
  }

  get items() {
    return [...this.element.querySelectorAll("input[type=checkbox][data-ss-selection-target=item], input[type=checkbox].ss-select-item")]
      .filter((i) => !i.disabled)
  }

  isAll(box) { return box.matches("[data-ss-selection-target=all]") }
  get ids() { return this.items.filter((i) => i.checked).map((i) => i.value) }

  toggleAll(on) {
    this.items.forEach((i) => { i.checked = on })
    haptic("selection")
    this.update()
  }

  clear() {
    this.items.forEach((i) => { i.checked = false })
    this.last = null
    this.update()
  }

  update(initial = false) {
    const ids = this.ids
    const n = ids.length
    this.items.forEach((i) => (i.closest("li, tr, .ss-item") || i.closest("label"))?.classList.toggle("is-selected", i.checked))
    if (this.hasAllTarget) {
      this.allTarget.checked = n > 0 && n === this.items.length
      this.allTarget.indeterminate = n > 0 && n < this.items.length
    }
    // Saindo, a barra mostra o último número (e não "0 selecionados"), como no app.
    if (n > 0 && this.hasCountTarget) this.countTarget.setAttribute("data-ss-odometer-text-value", String(n))
    if (n > 0 && this.hasWordTarget) this.wordTarget.textContent = n === 1 ? this.oneValue : this.manyValue
    this.toggleBar(n > 0, initial)
    this.dispatch("change", { detail: { ids, count: n } })
  }

  toggleBar(on, initial) {
    if (!this.hasBarTarget) return
    const bar = this.barTarget
    clearTimeout(this.hideTimer)
    if (on) {
      bar.hidden = false
      bar.classList.remove("is-out")
      return
    }
    if (bar.hidden) return
    if (initial || reduced()) { bar.hidden = true; return }
    bar.classList.add("is-out")
    this.hideTimer = setTimeout(() => { bar.hidden = true; bar.classList.remove("is-out") }, 300)
  }

  // Envio de uma ação: um campo escondido por id marcado (os antigos saem antes).
  fill(e) {
    const form = e.target
    form.querySelectorAll("input[data-ss-selection-id]").forEach((i) => i.remove())
    this.ids.forEach((id) => {
      const input = document.createElement("input")
      Object.assign(input, { type: "hidden", name: this.nameValue, value: id })
      input.dataset.ssSelectionId = ""
      form.append(input)
    })
  }

  follow(e) {
    const a = e.currentTarget
    const url = new URL(a.getAttribute("href"), location.href)
    url.searchParams.delete(this.nameValue)
    this.ids.forEach((id) => url.searchParams.append(this.nameValue, id))
    a.setAttribute("href", url.pathname + url.search + url.hash)
  }
}
