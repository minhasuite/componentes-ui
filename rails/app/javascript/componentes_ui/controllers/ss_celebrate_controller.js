import { Controller } from "@hotwired/stimulus"
import { ssConfetti, ssCelebrationClaim } from "componentes_ui/controllers/ss_confetti_controller"

// Ss::CelebrateComponent (v1.9, par do SsCelebrate(kind:)): uma comemoração por sessão por tipo
// (sessionStorage "ss-celebrate:<tipo>"). goal e first_use: confete; streak: pulo e estouro em volta
// do conteúdo (.is-bursting, CSS). Sempre anuncia no aria-live. Com prefers-reduced-motion, só anuncia.
// auto: comemora ao conectar; senão pelo data-action="ss-celebrate#celebrate" ou o evento "ss:celebrate".
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

export default class extends Controller {
  static values = { kind: String, text: String, auto: { type: Boolean, default: true } }
  static targets = ["live"]

  connect() {
    this.onEvent = () => this.celebrate()
    this.element.addEventListener("ss:celebrate", this.onEvent)
    if (this.autoValue) this.celebrate()
  }

  disconnect() {
    this.element.removeEventListener("ss:celebrate", this.onEvent)
    clearTimeout(this.timer)
  }

  celebrate() {
    if (!ssCelebrationClaim(this.kindValue)) return
    if (this.hasLiveTarget) {
      this.liveTarget.textContent = ""
      requestAnimationFrame(() => { this.liveTarget.textContent = this.textValue })
    }
    this.element.setAttribute("data-celebrated", "")
    if (reduced()) return
    if (this.kindValue === "streak") {
      this.element.classList.remove("is-bursting")
      void this.element.offsetWidth
      this.element.classList.add("is-bursting")
      clearTimeout(this.timer)
      this.timer = setTimeout(() => this.element.classList.remove("is-bursting"), 900)
    } else {
      ssConfetti()
    }
  }
}
