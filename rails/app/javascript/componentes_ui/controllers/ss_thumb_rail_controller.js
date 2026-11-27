import { Controller } from "@hotwired/stimulus"

// Ss::ThumbRailComponent (v1.10, par do SsThumbRail). As setas rolam uma miniatura (o lado + o espaço) e somem
// nas pontas (update, no scroll e ao ligar). select() marca a miniatura (aria-pressed), troca o src do <img
// id=target> e dispara ss-thumb-rail:select { index, src }; a escolhida entra inteira na coluna. ↑ ↓ andam o
// foco entre as miniaturas (um ponto de Tab). Reduzir movimento: rola sem animar.
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches
const behavior = () => (reduced() ? "auto" : "smooth")

export default class extends Controller {
  static targets = ["list", "item", "up", "down"]
  static values = { target: String }

  connect() {
    this.update()
    this.reveal(this.itemTargets.find((i) => i.getAttribute("aria-pressed") === "true" || i.hasAttribute("aria-current")), "auto")
  }

  get step() {
    const [a, b] = this.itemTargets
    return a && b ? b.offsetTop - a.offsetTop : (a?.offsetHeight || 64)
  }

  update() {
    if (!this.hasListTarget) return
    const l = this.listTarget
    this.upTarget.hidden = l.scrollTop <= 1
    this.downTarget.hidden = l.scrollTop >= l.scrollHeight - l.clientHeight - 1
  }

  up() { this.listTarget.scrollBy({ top: -this.step, behavior: behavior() }) }
  down() { this.listTarget.scrollBy({ top: this.step, behavior: behavior() }) }

  select(e) {
    const item = e.currentTarget
    if (item.getAttribute("aria-pressed") === "true") return
    this.itemTargets.forEach((i) => { i.setAttribute("aria-pressed", "false"); i.tabIndex = -1 })
    item.setAttribute("aria-pressed", "true")
    item.tabIndex = 0
    const img = this.targetValue && document.getElementById(this.targetValue)
    if (img) img.src = item.dataset.src
    this.reveal(item)
    this.dispatch("select", { detail: { index: Number(item.dataset.index), src: item.dataset.src } })
  }

  reveal(item, how = behavior()) {
    if (!item || !this.hasListTarget) return
    const l = this.listTarget
    const top = item.offsetTop // a lista é position: relative (o offsetParent)
    if (top < l.scrollTop || top + item.offsetHeight > l.scrollTop + l.clientHeight) {
      l.scrollTo({ top: top - (l.clientHeight - item.offsetHeight) / 2, behavior: how })
    }
  }

  key(e) {
    const items = this.itemTargets
    const i = items.indexOf(document.activeElement)
    const step = { ArrowDown: 1, ArrowUp: -1, ArrowRight: 1, ArrowLeft: -1 }[e.key]
    if (i < 0 || step === undefined) return
    e.preventDefault()
    const j = Math.min(items.length - 1, Math.max(0, i + step))
    items.forEach((x) => { x.tabIndex = -1 })
    items[j].tabIndex = 0
    items[j].focus()
    this.reveal(items[j])
  }
}
