import { Controller } from "@hotwired/stimulus"

// Ss::DialogComponent (v0.15): o <dialog> genérico com conteúdo num turbo-frame. Abre quando um
// link carrega o frame dele ou por <button data-ss-dialog-open="id">; Esc, X e clique no fundo
// fecham (saída animada pelo .is-closing). Envio que deu certo fecha (closeOnSubmit) e
// [data-ss-dialog-close] na resposta do frame também. JS: elemento.ssDialog.open()/.close().
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

export default class extends Controller {
  static targets = ["frame", "title", "subtitle"]
  static values = { open: Boolean, closeOnSubmit: { type: Boolean, default: true } }

  connect() {
    this.onClick = (e) => {
      const opener = e.target.closest?.(`[data-ss-dialog-open="${this.element.id}"]`)
      if (opener) { e.preventDefault(); this.open() }
    }
    this.onCancel = (e) => { e.preventDefault(); this.close() }
    document.addEventListener("click", this.onClick)
    this.element.addEventListener("cancel", this.onCancel)
    this.element.ssDialog = { open: () => this.open(), close: () => this.close() }
    if (this.openValue) this.open()
  }

  disconnect() {
    document.removeEventListener("click", this.onClick)
    this.element.removeEventListener("cancel", this.onCancel)
    clearTimeout(this.closeTimer)
    delete this.element.ssDialog
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
    if (reduced()) return this.finish()
    dialog.classList.add("is-closing")
    const onEnd = (e) => { if (e.target === dialog) done() }
    const done = () => {
      clearTimeout(this.closeTimer)
      dialog.removeEventListener("animationend", onEnd)
      if (dialog.classList.contains("is-closing")) this.finish()
    }
    dialog.addEventListener("animationend", onEnd)
    this.closeTimer = setTimeout(done, 280)
  }

  finish() {
    this.element.classList.remove("is-closing")
    this.element.close()
    this.dispatch("closed", { prefix: "ss-dialog" })
  }

  loading(event) {
    if (this.hasFrameTarget && event.target === this.frameTarget) { this.element.setAttribute("aria-busy", "true"); this.open() }
  }

  loaded(event) {
    if (!this.hasFrameTarget || event.target !== this.frameTarget) return
    this.element.removeAttribute("aria-busy")
    const f = this.frameTarget
    const head = f.querySelector("[data-dialog-title]") || (f.dataset.dialogTitle ? f : null)
    if (head && this.hasTitleTarget) this.titleTarget.textContent = head.dataset.dialogTitle
    const sub = f.querySelector("[data-dialog-subtitle]") || (f.dataset.dialogSubtitle !== undefined ? f : null)
    if (sub && this.hasSubtitleTarget) { this.subtitleTarget.textContent = sub.dataset.dialogSubtitle; this.subtitleTarget.hidden = !sub.dataset.dialogSubtitle }
    if (f.querySelector("[data-ss-dialog-close]")) return this.close()
    f.querySelector("[autofocus], input:not([type=hidden]), select, textarea")?.focus()
  }

  submitted(event) {
    if (this.closeOnSubmitValue && event.detail?.success && this.element.contains(event.target)) this.close()
  }

  backdrop(event) {
    if (event.target !== this.element) return
    const r = this.element.getBoundingClientRect()
    const inside = event.clientX >= r.left && event.clientX <= r.right && event.clientY >= r.top && event.clientY <= r.bottom
    if (!inside) this.close()
  }
}
