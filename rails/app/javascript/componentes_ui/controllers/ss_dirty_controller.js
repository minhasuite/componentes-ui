import { Controller } from "@hotwired/stimulus"

// Formulário "sujo": fica no Ss::StickyActionBarComponent (dentro do <form>).
// Compara o form com o estado inicial; com alteração, marca form[data-dirty]
// (a barra aparece) e avisa antes de sair da página (navegador e Turbo).
// Cancelar (data-action="ss-dirty#reset") volta ao inicial; enviar libera a saída.
export default class extends Controller {
  static values = { message: { type: String, default: "Há alterações não salvas. Sair mesmo assim?" } }

  connect() {
    this.form = this.element.closest("form")
    if (!this.form) return
    this.initial = this.snapshot()
    this.check = () => this.update()
    this.leaving = (e) => { if (this.dirty) { e.preventDefault(); e.returnValue = "" } }
    this.visiting = (e) => { if (this.dirty && !confirm(this.messageValue)) e.preventDefault() }
    this.submitted = () => { this.dirty = false }
    this.form.addEventListener("input", this.check)
    this.form.addEventListener("change", this.check)
    this.form.addEventListener("submit", this.submitted)
    window.addEventListener("beforeunload", this.leaving)
    document.addEventListener("turbo:before-visit", this.visiting)
  }

  disconnect() {
    if (!this.form) return
    this.form.removeEventListener("input", this.check)
    this.form.removeEventListener("change", this.check)
    this.form.removeEventListener("submit", this.submitted)
    window.removeEventListener("beforeunload", this.leaving)
    document.removeEventListener("turbo:before-visit", this.visiting)
  }

  snapshot() {
    const data = new FormData(this.form)
    return JSON.stringify([...data.entries()].filter(([k]) => k !== "authenticity_token").map(([k, v]) => [k, v instanceof File ? v.name : v]))
  }

  update() { this.dirty = this.snapshot() !== this.initial }

  get dirty() { return this.form.hasAttribute("data-dirty") }
  set dirty(on) {
    this.form.toggleAttribute("data-dirty", on)
    this.element.toggleAttribute("data-visible", on)
  }

  reset(event) {
    event?.preventDefault()
    this.form.reset()
    this.dirty = false
  }
}
