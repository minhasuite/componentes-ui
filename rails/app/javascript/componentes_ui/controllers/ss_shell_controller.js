import { Controller } from "@hotwired/stimulus"

// Moldura do Ss::AppShellComponent: recolhe o menu (desktop, lembrado), abre a
// gaveta (celular), fecha com Esc/fundo e abre a busca (.ss-command) com Ctrl+K.
// Os textos de recolher/expandir vêm do componente (I18n), não daqui.
// searchAction: id do <dialog> que a busca abre (sem ele, o 1º dialog.ss-command).
//
// v0.10.1: o recolhido fica também no <html> (data-ss-shell-collapsed), que o Turbo não troca
// (nem no morph), e num cookie (ss_shell_collapsed=1/0) que o servidor lê para já desenhar
// recolhido. O ss_app_shell_head (inline no <head>) põe o atributo antes da 1ª pintura.
const KEY = "ss-shell-collapsed"
const COOKIE = "ss_shell_collapsed"
const HTML_ATTR = "data-ss-shell-collapsed"

// Escolha guardada: "1", "0" ou null (nunca escolheu).
function saved() {
  let v = null
  try { v = localStorage.getItem(KEY) } catch (_) {}
  if (v === "1" || v === "0") return v
  const m = document.cookie.match(/(?:^|;\s*)ss_shell_collapsed=([01])/)
  return m ? m[1] : null
}

function save(on) {
  const v = on ? "1" : "0"
  try { localStorage.setItem(KEY, v) } catch (_) {}
  document.cookie = `${COOKIE}=${v}; path=/; max-age=31536000; samesite=lax`
}

export default class extends Controller {
  static targets = ["side", "collapse", "burger"]
  static values = {
    searchAction: String,
    collapseLabel: { type: String, default: "Recolher menu" },
    expandLabel: { type: String, default: "Expandir menu" }
  }

  connect() {
    this.sync()
    this.closeOnVisit = () => this.close()
    // Depois de um morph o elemento é o mesmo (sem connect), mas os atributos voltam aos do servidor.
    this.onRender = () => this.sync()
    document.addEventListener("turbo:visit", this.closeOnVisit)
    document.addEventListener("turbo:morph", this.onRender)
    document.addEventListener("turbo:render", this.onRender)
  }

  disconnect() {
    document.removeEventListener("turbo:visit", this.closeOnVisit)
    document.removeEventListener("turbo:morph", this.onRender)
    document.removeEventListener("turbo:render", this.onRender)
  }

  // Escolha do usuário (vale para toda moldura da página, pelo <html>); sem ela, o
  // collapsed: do servidor (data-collapsed no elemento), sem mexer no <html>.
  sync() {
    const v = saved()
    if (v) this.setCollapsed(v === "1")
    else this.setCollapsed(this.element.hasAttribute("data-collapsed"), false)
  }

  get mobile() { return matchMedia("(max-width: 1023px)").matches }

  toggle() {
    if (this.mobile) return this.close()
    const on = !this.element.hasAttribute("data-collapsed")
    this.setCollapsed(on)
    save(on)
  }

  setCollapsed(on, global = true) {
    this.element.toggleAttribute("data-collapsed", on)
    if (global) document.documentElement.toggleAttribute(HTML_ATTR, on)
    if (this.hasCollapseTarget) {
      this.collapseTarget.setAttribute("aria-expanded", on ? "false" : "true")
      const label = on ? this.expandLabelValue : this.collapseLabelValue
      this.collapseTarget.setAttribute("aria-label", label); this.collapseTarget.title = label
    }
  }

  open() {
    this.element.setAttribute("data-open", "")
    if (this.hasBurgerTarget) this.burgerTarget.setAttribute("aria-expanded", "true")
    this.sideTarget.querySelector("a, summary, button")?.focus()
  }

  close() {
    if (!this.element.hasAttribute("data-open")) return
    this.element.removeAttribute("data-open")
    if (this.hasBurgerTarget) { this.burgerTarget.setAttribute("aria-expanded", "false"); this.burgerTarget.focus() }
  }

  search(event) {
    // Ctrl+K com uma paleta ss-command de atalho na página: ela mesma abre (não abre duas vezes).
    if (event?.type === "keydown" && document.querySelector('[data-controller~="ss-command"][data-ss-command-shortcut-value]:not([data-ss-command-shortcut-value=""])')) return
    // O app pode tratar a busca do jeito dele (preventDefault no "ss-shell:search").
    const ev = this.dispatch("search", { cancelable: true, detail: { action: this.searchActionValue } })
    if (ev.defaultPrevented) return
    const dialog = this.searchActionValue ? document.getElementById(this.searchActionValue) : document.querySelector("dialog.ss-command")
    if (!dialog) return
    this.close()
    if (dialog.matches('[data-controller~="ss-command"]')) return dialog.dispatchEvent(new CustomEvent("ss-command:open"))
    if (dialog.open) return
    dialog.showModal()
    dialog.querySelector("input")?.focus()
  }
}
