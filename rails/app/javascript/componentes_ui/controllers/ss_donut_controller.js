import { Controller } from "@hotwired/stimulus"
import { inView } from "componentes_ui/controllers/ss_in_view_controller"

// Rosca (Ss::DonutChartComponent): passar o mouse/foco na legenda destaca a fatia;
// clicar fixa o destaque (aria-pressed) até clicar de novo. Ao aparecer (inView),
// as fatias varrem em cascata.
export default class extends Controller {
  static targets = ["slice", "key"]

  connect() { this.stop = inView(this.element) }
  disconnect() { this.stop?.() }

  peek(event) { this.highlight(event.currentTarget.dataset.index) }

  unpeek() { this.highlight(this.pinned ?? null) }

  toggle(event) {
    const i = event.currentTarget.dataset.index
    this.pinned = this.pinned === i ? null : i
    this.keyTargets.forEach((k) => k.setAttribute("aria-pressed", String(k.dataset.index === this.pinned)))
    this.highlight(this.pinned)
  }

  highlight(i) {
    if (i === null || i === undefined) delete this.element.dataset.active
    else this.element.dataset.active = i
    this.sliceTargets.forEach((s) => s.classList.toggle("is-active", s.dataset.index === i))
    this.keyTargets.forEach((k) => k.classList.toggle("is-active", k.dataset.index === i))
  }
}
