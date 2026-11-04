import { Controller } from "@hotwired/stimulus"

// Atalhos de período: preenche De/Até e marca o atalho que bate com as datas.
export default class extends Controller {
  static targets = ["from", "to"]

  connect() { this.sync() }

  pick({ params: { range } }) {
    const [a, b] = this.compute(range)
    this.fromTarget.value = a; this.toTarget.value = b
    ;[this.fromTarget, this.toTarget].forEach((i) => i.dispatchEvent(new Event("change", { bubbles: true })))
  }

  sync() {
    const cur = `${this.fromTarget.value}|${this.toTarget.value}`
    this.element.querySelectorAll("[data-ss-date-range-range-param]").forEach((b) =>
      b.setAttribute("aria-pressed", this.compute(b.dataset.ssDateRangeRangeParam).join("|") === cur ? "true" : "false"))
    if (this.fromTarget.value) this.toTarget.min = this.fromTarget.value
  }

  compute(range) {
    const t = new Date(); t.setHours(12, 0, 0, 0)
    const iso = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`
    const y = t.getFullYear(), m = t.getMonth()
    switch (range) {
      case "today": return [iso(t), iso(t)]
      case "7d": { const a = new Date(t); a.setDate(t.getDate() - 6); return [iso(a), iso(t)] }
      case "month": return [iso(new Date(y, m, 1, 12)), iso(new Date(y, m + 1, 0, 12))]
      case "last_month": return [iso(new Date(y, m - 1, 1, 12)), iso(new Date(y, m, 0, 12))]
      default: return ["", ""]
    }
  }
}
