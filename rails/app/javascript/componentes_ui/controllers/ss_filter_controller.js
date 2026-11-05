import { Controller } from "@hotwired/stimulus"

// Busca na própria lista, sem ir ao servidor (v0.10.2): esconde os itens cujo texto não tem
// todas as palavras digitadas, sem acento e sem caixa. Os escondidos continuam no formulário.
//   <div data-controller="ss-filter">
//     <input type="search" class="ss-input" data-ss-filter-target="input" data-action="input->ss-filter#apply keydown.esc->ss-filter#clear">
//     <li data-ss-filter-target="item" data-ss-filter-text="palavras extras">…</li>
//     <p data-ss-filter-target="empty" hidden>Nada encontrado</p>
//     <span data-ss-filter-target="count"></span>   ← quantos aparecem
// Grupo (data-ss-filter-target="group") some quando todos os itens dele somem.
const norm = (s) => (s || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()

export default class extends Controller {
  static targets = ["input", "item", "empty", "group", "count"]

  connect() { if (this.hasInputTarget && this.inputTarget.value) this.apply() }

  apply() {
    const words = norm(this.inputTarget.value).split(/\s+/).filter(Boolean)
    let shown = 0
    this.itemTargets.forEach((item) => {
      const extra = [...item.querySelectorAll("input[placeholder]")].map((i) => i.placeholder).join(" ")
      const text = norm(`${item.textContent} ${item.dataset.ssFilterText || ""} ${extra}`)
      const hit = words.every((w) => text.includes(w))
      item.style.display = hit ? "" : "none" // [hidden] perde para o display das listas
      if (hit) shown++
    })
    this.groupTargets.forEach((g) => {
      const items = this.itemTargets.filter((i) => g.contains(i))
      g.style.display = items.length && items.every((i) => i.style.display === "none") ? "none" : ""
    })
    if (this.hasEmptyTarget) this.emptyTarget.hidden = shown > 0
    if (this.hasCountTarget) this.countTarget.textContent = shown
    this.dispatch("filtered", { prefix: "ss-filter", detail: { shown, query: this.inputTarget.value } })
  }

  clear() {
    this.inputTarget.value = ""
    this.apply()
    this.inputTarget.focus()
  }
}
