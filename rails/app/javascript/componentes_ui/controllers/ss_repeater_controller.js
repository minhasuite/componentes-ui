import { Controller } from "@hotwired/stimulus"

// Linhas repetíveis de formulário (v0.20, Ss::RepeaterComponent; par do SsRepeater).
// add: clona o <template> trocando o marcador (NEW_RECORD, padrão do accepts_nested_attributes_for)
// por um número único e põe a linha no fim da lista; o foco vai ao 1º campo dela.
// remove: linha que já existe no banco (tem input[name$="[_destroy]"]) é marcada _destroy=1 e
// escondida; linha nova sai do DOM. min: não deixa ficar menos linhas visíveis que isso.
// Eventos ss-repeater:add / ss-repeater:remove (detail: { row }).
export default class extends Controller {
  static targets = ["template", "list", "row", "live"]
  static values = { placeholder: { type: String, default: "NEW_RECORD" }, min: { type: Number, default: 0 }, added: String, removed: String }

  connect() { this.sync() }

  get visible() { return this.rowTargets.filter((r) => !r.hidden) }

  add(event) {
    event?.preventDefault()
    const id = `${Date.now()}${Math.floor(Math.random() * 1000)}`
    const html = this.templateTarget.innerHTML.replaceAll(this.placeholderValue, id)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    const row = this.listTarget.lastElementChild
    row?.querySelector("input:not([type=hidden]), select, textarea")?.focus()
    this.announce(this.addedValue)
    this.sync()
    this.dispatch("add", { prefix: "ss-repeater", detail: { row } })
  }

  remove(event) {
    event?.preventDefault()
    if (this.visible.length <= this.minValue) return
    const row = event.currentTarget.closest("[data-ss-repeater-target~='row']")
    if (!row) return
    const destroy = row.querySelector("input[name$='[_destroy]']")
    if (destroy) {
      destroy.value = "1"
      row.hidden = true
      row.querySelectorAll("[required]").forEach((el) => el.removeAttribute("required"))
    } else {
      row.remove()
    }
    this.announce(this.removedValue)
    this.sync()
    this.dispatch("remove", { prefix: "ss-repeater", detail: { row } })
    ;(this.visible.at(-1)?.querySelector("input:not([type=hidden]), select, textarea") || this.element.querySelector("[data-action*='ss-repeater#add']"))?.focus()
  }

  // O × some quando só sobram min linhas.
  sync() {
    const lock = this.visible.length <= this.minValue
    this.element.querySelectorAll("[data-action*='ss-repeater#remove']").forEach((b) => { b.hidden = lock })
  }

  announce(text) { if (this.hasLiveTarget && text) this.liveTarget.textContent = text }
}
