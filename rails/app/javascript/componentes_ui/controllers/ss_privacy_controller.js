import { Controller } from "@hotwired/stimulus"

// Esconder valores (v0.10.2): liga/desliga [data-privacy="on"] no <html>, que borra .money,
// .ss-amount, gráficos e o resto que a gem marca (engine.css). Lembra neste navegador.
// Botão: data-action="ss-privacy#toggle" (.ss-eye-on/.ss-eye-off trocam o ícone). Tecla P
// fora de campo: data-action="keydown.p@window->ss-privacy#key".
export default class extends Controller {
  static values = { key: { type: String, default: "ss-privacy" } }

  connect() {
    try {
      const saved = localStorage.getItem(this.keyValue)
      if (saved) document.documentElement.dataset.privacy = saved
    } catch (_) {}
    this.sync()
  }

  toggle() {
    const on = document.documentElement.dataset.privacy !== "on"
    document.documentElement.dataset.privacy = on ? "on" : "off"
    try { localStorage.setItem(this.keyValue, on ? "on" : "off") } catch (_) {}
    this.sync()
    this.dispatch("change", { prefix: "ss-privacy", detail: { on } })
  }

  key(e) {
    if (e.ctrlKey || e.metaKey || e.altKey || e.target.closest?.("input, textarea, select, [contenteditable]")) return
    e.preventDefault()
    this.toggle()
  }

  sync() {
    const on = document.documentElement.dataset.privacy === "on"
    this.element.querySelectorAll("[data-action*='ss-privacy#toggle']").forEach((b) => b.setAttribute("aria-pressed", on))
    if (this.element.matches("[data-action*='ss-privacy#toggle']")) this.element.setAttribute("aria-pressed", on)
  }
}
