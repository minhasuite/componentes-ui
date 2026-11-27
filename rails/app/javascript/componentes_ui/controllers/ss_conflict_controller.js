import { Controller } from "@hotwired/stimulus"

// v1.13.0 (Ss::ConflictResolverComponent, par do SsConflictResolver): "Ficar com a minha"/"Ficar com a do servidor"
// marcam o mesmo lado (data-side do botão) em todos os campos.
export default class extends Controller {
  all(e) {
    const side = e.currentTarget.dataset.side
    this.element.querySelectorAll(`input[type=radio][value="${side}"]`).forEach((r) => { r.checked = true })
    this.dispatch("change", { prefix: "ss-conflict", detail: { side } })
  }
}
