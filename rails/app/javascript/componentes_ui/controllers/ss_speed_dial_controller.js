import { Controller } from "@hotwired/stimulus"

// Ss::SpeedDialComponent (v0.18, par do SsSpeedDial): o botão flutuante abre a lista de ações acima
// dele. Abrir põe o foco na 1ª ação; ↑ ↓ Home End movem; Esc fecha e devolve o foco ao botão;
// clique fora, Tab para fora e escolher uma ação fecham. Antes do cache do Turbo, fecha (a página
// guardada não volta com a lista aberta).
export default class extends Controller {
  static targets = ["menu", "button", "item"]

  connect() {
    this.onOutside = (e) => { if (this.isOpen && !this.element.contains(e.target)) this.close() }
    this.onCache = () => this.close()
    document.addEventListener("click", this.onOutside)
    document.addEventListener("turbo:before-cache", this.onCache)
  }

  disconnect() {
    document.removeEventListener("click", this.onOutside)
    document.removeEventListener("turbo:before-cache", this.onCache)
  }

  get isOpen() { return !this.menuTarget.hidden }

  toggle(event) {
    event?.preventDefault()
    this.isOpen ? this.close({ focus: true }) : this.open()
  }

  open() {
    this.menuTarget.hidden = false
    this.element.classList.add("is-open")
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.focusItem(0)
    this.dispatch("open", { prefix: "ss-speed-dial" })
  }

  close({ focus = false } = {}) {
    if (!this.isOpen) return
    this.menuTarget.hidden = true
    this.element.classList.remove("is-open")
    this.buttonTarget.setAttribute("aria-expanded", "false")
    if (focus) this.buttonTarget.focus()
    this.dispatch("close", { prefix: "ss-speed-dial" })
  }

  // Escolheu uma ação: fecha (a ação do app e o link seguem).
  chosen() { this.close() }

  key(e) {
    if (!this.isOpen) return
    const items = this.itemTargets
    const i = items.indexOf(document.activeElement)
    if (e.key === "Escape") { e.preventDefault(); this.close({ focus: true }) }
    // A lista fica acima do botão: ↑ vai para longe do botão (o item de cima), ↓ volta.
    else if (e.key === "ArrowUp") { e.preventDefault(); this.focusItem(i <= 0 ? items.length - 1 : i - 1) }
    else if (e.key === "ArrowDown") { e.preventDefault(); this.focusItem(i < 0 || i >= items.length - 1 ? 0 : i + 1) }
    else if (e.key === "Home") { e.preventDefault(); this.focusItem(0) }
    else if (e.key === "End") { e.preventDefault(); this.focusItem(items.length - 1) }
  }

  // Foco saiu do componente (Tab): fecha.
  blur(e) {
    if (this.isOpen && e.relatedTarget && !this.element.contains(e.relatedTarget)) this.close()
  }

  focusItem(i) { this.itemTargets[i]?.focus() }
}
