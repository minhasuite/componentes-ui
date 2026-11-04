import { Controller } from "@hotwired/stimulus"

// Ss::ConfirmDialogComponent: a caixa de confirmação da suíte. Com global (padrão) vira o
// confirm do Turbo: todo data-turbo-confirm abre esta caixa e o envio espera a resposta
// (Promise<boolean>). Por chamada, no form/link/botão: data-turbo-confirm-title,
// data-turbo-confirm-button (texto do OK) e data-turbo-confirm-tone (default|warn|danger).
// Por JS: elemento.ssConfirm(mensagem, { title, ok, tone }).then((ok) => …).
const TONES = ["default", "warn", "danger"]

export default class extends Controller {
  static targets = ["title", "text", "ok", "cancel"]
  static values = { global: { type: Boolean, default: true }, tone: { type: String, default: "default" } }

  connect() {
    // Textos do HTML (já no idioma da página): voltam a cada abertura.
    this.defaults = { title: this.titleTarget.textContent, text: this.textTarget.textContent, ok: this.okTarget.textContent, tone: this.toneValue }
    this.element.ssConfirm = (message, opts = {}) => this.confirm(message, opts)
    if (this.globalValue) this.install()
  }

  disconnect() {
    delete this.element.ssConfirm
    if (this.installed) this.uninstall()
    this.settle(false)
  }

  // Turbo 8: Turbo.config.forms.confirm; antes do 8.0.13: Turbo.setConfirmMethod.
  install() {
    const Turbo = window.Turbo
    if (!Turbo) return
    const fn = (message, element, submitter) => this.confirm(message, { ...this.fromData(element), ...this.fromData(submitter) })
    if (Turbo.config?.forms) {
      this.previous = Turbo.config.forms.confirm
      Turbo.config.forms.confirm = fn
    } else if (Turbo.setConfirmMethod) {
      Turbo.setConfirmMethod(fn)
    }
    this.installed = fn
  }

  uninstall() {
    const Turbo = window.Turbo
    // Só devolve o anterior se ninguém trocou depois (outra caixa no lugar desta).
    if (Turbo?.config?.forms && Turbo.config.forms.confirm === this.installed) Turbo.config.forms.confirm = this.previous
    this.installed = null
  }

  fromData(el) {
    const d = el?.dataset || {}
    const o = {}
    if (d.turboConfirmTitle) o.title = d.turboConfirmTitle
    if (d.turboConfirmButton) o.ok = d.turboConfirmButton
    if (d.turboConfirmTone) o.tone = d.turboConfirmTone
    return o
  }

  confirm(message, opts = {}) {
    if (!this.element.isConnected) return Promise.resolve(window.confirm(message))
    this.settle(false) // uma pergunta por vez
    const o = { ...this.defaults, ...opts }
    const text = message ?? o.text ?? ""
    this.titleTarget.textContent = o.title
    this.textTarget.textContent = text
    this.textTarget.hidden = !text
    this.okTarget.textContent = o.ok
    const tone = TONES.includes(o.tone) ? o.tone : "default"
    TONES.forEach((t) => this.element.classList.toggle(`is-${t}`, t !== "default" && t === tone))
    this.element.returnValue = ""
    if (!this.element.open) this.element.showModal()
    return new Promise((resolve) => { this.resolver = resolve })
  }

  // close do <dialog>: OK (value=ok), Voltar, Esc ou clique fora.
  closed() { this.settle(this.element.returnValue === "ok") }

  backdrop(event) {
    if (event.target === this.element) this.element.close("cancel")
  }

  settle(answer) {
    const r = this.resolver
    this.resolver = null
    if (r) r(answer)
  }
}
