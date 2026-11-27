import { Controller } from "@hotwired/stimulus"

// v1.14.0 · Ss::ExpandableRowComponent (par do SsExpandableRow): "Editar" abre o painel embaixo da linha (a altura
// anima no CSS: .is-open troca grid-template-rows 0fr → 1fr), tira o inert e põe o foco no 1º campo; Esc ou
// Cancelar desfazem o digitado (form.reset), fecham e devolvem o foco ao "Editar". Salvou (turbo:submit-end com
// sucesso): fecha e diz "Salvo" ao leitor de tela. Evento ss-expandable-row:toggle { open } a cada troca.
const FIELD = "input:not([type=hidden]):not([disabled]), select:not([disabled]), textarea:not([disabled]), [contenteditable=true]"

export default class extends Controller {
  static targets = ["panel", "toggle", "status"]
  static values = { saved: String }

  toggle() { this.element.classList.contains("is-open") ? this.close() : this.open() }

  open() {
    this.set(true)
    const first = this.panelTarget.querySelector(FIELD)
    first?.focus({ preventScroll: true })
    if (first?.select && first.type !== "checkbox" && first.type !== "radio") first.select?.()
  }

  close({ focus = true } = {}) {
    if (!this.element.classList.contains("is-open")) return
    this.set(false)
    if (focus) this.toggleTarget.focus({ preventScroll: true })
  }

  cancel() {
    this.panelTarget.querySelector("form")?.reset()
    this.close()
  }

  key(e) {
    if (e.key !== "Escape") return
    e.preventDefault()
    e.stopPropagation()
    this.cancel()
  }

  saved(e) {
    if (!e.detail?.success) return
    this.close()
    if (this.hasStatusTarget) this.statusTarget.textContent = this.savedValue
  }

  set(open) {
    this.element.classList.toggle("is-open", open)
    this.toggleTarget.setAttribute("aria-expanded", String(open))
    this.panelTarget.inert = !open
    this.dispatch("toggle", { detail: { open } })
  }
}
