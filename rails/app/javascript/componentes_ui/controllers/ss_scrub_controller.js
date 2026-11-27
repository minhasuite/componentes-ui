import { Controller } from "@hotwired/stimulus"
import { haptic } from "componentes_ui/controllers/ss_haptics_controller"

// v1.14.0 · gráfico que se arrasta (par do SsScrubDetector / `scrub:` do SsLineChart e do SsBarChart): o
// marcador segue o dedo ou o mouse, o balão mostra o rótulo e os valores do ponto, vibra (selection) a cada
// ponto novo e avisa a tela com o evento `ss-scrub:change` { index, label } (index null ao soltar), para o
// resto da página acompanhar. Teclado: ← → Home End no gráfico focado (com aviso ao leitor de tela).
//
//   <figure data-controller="ss-scrub" data-ss-scrub-points-value='[[x%, y%, "rótulo", [["nome", "cor", "texto"]]], …]'>
//     <div class="ss-scrub-plot" data-ss-scrub-target="plot" tabindex="0">…svg…</div>
//   </figure>
//
// Os outros gráficos (ss-chart da área, ss-time-chart) usam o scrubTick daqui para a mesma vibração e o mesmo
// evento.
export function scrubTick(el, index, detail = {}) {
  haptic("selection")
  el.dispatchEvent(new CustomEvent("ss-scrub:change", { bubbles: true, detail: { index, ...detail } }))
}

const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c])

export default class extends Controller {
  static targets = ["plot", "live"]
  static values = { points: Array }

  connect() {
    if (!this.hasPlotTarget) return
    this.index = null
    const mk = (cls) => { const e = document.createElement("span"); e.className = cls; e.hidden = true; e.setAttribute("aria-hidden", "true"); this.plotTarget.append(e); return e }
    this.cursor = mk("ss-scrub-cursor")
    this.dot = mk("ss-scrub-dot")
    this.tip = mk("ss-scrub-tip")
    this.on = {
      down: (e) => { if (e.pointerType !== "mouse") this.touching = true; this.move(e) },
      move: (e) => { if (e.pointerType === "mouse" || this.touching) this.move(e) },
      up: (e) => { if (e.pointerType !== "mouse") { this.touching = false; this.hide() } },
      leave: (e) => { if (e.pointerType === "mouse") this.hide() },
      key: (e) => this.key(e),
      blur: () => this.hide()
    }
    const p = this.plotTarget
    p.addEventListener("pointerdown", this.on.down)
    p.addEventListener("pointermove", this.on.move)
    p.addEventListener("pointerup", this.on.up)
    p.addEventListener("pointercancel", this.on.up)
    p.addEventListener("pointerleave", this.on.leave)
    p.addEventListener("keydown", this.on.key)
    p.addEventListener("blur", this.on.blur)
  }

  disconnect() {
    if (!this.on) return
    const p = this.plotTarget
    p.removeEventListener("pointerdown", this.on.down)
    p.removeEventListener("pointermove", this.on.move)
    p.removeEventListener("pointerup", this.on.up)
    p.removeEventListener("pointercancel", this.on.up)
    p.removeEventListener("pointerleave", this.on.leave)
    p.removeEventListener("keydown", this.on.key)
    p.removeEventListener("blur", this.on.blur)
    ;[this.cursor, this.dot, this.tip].forEach((e) => e?.remove())
  }

  move(e) {
    const r = this.plotTarget.getBoundingClientRect()
    if (!r.width || !this.pointsValue.length) return
    const fx = ((e.clientX - r.left) / r.width) * 100
    let best = 0
    this.pointsValue.forEach((p, i) => { if (Math.abs(p[0] - fx) < Math.abs(this.pointsValue[best][0] - fx)) best = i })
    this.select(best)
  }

  key(e) {
    const last = this.pointsValue.length - 1
    const cur = this.index ?? -1
    const map = { ArrowRight: Math.min(last, cur + 1), ArrowLeft: Math.max(0, cur < 0 ? last : cur - 1), Home: 0, End: last }
    if (!(e.key in map)) return
    e.preventDefault()
    this.select(map[e.key], true)
  }

  select(i, announce = false) {
    if (i === this.index && !announce) return
    const [x, y, label, rows] = this.pointsValue[i]
    const changed = i !== this.index
    this.index = i
    this.cursor.hidden = this.tip.hidden = false
    this.cursor.style.left = `${x}%`
    this.dot.hidden = y == null
    if (y != null) { this.dot.style.left = `${x}%`; this.dot.style.top = `${y}%`; this.dot.style.setProperty("--c", rows[0]?.[1] || "var(--accent)") }
    this.tip.innerHTML = `<b>${esc(label)}</b>${rows.map(([n, c, t]) => `<span><i style="background:${esc(c)}"></i>${n ? `<em>${esc(n)}</em>` : ""}<strong class="num">${esc(t)}</strong></span>`).join("")}`
    this.tip.style.left = `${Math.min(Math.max(x, 12), 88)}%`
    this.element.classList.add("is-scrubbing")
    if (announce && this.hasLiveTarget) this.liveTarget.textContent = [label, ...rows.map(([n, , t]) => `${n} ${t}`.trim())].join(", ")
    if (changed) scrubTick(this.element, i, { label })
  }

  hide() {
    if (this.index == null) return
    this.index = null
    this.cursor.hidden = this.dot.hidden = this.tip.hidden = true
    this.element.classList.remove("is-scrubbing")
    this.element.dispatchEvent(new CustomEvent("ss-scrub:change", { bubbles: true, detail: { index: null } }))
  }
}
