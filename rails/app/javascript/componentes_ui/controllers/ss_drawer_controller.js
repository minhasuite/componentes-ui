import { Controller } from "@hotwired/stimulus"

// Ss::DrawerComponent (<dialog>): abre quando um link carrega o frame dele ou por
// <button data-ss-drawer-open="id">; Esc, X e clique no fundo fecham.
// Movimento: entra deslizando com mola (CSS) e, ao fechar, sai deslizando e o fundo
// apaga (.is-closing) antes do dialog.close(). Sem JS, o X (form method=dialog) fecha seco.
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

export default class extends Controller {
  static targets = ["frame", "title", "handle"]
  static values = { open: Boolean, detents: Array, detent: Number, size: String }

  connect() {
    this.onClick = (e) => {
      const opener = e.target.closest(`[data-ss-drawer-open="${this.element.id}"]`)
      if (opener) { e.preventDefault(); this.open() }
    }
    // Esc: o navegador dispara "cancel"; seguramos para sair animando.
    this.onCancel = (e) => { e.preventDefault(); this.close() }
    document.addEventListener("click", this.onClick)
    this.element.addEventListener("cancel", this.onCancel)
    if (this.openValue) this.open()
  }

  disconnect() {
    document.removeEventListener("click", this.onClick)
    this.element.removeEventListener("cancel", this.onCancel)
    clearTimeout(this.closeTimer)
  }

  open() {
    clearTimeout(this.closeTimer)
    this.element.classList.remove("is-closing")
    if (!this.element.open) this.element.showModal()
  }

  close(event) {
    event?.preventDefault?.()
    const dialog = this.element
    if (!dialog.open || dialog.classList.contains("is-closing")) return
    if (reduced()) return dialog.close()
    dialog.classList.add("is-closing")
    const onEnd = (e) => { if (e.target === dialog) done() }
    const done = () => {
      clearTimeout(this.closeTimer)
      dialog.removeEventListener("animationend", onEnd)
      if (!dialog.classList.contains("is-closing")) return
      dialog.classList.remove("is-closing")
      dialog.close()
    }
    dialog.addEventListener("animationend", onEnd)
    this.closeTimer = setTimeout(done, 320)
  }

  loading(event) {
    if (this.hasFrameTarget && event.target === this.frameTarget) { this.element.setAttribute("aria-busy", "true"); this.open() }
  }

  loaded(event) {
    if (!this.hasFrameTarget || event.target !== this.frameTarget) return
    this.element.removeAttribute("aria-busy")
    const heading = this.frameTarget.querySelector("[data-drawer-title]")
    if (heading && this.hasTitleTarget) this.titleTarget.textContent = heading.dataset.drawerTitle
  }

  // ── v1.14.0: folha com alturas (detents) no celular ───────────────
  // Só vale com o painel virado folha (CSS até 40rem); --ss-detent é a fração da tela. Arrastar a alça muda a altura
  // sem transição (.is-dragging); soltou, vai à altura mais perto (com o embalo do dedo) com a mola do CSS; abaixo
  // da menor, fecha.
  get sheet() { return this.detentsValue.length > 0 && matchMedia("(max-width: 40rem)").matches }

  setDetent(v) {
    this.detentValue = v
    this.element.style.setProperty("--ss-detent", v)
    if (!this.hasHandleTarget) return
    const pct = Math.round(v * 100)
    this.handleTarget.setAttribute("aria-valuenow", pct)
    this.handleTarget.setAttribute("aria-valuetext", (this.sizeValue || "%{percent}%").replace("%{percent}", pct))
    this.element.dispatchEvent(new CustomEvent("ss-drawer:detent", { bubbles: true, detail: { detent: v } }))
  }

  grab(e) {
    if (!this.sheet || e.button > 0) return
    e.preventDefault()
    const h = innerHeight
    const start = { y: e.clientY, v: this.detentValue || this.detentsValue[0], t: performance.now() }
    let last = { y: e.clientY, t: start.t }
    let vel = 0
    this.element.classList.add("is-dragging")
    this.handleTarget.setPointerCapture?.(e.pointerId)
    const move = (ev) => {
      const now = performance.now()
      vel = (ev.clientY - last.y) / Math.max(now - last.t, 1)
      last = { y: ev.clientY, t: now }
      const v = Math.min(1, Math.max(0.08, start.v - (ev.clientY - start.y) / h))
      this.element.style.setProperty("--ss-detent", v)
    }
    const up = (ev) => {
      this.handleTarget.removeEventListener("pointermove", move)
      this.handleTarget.removeEventListener("pointerup", up)
      this.handleTarget.removeEventListener("pointercancel", up)
      this.element.classList.remove("is-dragging")
      const moved = Math.abs(ev.clientY - start.y)
      if (moved < 6) return this.step(1, true)
      // O embalo projeta ~180 ms para a frente (px/ms → fração da tela).
      const v = start.v - (ev.clientY - start.y) / h - vel * 180 / h
      const ds = this.detentsValue
      if (v < ds[0] - 0.12) { this.setDetent(ds[0]); return this.close() }
      this.setDetent(ds.reduce((a, b) => (Math.abs(b - v) < Math.abs(a - v) ? b : a)))
    }
    this.handleTarget.addEventListener("pointermove", move)
    this.handleTarget.addEventListener("pointerup", up)
    this.handleTarget.addEventListener("pointercancel", up)
  }

  // Toque na alça (ou Enter) sobe uma altura; na mais alta, volta à primeira.
  step(dir, wrap = false) {
    const ds = this.detentsValue
    const i = Math.max(0, ds.indexOf(this.detentValue))
    let j = i + dir
    if (j >= ds.length) j = wrap ? 0 : ds.length - 1
    if (j < 0) j = 0
    this.setDetent(ds[j])
  }

  handleKey(e) {
    const ds = this.detentsValue
    const map = { ArrowUp: 1, ArrowRight: 1, ArrowDown: -1, ArrowLeft: -1 }
    if (e.key in map) { e.preventDefault(); return this.step(map[e.key]) }
    if (e.key === "Home") { e.preventDefault(); return this.setDetent(ds[0]) }
    if (e.key === "End") { e.preventDefault(); return this.setDetent(ds[ds.length - 1]) }
    if (e.key === "Enter" || e.key === " ") { e.preventDefault(); this.step(1, true) }
  }

  // Clique fora do painel (no ::backdrop) cai no próprio <dialog>.
  backdrop(event) {
    if (event.target !== this.element) return
    const r = this.element.getBoundingClientRect()
    const inside = event.clientX >= r.left && event.clientX <= r.right && event.clientY >= r.top && event.clientY <= r.bottom
    if (!inside) this.close()
  }
}
