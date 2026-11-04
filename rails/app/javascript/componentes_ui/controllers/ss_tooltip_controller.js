import { Controller } from "@hotwired/stimulus"

// Dica (Ss::TooltipComponent): liga aria-describedby no elemento focável de dentro;
// Esc esconde até o mouse/foco sair.
export default class extends Controller {
  static values = { id: String }

  connect() {
    const target = this.element.querySelector("a, button, input, select, textarea, [tabindex]") || this.element.firstElementChild
    if (target && target.getAttribute("role") !== "tooltip") target.setAttribute("aria-describedby", this.idValue)
  }

  hide() { this.element.classList.add("is-dismissed") }

  reset() { if (!this.element.matches(":hover, :focus-within")) this.element.classList.remove("is-dismissed") }
}
