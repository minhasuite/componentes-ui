import { Controller } from "@hotwired/stimulus"

// v1.13.0 (Ss::SinceLastVisitComponent, par do SsSinceLastVisit): guarda a última visita no localStorage (key-value),
// some sozinho em auto-hide segundos (pausa com o mouse ou o foco em cima; 0 não some) ou no "Entendi", recolhendo com
// os tokens de movimento (reduzir movimento: some na hora). Com src-value (o cartão vem do produto), lê a última visita,
// busca o src com %{since} trocado pela data ISO e põe o HTML; na 1ª visita só guarda o agora.
export default class extends Controller {
  static values = { key: { type: String, default: "ss-last-visit" }, autoHide: Number, src: String }

  connect() {
    if (this.srcValue) return this.load()
    if (this.autoHideValue > 0) { this.left = this.autoHideValue * 1000; this.resume() }
  }

  disconnect() { clearTimeout(this.timer) }

  get last() { try { return localStorage.getItem(this.keyValue) } catch (_) { return null } }

  store() { try { localStorage.setItem(this.keyValue, new Date().toISOString()) } catch (_) {} }

  async load() {
    const since = this.last
    this.store()
    if (!since) return
    try {
      const res = await fetch(this.srcValue.replace("%{since}", encodeURIComponent(since)), { headers: { Accept: "text/html" }, credentials: "same-origin" })
      if (res.ok) this.element.innerHTML = await res.text()
    } catch (_) {}
  }

  pause() {
    if (!this.started) return
    clearTimeout(this.timer)
    this.left -= Date.now() - this.started
    this.started = null
  }

  resume() {
    if (this.started || !(this.left > 0)) return
    this.started = Date.now()
    this.timer = setTimeout(() => this.dismiss(), this.left)
  }

  dismiss() {
    clearTimeout(this.timer)
    this.started = null
    this.left = 0
    this.store()
    this.dispatch("dismissed", { prefix: "ss-since" })
    const el = this.element
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) { el.hidden = true; return }
    el.addEventListener("transitionend", () => { el.hidden = true }, { once: true })
    el.dataset.leaving = ""
    const ms = parseFloat(getComputedStyle(el).transitionDuration) * 1000 || 0
    setTimeout(() => { el.hidden = true }, ms + 50)
  }
}
