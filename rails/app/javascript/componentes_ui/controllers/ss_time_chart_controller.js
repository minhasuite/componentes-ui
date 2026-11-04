import { Controller } from "@hotwired/stimulus"
import { inView } from "componentes_ui/controllers/ss_in_view_controller"
import { formatter, langOf, ticks, niceRange, valueAt, renderAxis, placeSegments, escapeHtml } from "componentes_ui/controllers/ss_time_axis"

// Gráfico de séries no tempo (Ss::TimeSeriesChartComponent). Desenha o SVG no tamanho
// real (redesenha ao mudar de tamanho), com números e datas pelo Intl no idioma da página.
// - Mouse em cima (ou dedo): cursor, um ponto por série e balão com o horário, o valor de
//   cada série e o estado de cada faixa. No toque, tocar fixa e tocar de novo solta.
// - Arrastar com o mouse marca um trecho e aproxima; duplo clique ou "Ver tudo" volta.
//   Com zoom-url, pede a janela ao servidor pelo Turbo (turbo-frame em volta, o
//   zoom-frame ou uma visita).
// - Legenda: botões aria-pressed ligam e desligam a série (o eixo Y se ajusta).
// - Teclado no gráfico: ← → andam no tempo, Home End, + aproxima, 0 ou - volta, Esc solta.
// - Entrada: as linhas se desenham da esquerda para a direita quando entram na tela.
const NS = "http://www.w3.org/2000/svg"
const TOP = 14
const BOTTOM = 4

export default class extends Controller {
  static targets = ["stage", "plot", "svg", "axis", "cursor", "brush", "tip", "reset", "key", "live", "bands"]
  static values = { series: Array, from: Number, to: Number, mode: String, dual: Boolean, zoomUrl: String, zoomFrame: String,
                    resetUrl: String, lang: String, empty: String }

  connect() {
    this.f = formatter(langOf(this.element, this.langValue))
    this.hidden = new Set()
    this.win = [this.fromValue, this.toValue]
    // Veio aproximado do servidor (zoomed: true): o "Ver tudo" fica e leva ao reset-url.
    this.serverZoomed = !this.resetTarget.hidden
    this.uid = `tc${Math.random().toString(36).slice(2, 8)}`
    this.render()
    this.ro = new ResizeObserver(() => { if (this.stageTarget.clientWidth !== this.w) this.render() })
    this.ro.observe(this.stageTarget)
    // Depois da entrada, redesenhos (legenda, zoom, tamanho) não animam de novo.
    this.stop = inView(this.element, { onEnter: () => setTimeout(() => this.element.setAttribute("data-drawn", ""), 1000) })
  }

  disconnect() { this.ro?.disconnect(); this.stop?.() }

  // ── conta ─────────────────────────────────────────────────────────
  modeOf(s) { return s.mode || this.modeValue || "line" }
  x(t) { return ((t - this.win[0]) / (this.win[1] - this.win[0])) * this.w }

  axes() {
    const vis = this.seriesValue.map((_, i) => i).filter((i) => !this.hidden.has(i))
    const units = [...new Set(vis.map((i) => this.seriesValue[i].unit || ""))]
    const groups = this.dualValue && units.length === 2 ? units.map((u) => vis.filter((i) => (this.seriesValue[i].unit || "") === u)) : [vis]
    const [a, b] = this.win
    return groups.filter((g) => g.length).map((g) => {
      let lo = Infinity, hi = -Infinity
      g.forEach((i) => {
        const p = this.seriesValue[i].pts
        p.forEach((pt, k) => {
          const dentro = pt[0] >= a && pt[0] <= b
          const viz = (pt[0] < a && p[k + 1] && p[k + 1][0] >= a) || (pt[0] > b && p[k - 1] && p[k - 1][0] <= b)
          if (!dentro && !viz) return
          ;[pt[1], pt[2], pt[3]].forEach((v) => { if (v != null) { lo = Math.min(lo, v); hi = Math.max(hi, v) } })
        })
      })
      if (lo === Infinity) { lo = 0; hi = 1 }
      const unit = units.length === 1 || groups.length === 2 ? this.seriesValue[g[0]].unit : null
      return { ...niceRange(lo, hi, 3), unit, idx: g }
    })
  }

  y(ax, v) { return TOP + (this.h - TOP - BOTTOM) * (1 - (v - ax.lo) / (ax.hi - ax.lo)) }

  // ── desenho ───────────────────────────────────────────────────────
  el(name, attrs = {}, parent) {
    const e = document.createElementNS(NS, name)
    for (const [k, v] of Object.entries(attrs)) e.setAttribute(k, v)
    parent?.appendChild(e)
    return e
  }

  render() {
    this.w = this.stageTarget.clientWidth
    this.h = this.plotTarget.clientHeight
    if (!this.w || !this.h) return
    const svg = this.svgTarget
    svg.setAttribute("viewBox", `0 0 ${this.w} ${this.h}`)
    svg.setAttribute("width", this.w)
    svg.setAttribute("height", this.h)
    svg.replaceChildren()
    const [a, b] = this.win
    this.axs = this.axes()
    const defs = this.el("defs", {}, svg)
    const grid = this.el("g", { class: "ss-tc-grid" }, svg)
    ticks(a, b, Math.max(2, Math.floor(this.w / 72)), this.f).forEach((k) => {
      const gx = this.x(k.at)
      this.el("line", { x1: gx, x2: gx, y1: 0, y2: this.h, class: "is-v" }, grid)
    })
    const a0 = this.axs[0]
    if (a0) for (let v = a0.lo; v <= a0.hi + a0.step / 2; v += a0.step) this.el("line", { x1: 0, x2: this.w, y1: this.y(a0, v), y2: this.y(a0, v) }, grid)

    const lines = this.el("g", { class: "ss-tc-lines" }, svg)
    const fim = Math.min(this.w, this.x(Date.now()))
    this.axs.forEach((ax) => ax.idx.forEach((i) => {
      const s = this.seriesValue[i]
      const mode = this.modeOf(s)
      const runs = []
      const band = []
      let cur = []
      const p = s.pts
      for (let k = 0; k < p.length; k++) {
        const [t, v, mn, mx] = p[k]
        if (t < a && p[k + 1] && p[k + 1][0] < a) continue
        if (t > b && p[k - 1] && p[k - 1][0] > b) break
        if (v == null) { if (cur.length) runs.push(cur); cur = []; continue }
        const px = this.x(t), py = this.y(ax, v)
        if (mode === "step" && cur.length) cur.push([px, cur[cur.length - 1][1]])
        cur.push([px, py])
        if (mn != null && mx != null) band.push([px, this.y(ax, mn), this.y(ax, mx)])
      }
      if (cur.length) runs.push(cur)
      // Degrau: a última leitura vale até o fim da janela (ou até agora).
      if (mode === "step" && runs.length && p.length && p[p.length - 1][1] != null) {
        const last = runs[runs.length - 1], ult = last[last.length - 1]
        if (fim > ult[0]) last.push([fim, ult[1]])
      }
      const g = this.el("g", { style: `--c:${s.color}`, "data-series": i }, lines)
      if (band.length > 1) {
        const pts = [...band.map((q) => `${q[0]},${q[2]}`), ...band.slice().reverse().map((q) => `${q[0]},${q[1]}`)]
        this.el("polygon", { points: pts.join(" "), class: "ss-tc-band" }, g)
      }
      if (mode === "area") {
        const gid = `${this.uid}-g${i}`
        const lg = this.el("linearGradient", { id: gid, x1: 0, y1: 0, x2: 0, y2: 1 }, defs)
        this.el("stop", { offset: 0, style: `stop-color:${s.color};stop-opacity:.28` }, lg)
        this.el("stop", { offset: 1, style: `stop-color:${s.color};stop-opacity:0` }, lg)
        runs.filter((r) => r.length > 1).forEach((r) => {
          const d = `M${r.map((q) => q.join(",")).join(" L")} L${r[r.length - 1][0]},${this.h - BOTTOM} L${r[0][0]},${this.h - BOTTOM} Z`
          this.el("path", { d, fill: `url(#${gid})`, class: "ss-tc-area" }, g)
        })
      }
      runs.forEach((r) => {
        if (r.length === 1) this.el("circle", { cx: r[0][0], cy: r[0][1], r: 2.5, class: "ss-tc-pt" }, g)
        else this.el("path", { d: `M${r.map((q) => q.join(",")).join(" L")}`, class: "ss-tc-line" }, g)
      })
    }))

    // Rótulos do eixo Y por cima: o 1º à esquerda, o 2º à direita.
    const labels = this.el("g", { class: "ss-tc-ylabels" }, svg)
    this.axs.forEach((ax, n) => {
      const dec = ax.step < 1 ? (ax.step < 0.1 ? 2 : 1) : 0
      for (let v = ax.lo; v <= ax.hi + ax.step / 2; v += ax.step) {
        const yy = this.y(ax, v)
        if (yy < TOP - 1 || yy > this.h - BOTTOM + 1) continue
        const t = this.el("text", { x: n ? this.w - 5 : 5, y: Math.max(11, yy - 4), "text-anchor": n ? "end" : "start" }, labels)
        t.textContent = this.f.value(v, ax.unit, dec)
      }
    })
    this.dots = this.el("g", { class: "ss-tc-dots" }, svg)

    renderAxis(this.axisTarget, a, b, this.f)
    if (this.hasBandsTarget) placeSegments(this.bandsTarget, a, b)
    if (this.t != null) this.cursorAt(this.t)
  }

  // ── cursor e balão ────────────────────────────────────────────────
  timeAt(clientX) {
    const r = this.stageTarget.getBoundingClientRect()
    const fx = Math.min(Math.max((clientX - r.left) / r.width, 0), 1)
    return { t: this.win[0] + fx * (this.win[1] - this.win[0]), x: fx * r.width }
  }

  bandStates(t) {
    if (!this.hasBandsTarget) return []
    return [...this.bandsTarget.querySelectorAll(".ss-sb-row")].map((row) => {
      const seg = [...row.querySelectorAll("i[data-from]")].find((s) => +s.dataset.from <= t && t < +s.dataset.to)
      return { name: row.querySelector(".ss-sb-label")?.textContent || "", seg }
    })
  }

  cursorAt(t) {
    this.t = t
    const x = this.x(t)
    this.cursorTarget.hidden = false
    this.cursorTarget.style.left = `${x}px`
    this.dots?.replaceChildren()
    const rows = []
    const plain = [this.f.when(t)]
    this.axs.forEach((ax) => ax.idx.forEach((i) => {
      const s = this.seriesValue[i]
      const v = valueAt(s.pts, t, this.modeOf(s))
      const txt = this.f.value(v, s.unit, s.decimals ?? undefined, this.emptyValue || "—")
      if (v != null && this.dots) {
        this.el("circle", { cx: x, cy: this.y(ax, v), r: 5.5, class: "ss-tc-dot-bg" }, this.dots)
        this.el("circle", { cx: x, cy: this.y(ax, v), r: 4, style: `fill:${s.color}` }, this.dots)
      }
      rows.push(`<li><span class="ss-tc-key" style="background:${s.color}"></span><span>${escapeHtml(s.name)}</span><strong class="num">${escapeHtml(txt)}</strong></li>`)
      plain.push(`${s.name} ${txt}`)
    }))
    this.bandStates(t).forEach(({ name, seg }) => {
      rows.push(`<li><span class="ss-tc-key is-band" data-tone="${seg?.dataset.tone || ""}"></span><span>${escapeHtml(name)}</span><strong>${escapeHtml(seg?.dataset.label || "—")}</strong></li>`)
      plain.push(`${name} ${seg?.dataset.label || "—"}`)
    })
    this.tipTarget.innerHTML = `<p class="num">${this.f.when(t)}</p><ul>${rows.join("")}</ul>`
    this.tipTarget.hidden = false
    const right = x > this.w * 0.55
    this.tipTarget.style.left = right ? "auto" : `${x + 12}px`
    this.tipTarget.style.right = right ? `${this.w - x + 12}px` : "auto"
    return plain.join(", ")
  }

  hideCursor() {
    this.t = null
    this.cursorTarget.hidden = true
    this.tipTarget.hidden = true
    this.dots?.replaceChildren()
  }

  move(e) {
    if (e.target.closest(".ss-tc-reset")) return
    if (e.pointerType === "touch" && !this.touching) return
    const { t, x } = this.timeAt(e.clientX)
    this.cursorAt(t)
    if (this.brushStart != null) {
      this.brushTarget.hidden = false
      this.brushTarget.style.left = `${Math.min(this.brushStart.x, x)}px`
      this.brushTarget.style.width = `${Math.abs(x - this.brushStart.x)}px`
    }
  }

  down(e) {
    if (e.target.closest(".ss-tc-reset")) return
    if (e.pointerType === "mouse") {
      if (e.button !== 0) return
      this.brushStart = this.timeAt(e.clientX)
      return
    }
    // Toque: tocar mostra (e o dedo arrasta o cursor); tocar de novo esconde.
    if (this.t != null && !this.touching) { this.hideCursor(); return }
    this.touching = true
    this.cursorAt(this.timeAt(e.clientX).t)
  }

  up(e) {
    this.touching = false
    if (this.brushStart == null) return
    const end = this.timeAt(e.clientX)
    const start = this.brushStart
    this.brushStart = null
    this.brushTarget.hidden = true
    if (Math.abs(end.x - start.x) < 8) return
    const [a, b] = [start.t, end.t].sort((m, n) => m - n)
    this.zoomTo(a, b)
  }

  leave(e) {
    if (e?.pointerType === "touch") return
    this.brushStart = null
    this.brushTarget.hidden = true
    this.hideCursor()
  }

  // ── zoom ──────────────────────────────────────────────────────────
  zoomTo(a, b) {
    if (b - a < 60e3) { const m = (a + b) / 2; a = m - 30e3; b = m + 30e3 }
    this.win = [Math.max(this.fromValue, a), Math.min(this.toValue, b)]
    this.element.classList.add("is-zoomed")
    this.resetTarget.hidden = false
    this.hideCursor()
    this.render()
    this.dispatch("zoom", { detail: { from: new Date(this.win[0]), to: new Date(this.win[1]) } })
    if (this.zoomUrlValue) this.visit(this.zoomUrlValue, this.win)
  }

  resetZoom() {
    const zoomed = this.win[0] !== this.fromValue || this.win[1] !== this.toValue
    if (!zoomed) { if (this.resetUrlValue) this.visit(this.resetUrlValue); return }
    this.win = [this.fromValue, this.toValue]
    this.element.classList.toggle("is-zoomed", this.serverZoomed)
    this.resetTarget.hidden = !this.serverZoomed
    this.hideCursor()
    this.render()
    this.dispatch("zoom", { detail: { from: new Date(this.win[0]), to: new Date(this.win[1]) } })
    this.plotTarget.focus({ preventScroll: true })
  }

  dblclick(e) {
    if (e.target.closest(".ss-tc-reset")) return
    this.resetZoom()
  }

  // Janela mais fina no servidor: troca o turbo-frame (o de zoom-frame ou o em volta)
  // ou visita a página com ?from=&to=.
  visit(base, win) {
    const url = new URL(base, window.location.href)
    if (win) { url.searchParams.set("from", new Date(win[0]).toISOString()); url.searchParams.set("to", new Date(win[1]).toISOString()) }
    const frame = (this.zoomFrameValue && document.getElementById(this.zoomFrameValue)) || this.element.closest("turbo-frame")
    if (frame) frame.src = url.toString()
    else if (window.Turbo) window.Turbo.visit(url.toString())
    else window.location.href = url.toString()
  }

  // ── legenda e teclado ─────────────────────────────────────────────
  toggle(e) {
    const btn = e.currentTarget
    const i = +btn.dataset.index
    const on = this.hidden.has(i)
    on ? this.hidden.delete(i) : this.hidden.add(i)
    btn.setAttribute("aria-pressed", String(on))
    const t = this.t
    this.render()
    if (t != null) this.cursorAt(t)
  }

  key(e) {
    const [a, b] = this.win
    const passo = (b - a) / 40
    const t = this.t ?? b
    const map = { ArrowRight: t + passo, ArrowLeft: t - passo, Home: a, End: b }
    if (e.key in map) {
      e.preventDefault()
      this.live(this.cursorAt(Math.max(a, Math.min(b, map[e.key]))))
    } else if (e.key === "+" || e.key === "=") {
      e.preventDefault()
      const span = (b - a) / 4
      this.zoomTo(t - span, t + span)
    } else if (e.key === "0" || e.key === "-") {
      e.preventDefault()
      this.resetZoom()
    } else if (e.key === "Escape") this.hideCursor()
  }

  live(text) { if (this.hasLiveTarget) this.liveTarget.textContent = text }
}
