import { Controller } from "@hotwired/stimulus"
import { reduced } from "componentes_ui/controllers/ss_motion_controller"

// Ss::TabsComponent: troca de painel e teclado (← → Home End). Abas-link só movem o foco.
// O sublinhado é do ss-indicator na lista (desliza com mola e estica no caminho); sem ele
// (marcação antiga), este controller ainda posiciona o .ss-tabs-ink por --x/--w.
// Trocou de aba: o rótulo novo sobe 2 px e volta com a mola enquanto a cor vai para a da
// marca (a cor é transição do CSS; a antiga volta ao muted).
// Faixa que rola (muitas abas): a aba marcada entra na vista ao conectar e ao trocar. Rola
// só a faixa (nunca a página) e, com menos movimento, sem animação.
export default class extends Controller {
  static targets = ["list", "tab", "panel"]

  connect() {
    this.reveal(this.current, false)
    if (this.indicator) return
    this.move()
    this.ro = new ResizeObserver(() => this.move())
    this.ro.observe(this.listTarget)
    document.fonts?.ready.then(() => this.move())
  }

  disconnect() { this.ro?.disconnect() }

  get current() {
    return this.tabTargets.find((t) => t.getAttribute("aria-selected") === "true" || t.getAttribute("aria-current") === "page")
  }

  select(event) { this.activate(event.currentTarget) }

  activate(tab) {
    if (tab.tagName === "A") return
    const was = this.current
    this.tabTargets.forEach((t) => {
      if (t.tagName === "A") return
      const on = t === tab
      t.setAttribute("aria-selected", on ? "true" : "false")
      t.tabIndex = on ? 0 : -1
    })
    this.panelTargets.forEach((p) => {
      p.hidden = p.id !== tab.getAttribute("aria-controls")
      // Frame preguiçoso: carrega ao abrir a aba (não depende do IntersectionObserver).
      if (!p.hidden) p.querySelectorAll('turbo-frame[loading="lazy"]').forEach((f) => f.setAttribute("loading", "eager"))
    })
    this.move()
    this.reveal(tab, true)
    if (tab !== was) this.lift(tab)
    this.dispatch("change", { detail: { tab } })
  }

  key(event) {
    const tabs = this.tabTargets
    const i = tabs.indexOf(document.activeElement)
    if (i < 0) return
    let next = null
    if (event.key === "ArrowRight") next = tabs[(i + 1) % tabs.length]
    else if (event.key === "ArrowLeft") next = tabs[(i - 1 + tabs.length) % tabs.length]
    else if (event.key === "Home") next = tabs[0]
    else if (event.key === "End") next = tabs[tabs.length - 1]
    if (!next) return
    event.preventDefault()
    next.focus()
    this.activate(next)
  }

  // Traz a aba para dentro da faixa (com uma folga para mostrar que há mais ao lado).
  reveal(tab, smooth) {
    const list = this.hasListTarget && this.listTarget
    if (!tab || !list || list.scrollWidth <= list.clientWidth + 1) return
    const a = list.getBoundingClientRect(), b = tab.getBoundingClientRect()
    const pad = 24
    const left = b.left - a.left + list.scrollLeft, right = left + b.width
    let to = null
    if (left - pad < list.scrollLeft) to = left - pad
    else if (right + pad > list.scrollLeft + list.clientWidth) to = right + pad - list.clientWidth
    if (to == null) return
    list.scrollTo({ left: Math.max(0, to), behavior: smooth && !reduced() ? "smooth" : "auto" })
  }

  lift(tab) {
    if (reduced() || !tab.animate) return
    const bounce = getComputedStyle(tab).getPropertyValue("--ss-bounce").trim() || "cubic-bezier(.34, 1.56, .64, 1)"
    tab.animate([
      { translate: "0 0", easing: "cubic-bezier(.3, .7, .4, 1)" },
      { translate: "0 -2px", offset: 0.3, easing: bounce },
      { translate: "0 0" }
    ], { duration: 520 })
  }

  get indicator() { return this.listTarget.matches('[data-controller~="ss-indicator"]') }

  move() {
    if (this.indicator) return
    const tab = this.current
    if (!tab) { this.listTarget.style.setProperty("--w", "0px"); return }
    this.listTarget.style.setProperty("--x", `${tab.offsetLeft}px`)
    this.listTarget.style.setProperty("--w", `${tab.offsetWidth}px`)
    this.listTarget.setAttribute("data-ready", "")
  }
}
