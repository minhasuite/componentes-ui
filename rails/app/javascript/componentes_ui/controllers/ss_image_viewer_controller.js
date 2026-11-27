import { Controller } from "@hotwired/stimulus"

// Ss::ImageViewerComponent (v1.10, par do SsImageViewer). open() abre o <dialog> (showModal: Esc fecha e o foco
// volta à miniatura sozinho). A imagem tem escala s (1 = inteira) e deslocamento x/y em px, no transform do
// .ss-viewer-img; o deslocamento fica preso para a ampliada não sair da tela. Roda: zoom no ponto do mouse;
// pinça: dois ponteiros; arrastar: move a ampliada; duplo clique: 2,5× no ponto e volta; + − 0 e as setas no
// teclado. O % vai num <output aria-live>. Com animação (classe is-anim: a transição do CSS, --ss-dur-medium)
// só nos saltos (botão, duplo clique, tecla); no arrasto e na pinça segue o dedo. Reduzir movimento: o CSS tira
// a transição.
const DOUBLE = 2.5 // o toque duplo do app
const STEP = 1.5 // cada clique em + ou −
const WHEEL = 0.0015 // sensibilidade da roda (por px de deltaY)
const PAN = 48 // px por seta

export default class extends Controller {
  static targets = ["dialog", "stage", "img", "pct", "fail", "less", "more", "opener"]
  static values = { max: { type: Number, default: 4 }, zoom: String }

  connect() {
    this.s = 1; this.x = 0; this.y = 0
    this.pointers = new Map()
    this.move = this.move.bind(this)
    this.up = this.up.bind(this)
    this.paint()
  }

  disconnect() { this.release() }

  open() {
    const d = this.dialogTarget
    if (d.showModal && !d.open) d.showModal()
    this.stageTarget.focus()
  }

  close() {
    if (this.dialogTarget.close && this.dialogTarget.open) this.dialogTarget.close()
    else this.reset()
  }

  reset() { this.set(1, 0, 0, true) }
  zoomIn() { this.zoomAt(this.s * STEP, null, true) }
  zoomOut() { this.zoomAt(this.s / STEP, null, true) }

  // Escala nova com o ponto (clientX/Y) parado na tela; sem ponto, o centro.
  zoomAt(s, point, animate) {
    const next = Math.min(this.maxValue, Math.max(1, s))
    const r = this.stageTarget.getBoundingClientRect()
    const px = point ? point.x - (r.left + r.width / 2) : 0
    const py = point ? point.y - (r.top + r.height / 2) : 0
    const k = next / this.s
    this.set(next, px - (px - this.x) * k, py - (py - this.y) * k, animate)
  }

  set(s, x, y, animate = false) {
    this.s = s
    const r = this.stageTarget.getBoundingClientRect()
    const mx = (r.width * (s - 1)) / 2, my = (r.height * (s - 1)) / 2
    this.x = Math.min(mx, Math.max(-mx, x))
    this.y = Math.min(my, Math.max(-my, y))
    this.imgTarget.classList.toggle("is-anim", animate)
    this.paint()
  }

  paint() {
    if (!this.hasImgTarget) return
    this.imgTarget.style.transform = `translate(${this.x}px, ${this.y}px) scale(${this.s})`
    this.stageTarget.classList.toggle("is-zoomed", this.s > 1.01)
    const pct = Math.round(this.s * 100)
    if (this.hasPctTarget) {
      this.pctTarget.textContent = `${pct}%`
      this.pctTarget.setAttribute("aria-label", (this.zoomValue || "Zoom %{pct}%").replace("%{pct}", pct))
    }
    if (this.hasLessTarget) this.lessTarget.disabled = this.s <= 1.01
    if (this.hasMoreTarget) this.moreTarget.disabled = this.s >= this.maxValue - 0.01
  }

  wheel(e) {
    e.preventDefault()
    this.zoomAt(this.s * Math.exp(-e.deltaY * WHEEL), { x: e.clientX, y: e.clientY }, false)
  }

  double(e) {
    if (this.s > 1.01) this.reset()
    else this.zoomAt(DOUBLE, { x: e.clientX, y: e.clientY }, true)
  }

  down(e) {
    this.stageTarget.setPointerCapture?.(e.pointerId)
    this.pointers.set(e.pointerId, { x: e.clientX, y: e.clientY })
    if (this.pointers.size === 1) {
      this.stageTarget.addEventListener("pointermove", this.move)
      this.stageTarget.addEventListener("pointerup", this.up)
      this.stageTarget.addEventListener("pointercancel", this.up)
    }
    this.start = { s: this.s, x: this.x, y: this.y, pts: [...this.pointers.values()].map((p) => ({ ...p })) }
  }

  move(e) {
    if (!this.pointers.has(e.pointerId)) return
    this.pointers.set(e.pointerId, { x: e.clientX, y: e.clientY })
    const pts = [...this.pointers.values()]
    const st = this.start
    if (pts.length >= 2 && st.pts.length >= 2) {
      const d0 = Math.hypot(st.pts[0].x - st.pts[1].x, st.pts[0].y - st.pts[1].y) || 1
      const d1 = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y)
      this.s = st.s; this.x = st.x; this.y = st.y
      this.zoomAt(st.s * (d1 / d0), { x: (pts[0].x + pts[1].x) / 2, y: (pts[0].y + pts[1].y) / 2 }, false)
    } else if (this.s > 1.01) {
      this.set(this.s, st.x + pts[0].x - st.pts[0].x, st.y + pts[0].y - st.pts[0].y, false)
    }
  }

  up(e) {
    this.pointers.delete(e.pointerId)
    if (this.pointers.size === 0) this.release()
    else this.start = { s: this.s, x: this.x, y: this.y, pts: [...this.pointers.values()].map((p) => ({ ...p })) }
  }

  release() {
    this.pointers?.clear()
    this.stageTarget?.removeEventListener("pointermove", this.move)
    this.stageTarget?.removeEventListener("pointerup", this.up)
    this.stageTarget?.removeEventListener("pointercancel", this.up)
  }

  key(e) {
    const pan = { ArrowLeft: [PAN, 0], ArrowRight: [-PAN, 0], ArrowUp: [0, PAN], ArrowDown: [0, -PAN] }[e.key]
    if (e.key === "+" || e.key === "=") this.zoomIn()
    else if (e.key === "-") this.zoomOut()
    else if (e.key === "0") this.reset()
    else if (pan && this.s > 1.01) this.set(this.s, this.x + pan[0], this.y + pan[1], true)
    else return
    e.preventDefault()
  }

  broken() {
    this.imgTarget.hidden = true
    this.failTarget.hidden = false
  }
}
