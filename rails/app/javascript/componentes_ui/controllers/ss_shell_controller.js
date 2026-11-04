import { Controller } from "@hotwired/stimulus"

// Moldura do Ss::AppShellComponent: recolhe o menu (desktop, lembrado), abre a
// gaveta (celular), fecha com Esc/fundo e abre a busca (.ss-command) com Ctrl+K.
// Os textos de recolher/expandir vêm do componente (I18n), não daqui.
// searchAction: id do <dialog> que a busca abre (sem ele, o 1º dialog.ss-command).
export default class extends Controller {
  static targets = ["side", "collapse", "burger"]
  static values = {
    searchAction: String,
    collapseLabel: { type: String, default: "Recolher menu" },
    expandLabel: { type: String, default: "Expandir menu" }
  }

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
      const label = on ? this.expandLabelValue : this.collapseLabelValue
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

  search(event) {
    // Ctrl+K com uma paleta ss-command de atalho na página: ela mesma abre (não abre duas vezes).
    if (event?.type === "keydown" && document.querySelector('[data-controller~="ss-command"][data-ss-command-shortcut-value]:not([data-ss-command-shortcut-value=""])')) return
    // O app pode tratar a busca do jeito dele (preventDefault no "ss-shell:search").
    const ev = this.dispatch("search", { cancelable: true, detail: { action: this.searchActionValue } })
    if (ev.defaultPrevented) return
    const dialog = this.searchActionValue ? document.getElementById(this.searchActionValue) : document.querySelector("dialog.ss-command")
    if (!dialog) return
    this.close()
    if (dialog.matches('[data-controller~="ss-command"]')) return dialog.dispatchEvent(new CustomEvent("ss-command:open"))
    if (dialog.open) return
    dialog.showModal()
    dialog.querySelector("input")?.focus()
  }
}
