import { Controller } from "@hotwired/stimulus"

// Ss::DrawerComponent (<dialog>): abre quando um link carrega o frame dele ou por
// <button data-ss-drawer-open="id">; Esc, X e clique no fundo fecham.
// Movimento: entra deslizando com mola (CSS) e, ao fechar, sai deslizando e o fundo
// apaga (.is-closing) antes do dialog.close(). Sem JS, o X (form method=dialog) fecha seco.
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

export default class extends Controller {
  static targets = ["frame", "title"]
  static values = { open: Boolean }

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

  // Clique fora do painel (no ::backdrop) cai no próprio <dialog>.
  backdrop(event) {
    if (event.target !== this.element) return
    const r = this.element.getBoundingClientRect()
    const inside = event.clientX >= r.left && event.clientX <= r.right && event.clientY >= r.top && event.clientY <= r.bottom
    if (!inside) this.close()
  }
}
