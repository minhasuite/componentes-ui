import { Controller } from "@hotwired/stimulus"

// Campos que aparecem conforme a escolha de um <select> (v0.23.4): o formulário que muda pelo tipo
// (tipo de card, ação de um gesto), sem CSS nem JS do produto.
//   <div data-controller="ss-reveal">
//     <select data-ss-reveal-target="source" data-action="change->ss-reveal#update">…</select>
//     <div data-ss-reveal-for="tile button">só para tile e button</div>
//   </div>
// O item aparece quando o valor escolhido está na lista dele (separada por espaço) e some (hidden) nos
// outros casos. Cada controller só cuida dos itens que são dele: um ss-reveal dentro de outro (um bloco
// por gesto dentro do formulário do card) não se mistura. Sem source, nada some.
export default class extends Controller {
  static targets = ["source"]

  connect() { this.update() }

  update() {
    const source = this.sourceTargets.find((s) => s.closest("[data-controller~='ss-reveal']") === this.element)
    if (!source) return
    const value = source.value
    this.element.querySelectorAll("[data-ss-reveal-for]").forEach((el) => {
      if (el.parentElement?.closest("[data-controller~='ss-reveal']") !== this.element) return
      el.hidden = !el.dataset.ssRevealFor.split(/\s+/).includes(value)
    })
  }
}
