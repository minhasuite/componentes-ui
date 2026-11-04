import { Controller } from "@hotwired/stimulus"
import { reduced } from "componentes_ui/controllers/ss_motion_controller"

// Chave sozinha (Ss::SwitchComponent).
// Modo A (checkbox): só a confirmação (confirm-value); o movimento é o do ss-motion.
// Modo B (form do button_to): ao enviar, vira a chave na hora (aria-pressed, a mesma festa
// da .ss-switch-row: data-ss-anim) e marca aria-busy; se o servidor falhar, volta. Dentro de
// um tile (.ss-device), marca o tile como "pending" e, na falha, "error".
// Escuta turbo:submit-start/end; com data-turbo="false", vira no submit e a página recarrega.
export default class extends Controller {
  static targets = ["button"]
  static values = { confirm: String, onLabel: String, offLabel: String }

  connect() {
    if (this.element.tagName !== "FORM") return
    this.start = (e) => this.begin(e)
    this.end = (e) => this.finish(e)
    this.plain = (e) => { if (!e.defaultPrevented && this.element.dataset.turbo === "false") this.flip() }
    this.element.addEventListener("turbo:submit-start", this.start)
    this.element.addEventListener("turbo:submit-end", this.end)
    this.element.addEventListener("submit", this.plain)
  }

  disconnect() {
    if (this.element.tagName !== "FORM") return
    this.element.removeEventListener("turbo:submit-start", this.start)
    this.element.removeEventListener("turbo:submit-end", this.end)
    this.element.removeEventListener("submit", this.plain)
  }

  // Modo A: pergunta antes de trocar; "não" desfaz.
  confirmChange(e) {
    if (!this.confirmValue) return
    if (!window.confirm(this.confirmValue)) e.target.checked = !e.target.checked
  }

  get button() { return this.hasButtonTarget ? this.buttonTarget : this.element.querySelector(".ss-switch") }
  get tile() { return this.element.closest(".ss-device") }

  begin() {
    this.was = this.button.getAttribute("aria-pressed") === "true"
    this.flip()
    this.button.setAttribute("aria-busy", "true")
    const t = this.tile
    if (t) { this.tileStatus = t.dataset.status; t.dataset.status = "pending" }
  }

  finish(e) {
    const ok = e.detail?.success !== false
    this.button.removeAttribute("aria-busy")
    if (!ok) this.set(this.was, true)
    const t = this.tile
    if (t) {
      t.dataset.status = ok ? (this.tileStatus === "error" ? "ready" : this.tileStatus || "ready") : "error"
      if (!ok) {
        const st = t.querySelector(".ss-device-state")
        if (st?.dataset.error) st.textContent = st.dataset.error
      }
    }
  }

  flip() { this.set(this.button.getAttribute("aria-pressed") !== "true", true) }

  set(on, animate) {
    const b = this.button
    b.setAttribute("aria-pressed", String(on))
    b.title = on ? this.onLabelValue : this.offLabelValue
    this.tile?.classList.toggle("is-on", on)
    if (!animate || reduced()) return
    b.removeAttribute("data-ss-anim")
    void b.offsetWidth // recomeça a animação se trocar de novo no meio
    b.setAttribute("data-ss-anim", on ? "on" : "off")
    clearTimeout(this.animTimer)
    this.animTimer = setTimeout(() => b.removeAttribute("data-ss-anim"), 800)
  }
}
