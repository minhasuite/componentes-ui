import { Controller } from "@hotwired/stimulus"
import { ssSuccess } from "componentes_ui/controllers/ss_success_check_controller"
import { haptic } from "componentes_ui/controllers/ss_haptics_controller"

// Ss::MorphButtonComponent (v1.9, par do SsMorphButton). data-state: idle | running | ok | error.
// No formulário: turbo:submit-start/-end; sem Turbo, o submit mostra carregando até a página trocar.
// Progresso: direct-upload:progress (Active Storage) ou "ss-morph:progress" { value } → --v (0..1) e .is-determinate.
// type="button": "ss-morph:run" com detail.waitUntil(promise). API: el.ssMorph.start() / .succeed() / .fail() / .progress(v).
export default class extends Controller {
  static targets = ["status"]
  static values = { label: String, loading: String, done: String, failed: String, sound: Boolean }

  connect() {
    this.element.ssMorph = { start: () => this.start(), succeed: () => this.end(true), fail: () => this.end(false), progress: (v) => this.progress(v) }
    this.form = this.element.form
    this.onStart = (e) => { if (this.mine(e)) this.start() }
    this.onEnd = (e) => { if (this.mine(e) && this.state === "running") this.end(!!e.detail?.success) }
    this.onSubmit = (e) => { if (!window.Turbo && (e.submitter === this.element)) this.start() }
    this.onUpload = (e) => this.progress((e.detail?.progress ?? 0) / 100)
    this.onProgress = (e) => this.progress(e.detail?.value ?? 0)
    this.form?.addEventListener("turbo:submit-start", this.onStart)
    this.form?.addEventListener("turbo:submit-end", this.onEnd)
    this.form?.addEventListener("submit", this.onSubmit)
    this.form?.addEventListener("direct-upload:progress", this.onUpload)
    this.element.addEventListener("ss-morph:progress", this.onProgress)
  }

  disconnect() {
    clearTimeout(this.back)
    this.form?.removeEventListener("turbo:submit-start", this.onStart)
    this.form?.removeEventListener("turbo:submit-end", this.onEnd)
    this.form?.removeEventListener("submit", this.onSubmit)
    this.form?.removeEventListener("direct-upload:progress", this.onUpload)
    this.element.removeEventListener("ss-morph:progress", this.onProgress)
    delete this.element.ssMorph
  }

  get state() { return this.element.dataset.state }

  // Envio do formulário deste botão (ou de qualquer botão dele, se não houver submitter).
  mine(e) {
    const s = e.detail?.formSubmission?.submitter
    return !s || s === this.element
  }

  click(e) {
    if (this.state !== "idle") { e.preventDefault(); return }
    if (this.element.type !== "button") return
    let wait = null
    const ev = new CustomEvent("ss-morph:run", { bubbles: true, cancelable: true, detail: { waitUntil: (p) => { wait = p } } })
    this.element.dispatchEvent(ev)
    if (!wait) return
    this.start()
    Promise.resolve(wait).then(() => this.end(true), () => this.end(false))
  }

  start() {
    clearTimeout(this.back)
    // Mede a pílula antes de encolher (a largura anima entre dois comprimentos).
    this.element.style.setProperty("--ss-morph-w", `${this.element.offsetWidth}px`)
    this.element.dataset.state = "running"
    this.element.classList.remove("is-determinate")
    this.element.setAttribute("aria-busy", "true")
    this.element.setAttribute("aria-disabled", "true")
    this.say(this.loadingValue)
  }

  progress(v) {
    if (this.state !== "running") return
    this.element.classList.add("is-determinate")
    this.element.style.setProperty("--v", Math.min(1, Math.max(0, Number(v) || 0)).toFixed(3))
  }

  end(ok) {
    this.element.dataset.state = ok ? "ok" : "error"
    this.element.removeAttribute("aria-busy")
    // v1.14.0: o ✓ se desenha (CSS) com a vibração de sucesso e o gancho do som (ssSuccess).
    ok ? ssSuccess(this.element, { sound: this.soundValue }) : haptic("error")
    this.say(ok ? this.doneValue : this.failedValue)
    this.back = setTimeout(() => {
      this.element.dataset.state = "idle"
      this.element.removeAttribute("aria-disabled")
      this.element.style.removeProperty("--v")
    }, 1600)
  }

  say(text) { if (this.hasStatusTarget) this.statusTarget.textContent = text }
}
