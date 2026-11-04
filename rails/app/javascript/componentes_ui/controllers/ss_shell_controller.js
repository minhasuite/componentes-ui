import { Controller } from "@hotwired/stimulus"

// Moldura do Ss::AppShellComponent: recolhe o menu (desktop, lembrado), abre a
// gaveta (celular), fecha com Esc/fundo e abre a busca (.ss-command) com Ctrl+K.
export default class extends Controller {
  static targets = ["side", "collapse", "burger"]

  connect() {
    let collapsed = false
    try { collapsed = localStorage.getItem("ss-shell-collapsed") === "1" } catch (_) {}
    this.setCollapsed(collapsed)
    this.closeOnVisit = () => this.close()
    document.addEventListener("turbo:visit", this.closeOnVisit)
  }

  disconnect() { document.removeEventListener("turbo:visit", this.closeOnVisit) }

  get mobile() { return matchMedia("(max-width: 1023px)").matches }

  toggle() {
    if (this.mobile) return this.close()
    this.setCollapsed(!this.element.hasAttribute("data-collapsed"))
    try { localStorage.setItem("ss-shell-collapsed", this.element.hasAttribute("data-collapsed") ? "1" : "0") } catch (_) {}
  }

  setCollapsed(on) {
    this.element.toggleAttribute("data-collapsed", on)
    if (this.hasCollapseTarget) {
      this.collapseTarget.setAttribute("aria-expanded", on ? "false" : "true")
      const label = on ? "Expandir menu" : "Recolher menu"
      this.collapseTarget.setAttribute("aria-label", label); this.collapseTarget.title = label
    }
  }

  open() {
    this.element.setAttribute("data-open", "")
    if (this.hasBurgerTarget) this.burgerTarget.setAttribute("aria-expanded", "true")
    this.sideTarget.querySelector("a, summary, button")?.focus()
  }

  close() {
    if (!this.element.hasAttribute("data-open")) return
    this.element.removeAttribute("data-open")
    if (this.hasBurgerTarget) { this.burgerTarget.setAttribute("aria-expanded", "false"); this.burgerTarget.focus() }
  }

  search() {
    const dialog = document.querySelector("dialog.ss-command")
    if (!dialog || dialog.open) return
    this.close()
    dialog.showModal()
    dialog.querySelector("input")?.focus()
  }
}
