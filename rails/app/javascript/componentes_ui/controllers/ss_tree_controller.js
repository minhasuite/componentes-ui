import { Controller } from "@hotwired/stimulus"

// Árvore (Ss::TreeViewComponent): ↑ ↓ entre os itens visíveis, → abre/entra,
// ← fecha/sobe para o pai, Home/End.
export default class extends Controller {
  key(event) {
    const item = event.target.closest("[data-ss-tree-item]")
    if (!item) return
    const items = this.visible()
    const i = items.indexOf(item)
    const details = item.tagName === "SUMMARY" ? item.parentElement : null
    let next = null
    switch (event.key) {
      case "ArrowDown": next = items[i + 1]; break
      case "ArrowUp": next = items[i - 1]; break
      case "Home": next = items[0]; break
      case "End": next = items[items.length - 1]; break
      case "ArrowRight":
        if (details && !details.open) details.open = true
        else if (details) next = items[i + 1]
        break
      case "ArrowLeft":
        if (details && details.open) details.open = false
        else next = (details ? details.parentElement.closest("details") : item.closest("details"))?.querySelector(":scope > summary")
        break
      default: return
    }
    event.preventDefault()
    if (next) next.focus()
  }

  visible() {
    return [...this.element.querySelectorAll("[data-ss-tree-item]")].filter((el) => el.offsetParent !== null || el.getClientRects().length)
  }
}
