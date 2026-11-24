import { Controller } from "@hotwired/stimulus"

// v0.24 (auditoria de UX, B13): validação do formulário da gem no lugar do balão nativo.
// O ss_form_with liga este controller no <form>. Ao conectar, o form ganha novalidate: o navegador para de
// mostrar "Preencha este campo" como dica ao passar o mouse (o Chrome usa a mensagem de validação como
// tooltip do campo inválido enquanto o form valida sozinho) e o balão do envio. A regra continua a do HTML
// (required, type, pattern, min/max, maxlength) e a mensagem aparece embaixo do campo (.ss-field-error):
// ao sair do campo e ao tentar enviar; o 1º campo errado recebe o foco e o envio para. Corrigindo, a mensagem
// some enquanto digita. Sem JS o form segue com a validação do navegador (o novalidate vem daqui).
// Botão com formnovalidate (salvar rascunho) envia sem conferir.
// v1.9: sem salto no meio do clique. Sair do campo porque se apertou um botão logo abaixo dele marcava o
// erro (que empurra o conteúdo) entre o apertar e o soltar, e o clique se perdia. Agora, saindo do campo
// com o dedo ou o mouse apertado (ou logo depois de um toque), a marca espera o clique terminar; pelo
// teclado (Tab) continua na hora. O form ganha data-ss-validate-ready, e o CSS (v19_movimento.css) só
// mostra a mensagem quando este controller marca (.is-invalid), não no :user-invalid do navegador.
const FIELDS = "input:not([type=hidden]):not([type=submit]):not([type=button]):not([type=reset]), select, textarea"

export default class extends Controller {
  static values = { required: String }

  connect() {
    this.touched = new WeakSet()
    this.pending = new Set()
    this.element.noValidate = true
    this.element.dataset.ssValidateReady = ""
    this.onDown = () => { this.pressing = true }
    this.onUp = () => {
      if (!this.pressing) return
      this.pressing = false
      this.lastUp = performance.now()
      setTimeout(() => this.flush(), 0)
    }
    document.addEventListener("pointerdown", this.onDown, true)
    document.addEventListener("pointerup", this.onUp, true)
    document.addEventListener("pointercancel", this.onUp, true)
    // Captura no próprio form: roda antes do ss-dirty e do Turbo, que olham o mesmo submit.
    this.onSubmit = (e) => this.submit(e)
    this.onLeave = (e) => { if (this.isField(e.target)) { this.touched.add(e.target); this.leave(e.target) } }
    this.onType = (e) => { if (this.isField(e.target) && this.touched.has(e.target)) this.mark(e.target) }
    this.element.addEventListener("submit", this.onSubmit, true)
    this.element.addEventListener("focusout", this.onLeave)
    this.element.addEventListener("input", this.onType)
    this.element.addEventListener("change", this.onType)
  }

  disconnect() {
    delete this.element.dataset.ssValidateReady
    document.removeEventListener("pointerdown", this.onDown, true)
    document.removeEventListener("pointerup", this.onUp, true)
    document.removeEventListener("pointercancel", this.onUp, true)
    this.pending.clear()
    this.element.removeEventListener("submit", this.onSubmit, true)
    this.element.removeEventListener("focusout", this.onLeave)
    this.element.removeEventListener("input", this.onType)
    this.element.removeEventListener("change", this.onType)
  }

  isField(el) { return el?.matches?.(FIELDS) && el.willValidate }

  // Saiu do campo: com o ponteiro apertado (ou num toque que acabou agora, cujo clique ainda vem), adia a
  // marca para depois do clique; senão marca já.
  leave(f) {
    const toque = this.lastUp != null && performance.now() - this.lastUp < 400
    if (!this.pressing && !toque) return this.mark(f)
    this.pending.add(f)
    if (!this.pressing) setTimeout(() => this.flush(), 0)
  }

  flush() {
    const fields = [...this.pending]
    this.pending.clear()
    fields.forEach((f) => { if (f.isConnected && this.touched.has(f)) this.mark(f) })
  }

  submit(event) {
    if (event.submitter?.formNoValidate) return
    const fields = [...this.element.elements].filter((f) => this.isField(f))
    this.pending.clear()
    const bad = fields.filter((f) => { this.touched.add(f); return !this.mark(f) })
    if (!bad.length) return
    event.preventDefault()
    event.stopImmediatePropagation()
    bad[0].focus()
  }

  // Marca o campo (e o .ss-field dele) como certo ou errado; devolve se está válido.
  mark(f) {
    const ok = f.checkValidity()
    const box = f.closest(".ss-field")
    // Rádios e caixas do mesmo nome: o grupo inteiro.
    const peers = f.name && (f.type === "radio" || f.type === "checkbox") ? [...this.element.querySelectorAll(`[name="${CSS.escape(f.name)}"]`)] : [f]
    peers.forEach((p) => (ok ? p.removeAttribute("aria-invalid") : p.setAttribute("aria-invalid", "true")))
    if (!box) return ok
    box.classList.toggle("is-invalid", !ok)
    if (ok) return ok
    let err = box.querySelector(".ss-field-error")
    if (!err) {
      err = document.createElement("small")
      err.className = "ss-field-error"
      err.id = `${f.id || f.name || "ss-field"}_error`
      box.append(err)
      const ids = (f.getAttribute("aria-describedby") || "").split(/\s+/).filter(Boolean)
      if (!ids.includes(err.id)) f.setAttribute("aria-describedby", [...ids, err.id].join(" "))
    }
    // Vazio: o texto do servidor no campo ou o do form (data-ss-validate-required-value, no idioma da página);
    // o resto (e-mail, mínimo, padrão) é o do navegador.
    if (err.dataset.ssValidateText == null) err.dataset.ssValidateText = err.textContent.trim()
    const vazio = this.requiredValue || err.dataset.ssValidateText
    err.textContent = f.validity.valueMissing && vazio ? vazio : f.validationMessage
    return ok
  }
}
