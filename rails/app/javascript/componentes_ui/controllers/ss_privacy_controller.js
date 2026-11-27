import { Controller } from "@hotwired/stimulus"

// Esconder valores (v0.10.2): liga/desliga [data-privacy="on"] no <html>, que borra .money,
// .ss-amount, gráficos e o resto que a gem marca (engine.css). Lembra neste navegador.
// Botão: data-action="ss-privacy#toggle" (.ss-eye-on/.ss-eye-off trocam o ícone). Tecla P
// fora de campo: data-action="keydown.p@window->ss-privacy#key".
//
// v1.13.0 (par do SsPrivacyScope(auto:)): data-ss-privacy-auto-value="true" liga o modo discreto automático. Esconde
// quando a aba sai da frente (visibilitychange: a miniatura do alternador de janelas não mostra os valores) e enquanto
// esta página compartilha a tela (getDisplayMedia; o compartilhamento feito por outro programa o navegador não conta).
// O produto liga e desliga os próprios sinais: window.dispatchEvent(new CustomEvent("ss-privacy:auto",
// { detail: { reason: "share", on: true } })). Com algum motivo, <html data-privacy="on" data-privacy-auto="share">;
// sem nenhum, volta a escolha da pessoa. O botão continua valendo (a escolha é guardada; o automático vence enquanto dura).
let displayPatched = false
const reasonsOn = new Set()

export default class extends Controller {
  static values = { key: { type: String, default: "ss-privacy" }, auto: Boolean }

  connect() {
    try {
      const saved = localStorage.getItem(this.keyValue)
      if (saved) document.documentElement.dataset.privacy = saved
    } catch (_) {}
    this.sync()
    if (this.autoValue) this.watch()
  }

  disconnect() {
    if (!this.onVisibility) return
    document.removeEventListener("visibilitychange", this.onVisibility)
    window.removeEventListener("ss-privacy:auto", this.onAuto)
  }

  watch() {
    this.onVisibility = () => this.reason("background", document.visibilityState === "hidden")
    this.onAuto = (e) => this.reason(String(e.detail?.reason ?? "app"), e.detail?.on !== false)
    document.addEventListener("visibilitychange", this.onVisibility)
    window.addEventListener("ss-privacy:auto", this.onAuto)
    const md = navigator.mediaDevices
    if (displayPatched || !md?.getDisplayMedia) return
    displayPatched = true
    const original = md.getDisplayMedia.bind(md)
    md.getDisplayMedia = async (...args) => {
      const stream = await original(...args)
      const fire = (on) => window.dispatchEvent(new CustomEvent("ss-privacy:auto", { detail: { reason: "share", on } }))
      fire(true)
      const tracks = stream.getTracks()
      tracks.forEach((t) => t.addEventListener("ended", () => { if (tracks.every((x) => x.readyState === "ended")) fire(false) }))
      return stream
    }
  }

  saved() {
    try { return localStorage.getItem(this.keyValue) || "off" } catch (_) { return "off" }
  }

  reason(name, on) {
    on ? reasonsOn.add(name) : reasonsOn.delete(name)
    const html = document.documentElement
    if (reasonsOn.size) {
      html.dataset.privacy = "on"
      html.dataset.privacyAuto = [...reasonsOn].join(" ")
    } else {
      delete html.dataset.privacyAuto
      html.dataset.privacy = this.saved()
    }
    this.sync()
    this.dispatch("auto", { prefix: "ss-privacy", detail: { reasons: [...reasonsOn] } })
  }

  toggle() {
    const html = document.documentElement
    const on = (html.dataset.privacyAuto ? this.saved() : html.dataset.privacy) !== "on"
    if (!html.dataset.privacyAuto) html.dataset.privacy = on ? "on" : "off"
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
