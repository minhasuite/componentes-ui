import { Controller } from "@hotwired/stimulus"

// Faixa que rola de lado (.ss-chips, .ss-subnav, .ss-tabs, v0.10.3): ao abrir, rola só a faixa
// (nunca a página) até o item atual ficar à vista, mais ou menos no meio. Atual é
// [aria-current] (true/page/…), [aria-selected=true], .is-active ou um chip com input :checked.
// Clicar num chip de rádio/checkbox também traz ele para a vista. Sem animação com "reduzir movimento".
const CURRENT = '[aria-current]:not([aria-current="false"]), [aria-selected="true"], .is-active, :has(> input:checked)'

export default class extends Controller {
  connect() {
    this.onChange = (e) => { const item = e.target.closest("label, a, button"); if (item) this.reveal(item, true) }
    this.element.addEventListener("change", this.onChange)
    requestAnimationFrame(() => this.reveal(this.element.querySelector(CURRENT), false))
  }

  disconnect() { this.element.removeEventListener("change", this.onChange) }

  reveal(item, smooth) {
    const box = this.element
    if (!item || box.scrollWidth <= box.clientWidth + 1) return
    const a = box.getBoundingClientRect(), b = item.getBoundingClientRect()
    if (b.left >= a.left && b.right <= a.right - 24) return
    const left = box.scrollLeft + (b.left - a.left) - (box.clientWidth - b.width) / 2
    const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches || document.documentElement.classList.contains("ss-reduce-motion")
    box.scrollTo({ left: Math.max(0, left), behavior: smooth && !reduce ? "smooth" : "auto" })
  }
}
