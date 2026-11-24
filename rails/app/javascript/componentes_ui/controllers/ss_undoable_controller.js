import { Controller } from "@hotwired/stimulus"
import { reduced } from "componentes_ui/controllers/ss_motion_controller"
import { haptic } from "componentes_ui/controllers/ss_haptics_controller"

// v1.9 · ação otimista com desfazer animado (Ss::UndoableRemovalComponent; par do SsUndoableRemoval).
// O item (data-controller="ss-undoable") tem um form de remover (button_to … method: :delete) com
// data-action="submit->ss-undoable#remove". Ao enviar:
//   1. o envio para; o item sai encolhendo (altura, opacidade e escala, --ss-dur-medium/--ss-ease-exit)
//      e fica inert (fora do Tab e do leitor de tela);
//   2. entra na pilha (#ss-toasts) um .ss-toast com o anel de contagem e "Desfazer" (o ss-toast cuida do
//      tempo, da pausa com o mouse e do arrastar);
//   3. Desfazer: o item volta crescendo no mesmo lugar (--ss-ease-enter) e o foco volta ao botão;
//   4. o aviso some sem desfazer: o form é enviado de verdade (requestSubmit, o Turbo trata a resposta);
//      deu certo, o item sai do DOM; falhou (turbo:submit-end sem sucesso), ele volta e entra um aviso de
//      erro (.is-bad). Saindo da página com a remoção pendente, ela vai na hora (fetch keepalive).
// Vibração (ss_haptics): warning ao remover, selection ao desfazer, error na falha. Menos movimento:
// some e volta sem animar.
export default class extends Controller {
  static values = {
    message: String,
    label: { type: String, default: "Desfazer" },
    close: { type: String, default: "Fechar aviso" },
    error: { type: String, default: "Não deu para concluir. Tente de novo." },
    duration: { type: Number, default: 5 },
  }

  connect() {
    this.leave = () => this.flushNow()
    document.addEventListener("turbo:before-visit", this.leave)
    window.addEventListener("pagehide", this.leave)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.leave)
    window.removeEventListener("pagehide", this.leave)
  }

  remove(event) {
    if (this.committing) return // o envio de verdade, depois do aviso
    event.preventDefault()
    if (this.pending) return
    this.form = event.target.closest("form") || event.target.form
    this.submitter = event.submitter
    this.pending = true
    haptic("warning")
    this.collapse()
    this.showToast()
  }

  // ── Movimento ──
  dur(name, fallback) {
    const v = getComputedStyle(this.element).getPropertyValue(name).trim()
    const n = parseFloat(v)
    return Number.isFinite(n) ? (v.endsWith("ms") ? n : n * 1000) : fallback
  }

  ease(name, fallback) {
    const v = getComputedStyle(this.element).getPropertyValue(name).trim()
    return v && CSS.supports("transition-timing-function", v) ? v : fallback
  }

  collapse() {
    const el = this.element
    el.inert = true
    el.setAttribute("aria-hidden", "true")
    el.classList.add("is-removing")
    if (reduced() || !el.animate) { el.hidden = true; return }
    const cs = getComputedStyle(el)
    const full = { height: `${el.offsetHeight}px`, opacity: 1, transform: "scale(1)", marginTop: cs.marginTop, marginBottom: cs.marginBottom,
                   paddingTop: cs.paddingTop, paddingBottom: cs.paddingBottom }
    const gone = { height: "0px", opacity: 0, transform: "scale(.94)", marginTop: "0px", marginBottom: "0px", paddingTop: "0px", paddingBottom: "0px" }
    el.style.overflow = "hidden"
    this.anim = el.animate([full, gone], { duration: this.dur("--ss-dur-medium", 280), easing: this.ease("--ss-ease-exit", "ease-in"), fill: "forwards" })
  }

  expand() {
    const el = this.element
    el.inert = false
    el.removeAttribute("aria-hidden")
    el.classList.remove("is-removing")
    el.hidden = false
    const done = () => { this.anim?.cancel(); this.anim = null; el.style.overflow = "" }
    if (!this.anim || reduced()) return done()
    const a = this.anim
    a.effect.updateTiming({ easing: this.ease("--ss-ease-enter", "ease-out") })
    a.reverse()
    a.finished.then(done, done)
  }

  // ── Aviso ──
  stack() {
    let s = document.getElementById("ss-toasts")
    if (!s) {
      s = document.createElement("div")
      s.id = "ss-toasts"
      s.className = "ss-toasts"
      s.dataset.position = "bottom-center"
      s.setAttribute("aria-live", "polite")
      s.setAttribute("aria-relevant", "additions")
      document.body.append(s)
    }
    return s
  }

  toast({ message, undo, bad }) {
    const t = document.createElement("div")
    t.className = `ss-toast${bad ? " is-bad" : ""}`
    t.setAttribute("role", bad ? "alert" : "status")
    t.style.setProperty("--ss-toast-d", `${this.durationValue}s`)
    t.dataset.controller = "ss-toast"
    t.dataset.ssToastDurationValue = String(this.durationValue * 1000)
    t.dataset.action = "mouseenter->ss-toast#pause mouseleave->ss-toast#resume focusin->ss-toast#pause focusout->ss-toast#resume"
    const lead = document.createElement("span")
    if (undo) {
      lead.className = "ss-toast-timer num"
      lead.setAttribute("aria-hidden", "true")
      lead.dataset.ssToastTarget = "timer"
      lead.textContent = String(this.durationValue)
    }
    const msg = document.createElement("span")
    msg.className = "ss-toast-msg"
    msg.textContent = message
    const close = document.createElement("button")
    close.type = "button"
    close.className = "ss-toast-close"
    close.setAttribute("aria-label", this.closeValue)
    close.dataset.action = "ss-toast#close"
    close.textContent = "×"
    t.append(...(undo ? [lead] : []), msg)
    if (undo) {
      const b = document.createElement("button")
      b.type = "button"
      b.className = "ss-toast-undo-btn"
      b.textContent = this.labelValue
      b.addEventListener("click", () => this.undo())
      t.append(b)
    }
    t.append(close)
    this.stack().append(t)
    return t
  }

  showToast() {
    this.undone = false
    this.toastEl = this.toast({ message: this.messageValue, undo: true })
    this.toastEl.addEventListener("ss-toast:closed", () => { if (!this.undone) this.commit() }, { once: true })
  }

  closeToast(t) {
    if (!t?.isConnected) return
    const c = this.application.getControllerForElementAndIdentifier(t, "ss-toast")
    if (c) c.close()
    else t.remove()
  }

  undo() {
    if (!this.pending) return
    this.undone = true
    this.pending = false
    haptic("selection")
    this.closeToast(this.toastEl)
    this.expand()
    const back = this.submitter || this.form?.querySelector("button, [type=submit]")
    back?.focus({ preventScroll: true })
    this.dispatch("undone")
  }

  // ── Remoção de verdade ──
  commit() {
    if (!this.pending || !this.form?.isConnected) return
    this.pending = false
    this.committing = true
    // Com Turbo, a resposta volta no turbo:submit-end; sem ele (data-turbo="false"), a página recarrega.
    this.form.addEventListener("turbo:submit-end", (e) => this.finished(e.detail?.success !== false), { once: true })
    this.form.requestSubmit(this.submitter)
  }

  finished(ok) {
    this.committing = false
    if (ok) {
      this.dispatch("removed")
      if (this.element.isConnected) this.element.remove()
      return
    }
    this.expand()
    haptic("error")
    this.toast({ message: this.errorValue, bad: true })
  }

  // Saindo da página com a remoção pendente: manda já (sem esperar o aviso).
  flushNow() {
    if (!this.pending || !this.form) return
    this.pending = false
    this.undone = true // o aviso que sumir com a página não envia de novo
    const body = new FormData(this.form, this.submitter || undefined)
    try {
      fetch(this.form.action, { method: "POST", body, keepalive: true, credentials: "same-origin", headers: { Accept: "text/vnd.turbo-stream.html, text/html" } })
    } catch { /* a página já está saindo */ }
  }
}
