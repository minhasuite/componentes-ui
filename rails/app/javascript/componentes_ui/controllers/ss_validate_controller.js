import { Controller } from "@hotwired/stimulus"

// v0.24 (auditoria de UX, B13): validação do formulário da gem no lugar do balão nativo.
// O ss_form_with liga este controller no <form>. Ao conectar, o form ganha novalidate: o navegador para de
// mostrar "Preencha este campo" como dica ao passar o mouse (o Chrome usa a mensagem de validação como
// tooltip do campo inválido enquanto o form valida sozinho) e o balão do envio. A regra continua a do HTML
// (required, type, pattern, min/max, maxlength) e a mensagem aparece embaixo do campo (.ss-field-error):
// ao sair do campo e ao tentar enviar; o 1º campo errado recebe o foco e o envio para. Corrigindo, a mensagem
// some enquanto digita. Sem JS o form segue com a validação do navegador (o novalidate vem daqui).
// Botão com formnovalidate (salvar rascunho) envia sem conferir.
const FIELDS = "input:not([type=hidden]):not([type=submit]):not([type=button]):not([type=reset]), select, textarea"

export default class extends Controller {
  static values = { required: String }

  connect() {
    this.touched = new WeakSet()
    this.element.noValidate = true
    // Captura no próprio form: roda antes do ss-dirty e do Turbo, que olham o mesmo submit.
    this.onSubmit = (e) => this.submit(e)
    this.onLeave = (e) => { if (this.isField(e.target)) { this.touched.add(e.target); this.mark(e.target) } }
    this.onType = (e) => { if (this.isField(e.target) && this.touched.has(e.target)) this.mark(e.target) }
    this.element.addEventListener("submit", this.onSubmit, true)
    this.element.addEventListener("focusout", this.onLeave)
    this.element.addEventListener("input", this.onType)
    this.element.addEventListener("change", this.onType)
  }

  disconnect() {
    this.element.removeEventListener("submit", this.onSubmit, true)
    this.element.removeEventListener("focusout", this.onLeave)
    this.element.removeEventListener("input", this.onType)
    this.element.removeEventListener("change", this.onType)
  }

  isField(el) { return el?.matches?.(FIELDS) && el.willValidate }

  submit(event) {
    if (event.submitter?.formNoValidate) return
    const fields = [...this.element.elements].filter((f) => this.isField(f))
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
