import { Controller } from "@hotwired/stimulus"

// Ss::DateStripComponent (v1.9, par do SsDateStrip). --i no .ss-date-strip-days é o dia escolhido (0 = dia 1):
// a pílula anda por transição, então o morph do Turbo e o clique (que já move a pílula antes de a página
// chegar) deslizam. Ao ligar, a faixa rola para o escolhido ficar no meio. pick() abre o calendário do
// navegador (input date) e jump() vai para a url do dia escolhido lá. ← → andam o foco entre os dias.
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

export default class extends Controller {
  static targets = ["scroller", "day", "picker"]
  static values = { url: String, frame: String }

  connect() { this.center(false) }

  center(smooth = true) {
    const sel = this.dayTargets.find((d) => d.hasAttribute("aria-current")) || this.dayTargets[0]
    if (!sel || !this.hasScrollerTarget) return
    const s = this.scrollerTarget
    s.scrollTo({ left: sel.offsetLeft + sel.offsetWidth / 2 - s.clientWidth / 2, behavior: smooth && !reduced() ? "smooth" : "auto" })
  }

  choose(e) {
    const day = e.currentTarget
    this.dayTargets.forEach((d) => { d.removeAttribute("aria-current"); d.tabIndex = -1 })
    day.setAttribute("aria-current", "date")
    day.removeAttribute("tabindex")
    this.scrollerTarget.style.setProperty("--i", day.dataset.index)
    this.center()
  }

  key(e) {
    const days = this.dayTargets
    const i = days.indexOf(document.activeElement)
    if (i < 0) return
    const j = e.key === "ArrowRight" ? i + 1 : e.key === "ArrowLeft" ? i - 1 : e.key === "Home" ? 0 : e.key === "End" ? days.length - 1 : null
    if (j === null || !days[j]) return
    e.preventDefault()
    days[j].focus()
  }

  pick() {
    const p = this.pickerTarget
    try { p.showPicker() } catch { p.focus(); p.click() }
  }

  jump() {
    const v = this.pickerTarget.value
    if (!v || !this.urlValue) return
    const url = this.urlValue.replace("%{date}", v)
    if (window.Turbo) window.Turbo.visit(url, this.frameValue ? { frame: this.frameValue } : {})
    else window.location.href = url
  }
}
