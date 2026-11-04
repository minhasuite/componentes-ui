import { Controller } from "@hotwired/stimulus"
import { reduced } from "componentes_ui/controllers/ss_motion_controller"

// Dias da semana (Ss::WeekdayPickerComponent): os atalhos marcam um conjunto de uma vez e ficam
// pressionados (aria-pressed) enquanto a escolha bate com eles. Sem JS os atalhos ficam
// escondidos e as bolinhas (checkboxes) funcionam sozinhas.
export default class extends Controller {
  static targets = ["day", "shortcuts"]

  connect() {
    if (this.hasShortcutsTarget) this.shortcutsTarget.hidden = false
    this.sync()
  }

  apply(e) {
    const want = new Set(e.currentTarget.dataset.days.split(","))
    this.dayTargets.forEach((d) => {
      const on = want.has(d.value)
      if (d.checked === on) return
      d.checked = on
      d.dispatchEvent(new Event("change", { bubbles: true }))
      if (!reduced()) d.nextElementSibling?.animate([{ scale: 0.8 }, { scale: 1.12 }, { scale: 1 }], { duration: 360, easing: "ease-out" })
    })
    this.sync()
  }

  sync() {
    if (!this.hasShortcutsTarget) return
    const on = this.dayTargets.filter((d) => d.checked).map((d) => d.value).sort().join(",")
    this.shortcutsTarget.querySelectorAll("button[data-days]").forEach((b) => {
      b.setAttribute("aria-pressed", String(b.dataset.days.split(",").sort().join(",") === on))
    })
  }
}
