import { Controller } from "@hotwired/stimulus"
import { formatter, langOf, renderAxis, escapeHtml } from "componentes_ui/controllers/ss_time_axis"

// Faixas de estado (Ss::StateBandsComponent): eixo do tempo no idioma da página,
// balão ao passar o mouse ou tocar num trecho e ← → Home End com o foco na faixa
// (o trecho é anunciado). A entrada (faixas da esquerda para a direita) é do CSS
// com o ss-in-view.
export default class extends Controller {
  static targets = ["bar", "axis", "tip", "live"]
  static values = { from: Number, to: Number, lang: String, timeZone: String }

  connect() {
    this.f = formatter(langOf(this.element, this.langValue), this.timeZoneValue || undefined)
    this.drawAxis()
    this.ro = new ResizeObserver(() => this.drawAxis())
    this.ro.observe(this.element)
  }

  disconnect() { this.ro?.disconnect() }

  drawAxis() {
    if (this.hasAxisTarget) renderAxis(this.axisTarget, this.fromValue, this.toValue, this.f)
  }

  segs(bar) { return [...bar.querySelectorAll("i[data-from]")].filter((s) => !s.hidden) }

  segAt(bar, clientX) {
    const r = bar.getBoundingClientRect()
    const t = this.fromValue + ((clientX - r.left) / r.width) * (this.toValue - this.fromValue)
    return this.segs(bar).find((s) => +s.dataset.from <= t && t < +s.dataset.to)
  }

  move(e) {
    if (e.pointerType === "touch") return
    this.show(e.currentTarget, this.segAt(e.currentTarget, e.clientX))
  }

  // Toque: abre o trecho; tocar no mesmo de novo fecha.
  tap(e) {
    if (e.pointerType === "mouse") return
    const s = this.segAt(e.currentTarget, e.clientX)
    this.show(e.currentTarget, s === this.current ? null : s)
  }

  leave(e) {
    if (e.type === "pointerleave" && e.pointerType === "touch") return
    this.show(null, null)
  }

  key(e) {
    const bar = e.currentTarget
    const list = this.segs(bar)
    if (!list.length) return
    const i = list.indexOf(this.current)
    const map = { ArrowRight: i + 1, ArrowLeft: i < 0 ? list.length - 1 : i - 1, Home: 0, End: list.length - 1 }
    if (e.key === "Escape") return this.show(null, null)
    if (!(e.key in map)) return
    e.preventDefault()
    const s = list[Math.max(0, Math.min(list.length - 1, map[e.key]))]
    this.show(bar, s)
    if (this.hasLiveTarget) this.liveTarget.textContent = this.plain(s)
  }

  plain(s) {
    const a = +s.dataset.from, b = +s.dataset.to
    return `${s.dataset.label}, ${this.f.when(a)} – ${this.f.hm(b)}, ${this.f.duration(b - a)}`
  }

  show(bar, s) {
    this.element.querySelectorAll("i.is-on").forEach((x) => x.classList.remove("is-on"))
    this.current = s
    if (!this.hasTipTarget) return
    if (!bar || !s) { this.tipTarget.hidden = true; return }
    s.classList.add("is-on")
    const a = +s.dataset.from, b = +s.dataset.to
    this.tipTarget.innerHTML = `<p><span class="ss-tc-key" data-tone="${s.dataset.tone}"></span>${escapeHtml(s.dataset.label)}</p>` +
      `<small class="num">${this.f.when(a)} – ${this.f.hm(b)} · ${this.f.duration(b - a)}</small>`
    this.tipTarget.hidden = false
    const root = this.element.getBoundingClientRect()
    const rs = s.getBoundingClientRect()
    const rb = bar.getBoundingClientRect()
    const w = this.tipTarget.offsetWidth
    const x = Math.max(0, Math.min(root.width - w, rs.left + rs.width / 2 - root.left - w / 2))
    this.tipTarget.style.left = `${x}px`
    this.tipTarget.style.top = `${rb.top - root.top - this.tipTarget.offsetHeight - 6}px`
  }
}
