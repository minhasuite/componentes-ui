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
// v1.4.1: o source também pode ser um grupo de rádios (f.ss_radio_buttons com data: { ss_reveal_target: "source",
// action: "change->ss-reveal#update" }): vale o valor do marcado (nenhum marcado = "").
//   <%= f.ss_radio_buttons :kind, [["Numa loja", "store"], ["Na empresa toda", "period"]],
//                          data: { ss_reveal_target: "source", action: "change->ss-reveal#update" } %>
//   <div data-ss-reveal-for="store">…</div>
export default class extends Controller {
  static targets = ["source"]

  connect() { this.update() }

  update() {
    const own = this.sourceTargets.filter((s) => s.closest("[data-controller~='ss-reveal']") === this.element)
    if (!own.length) return
    const radios = own.filter((s) => s.type === "radio")
    const value = radios.length ? (radios.find((r) => r.checked)?.value ?? "") : own[0].value
    this.element.querySelectorAll("[data-ss-reveal-for]").forEach((el) => {
      if (el.parentElement?.closest("[data-controller~='ss-reveal']") !== this.element) return
      el.hidden = !el.dataset.ssRevealFor.split(/\s+/).includes(value)
    })
  }
}
