import { Controller } from "@hotwired/stimulus"

// Marcar todos (v0.10.2): a caixa do cabeçalho marca ou desmarca as da coluna/grupo, e fica
// meio marcada quando só algumas estão. Várias colunas: data-ss-check-all-col-param.
//   <div data-controller="ss-check-all">
//     <input type="checkbox" data-action="ss-check-all#toggle" data-ss-check-all-col-param="alexa" data-ss-check-all-target="all">
//     <input type="checkbox" data-col="alexa" data-action="ss-check-all#sync"> …
export default class extends Controller {
  static targets = ["all"]

  connect() { this.sync() }

  boxes(col) {
    const sel = col ? `input[type=checkbox][data-col="${col}"]` : "input[type=checkbox]:not([data-ss-check-all-target])"
    return [...this.element.querySelectorAll(sel)].filter((b) => !b.disabled && !this.allTargets.includes(b))
  }

  toggle(e) {
    const col = e.params?.col || e.target.dataset.ssCheckAllColParam
    this.boxes(col).forEach((b) => {
      if (b.checked === e.target.checked) return
      b.checked = e.target.checked
      b.dispatchEvent(new Event("change", { bubbles: true }))
    })
    this.sync()
  }

  sync() {
    this.allTargets.forEach((all) => {
      const list = this.boxes(all.dataset.ssCheckAllColParam)
      const on = list.filter((b) => b.checked).length
      all.checked = list.length > 0 && on === list.length
      all.indeterminate = on > 0 && on < list.length
    })
  }
}
