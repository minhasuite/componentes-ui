import { Controller } from "@hotwired/stimulus"

// Ss::DialogComponent (v0.15): o <dialog> genérico com conteúdo num turbo-frame. Abre quando um
// link carrega o frame dele ou por <button data-ss-dialog-open="id">; Esc, X e clique no fundo
// fecham (saída animada pelo .is-closing). Envio que deu certo fecha (closeOnSubmit) e
// [data-ss-dialog-close] na resposta do frame também. JS: elemento.ssDialog.open()/.close().
//
// v0.18: data-ss-dialog-keep-open no form/botão não fecha ao salvar e marca "algo salvo" (fechar
// depois recarrega a página de trás; [data-ss-dialog-refresh] ou [data-modal-refresh-on-close] na
// resposta também); turbo:frame-missing fecha e segue a URL; clique num [data-ss-dialog-dismiss]
// fecha; global (frame do layout): abre quando o frame enche, fecha quando esvazia, limpa ao fechar.
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

export default class extends Controller {
  static targets = ["frame", "title", "subtitle"]
  static values = { open: Boolean, closeOnSubmit: { type: Boolean, default: true }, global: Boolean, clear: Boolean,
                    refresh: Boolean, followMissing: { type: Boolean, default: true } }

  connect() {
    this.onClick = (e) => {
      const opener = e.target.closest?.(`[data-ss-dialog-open="${this.element.id}"]`)
      if (opener) { e.preventDefault(); this.open() }
    }
    this.onCancel = (e) => { e.preventDefault(); this.close() }
    document.addEventListener("click", this.onClick)
    this.element.addEventListener("cancel", this.onCancel)
    this.element.ssDialog = { open: () => this.open(), close: () => this.close() }
    this.onCache = () => { if (this.element.open) this.finish({ refresh: false }) }
    document.addEventListener("turbo:before-cache", this.onCache)
    // Uma visita já em curso (redirect do envio para a página inteira) dispensa o recarregar.
    this.onVisit = () => { this.lastVisit = performance.now() }
    document.addEventListener("turbo:visit", this.onVisit)
    if (this.globalValue && this.hasFrameTarget) {
      // Frame global: o conteúdo pode chegar por link, formulário ou turbo-stream (update/replace).
      this.observer = new MutationObserver(() => this.frameChanged())
      this.observer.observe(this.frameTarget, { childList: true })
    }
    if (this.openValue || (this.globalValue && this.frameFilled())) this.open()
  }

  disconnect() {
    document.removeEventListener("click", this.onClick)
    document.removeEventListener("turbo:before-cache", this.onCache)
    document.removeEventListener("turbo:visit", this.onVisit)
    this.element.removeEventListener("cancel", this.onCancel)
    this.observer?.disconnect()
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

  finish({ refresh: allowRefresh = true } = {}) {
    this.element.classList.remove("is-closing")
    const visiting = performance.now() - (this.lastVisit ?? -1e9) < 1500
    const refresh = allowRefresh && !visiting && (this.saved || !!this.element.querySelector("[data-ss-dialog-refresh], [data-modal-refresh-on-close]"))
    this.saved = false
    if (this.element.open) this.element.close()
    if (this.clearValue && this.hasFrameTarget) {
      this.clearing = true
      this.frameTarget.replaceChildren()
      this.frameTarget.removeAttribute("src")
      this.clearing = false
    }
    this.dispatch("closed", { prefix: "ss-dialog", detail: { refresh } })
    if (refresh) window.Turbo ? window.Turbo.visit(window.location.href, { action: "replace" }) : window.location.reload()
  }

  // Frame global: abre quando enche, fecha quando esvazia (o app limpou o frame).
  frameChanged() {
    if (this.clearing) return
    if (this.frameFilled()) this.open()
    else if (this.element.open) this.close()
  }

  frameFilled() {
    return this.hasFrameTarget && [...this.frameTarget.childNodes].some((n) => n.nodeType === 1 || n.textContent.trim())
  }

  // Resposta sem o frame (redirect para uma página inteira): fecha e segue a URL.
  missing(event) {
    if (!this.followMissingValue || !this.hasFrameTarget || event.target !== this.frameTarget) return
    event.preventDefault()
    const url = event.detail?.response?.url
    this.element.removeAttribute("aria-busy")
    this.finish({ refresh: false })
    if (url) window.Turbo ? window.Turbo.visit(url) : (window.location.href = url)
  }

  // Clique num [data-ss-dialog-dismiss] dentro (Cancelar do rodapé, X da resposta): fecha.
  // ([data-ss-dialog-close] é outra coisa: na resposta do frame, pede para fechar ao carregar.)
  closer(event) {
    const el = event.target.closest?.("[data-ss-dialog-dismiss]")
    if (el && this.element.contains(el) && !el.matches("[data-action*='ss-dialog#close']")) this.close(event)
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
    if (!this.hasTitleTarget && !this.element.getAttribute("aria-label")) {
      const h = f.querySelector("h1, h2")
      if (h) this.element.setAttribute("aria-label", h.textContent.trim())
    }
    f.querySelector("[autofocus], input:not([type=hidden]), select, textarea")?.focus()
  }

  submitted(event) {
    if (!event.detail?.success || !this.element.contains(event.target)) return
    const form = event.target
    const submitter = event.detail?.formSubmission?.submitter
    const keep = form.hasAttribute?.("data-ss-dialog-keep-open") || submitter?.hasAttribute?.("data-ss-dialog-keep-open")
    if (keep || !this.closeOnSubmitValue) { this.saved = this.saved || keep || this.refreshValue; return }
    if (this.refreshValue) this.saved = true
    this.close()
  }

  backdrop(event) {
    if (event.target !== this.element) return
    const r = this.element.getBoundingClientRect()
    const inside = event.clientX >= r.left && event.clientX <= r.right && event.clientY >= r.top && event.clientY <= r.bottom
    if (!inside) this.close()
  }
}
