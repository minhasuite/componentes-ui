import { Controller } from "@hotwired/stimulus"

// v0.11: densidade da interface (o SsDensity do Flutter): data-ss-density="compact|comfortable"
// no <html> (padrão: sem atributo) ou no contêiner do target-value, lembrada no navegador
// (chave ss-density) quando persist-value. Os botões levam data-ss-density-value-param.
//   <div data-controller="ss-density" data-ss-density-target-value="#tabela">
//     <button data-action="ss-density#set" data-ss-density-value-param="compact">Compacta</button>
// Várias instâncias ficam marcadas juntas (evento ss-density:change na window, com detail.density).
const VALID = ["compact", "standard", "comfortable"]

export default class extends Controller {
  static values = { persist: { type: Boolean, default: true }, target: String, default: { type: String, default: "standard" } }

  connect() {
    if (this.persistValue && !this.targetValue) {
      try { const v = localStorage.getItem("ss-density"); if (VALID.includes(v)) this.apply(v) } catch (_) {}
    }
    this.remark = () => this.mark()
    window.addEventListener("ss-density:change", this.remark)
    this.mark()
  }

  disconnect() { window.removeEventListener("ss-density:change", this.remark) }

  get root() {
    return (this.targetValue && document.querySelector(this.targetValue)) || document.documentElement
  }

  current() {
    const v = this.root.getAttribute("data-ss-density")
    return VALID.includes(v) ? v : (this.targetValue ? "standard" : (v || "standard"))
  }

  set({ params }) {
    const v = VALID.includes(params.value) ? params.value : "standard"
    this.apply(v)
    if (this.persistValue && !this.targetValue) { try { localStorage.setItem("ss-density", v) } catch (_) {} }
    window.dispatchEvent(new CustomEvent("ss-density:change", { detail: { density: v, target: this.targetValue || null } }))
  }

  apply(v) {
    // No <html> o padrão é a ausência do atributo; num contêiner, "standard" explícito
    // (para valer dentro de um <html data-ss-density="compact">).
    if (v === "standard" && !this.targetValue) this.root.removeAttribute("data-ss-density")
    else this.root.setAttribute("data-ss-density", v)
  }

  mark() {
    const cur = this.current()
    this.element.querySelectorAll("[data-ss-density-value-param]").forEach((b) => {
      b.setAttribute("aria-pressed", b.dataset.ssDensityValueParam === cur ? "true" : "false")
    })
  }
}
