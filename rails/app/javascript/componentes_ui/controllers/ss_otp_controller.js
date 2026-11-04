import { Controller } from "@hotwired/stimulus"

// Código em caixinhas: digitar pula para a próxima, Backspace volta, colar preenche todas.
// Movimento: cada dígito que entra estala a caixinha (colar = em cascata) e, completo, passa
// uma onda curta. WAAPI no `scale`/`translate` (não briga com o transform do foco).
export default class extends Controller {
  static targets = ["box", "hidden"]

  type(e) {
    const box = e.target
    const digits = box.value.replace(/\D/g, "")
    if (digits.length > 1) return this.fill(digits, this.boxTargets.indexOf(box))
    box.value = digits
    if (digits) { this.pop(box); this.focus(this.boxTargets.indexOf(box) + 1) }
    this.update()
  }

  key(e) {
    const i = this.boxTargets.indexOf(e.target)
    if (e.key === "Backspace" && !e.target.value) { e.preventDefault(); this.focus(i - 1, true) }
    else if (e.key === "ArrowLeft") { e.preventDefault(); this.focus(i - 1) }
    else if (e.key === "ArrowRight") { e.preventDefault(); this.focus(i + 1) }
  }

  paste(e) {
    e.preventDefault()
    this.fill((e.clipboardData || window.clipboardData).getData("text").replace(/\D/g, ""), this.boxTargets.indexOf(e.target))
  }

  fill(digits, from = 0) {
    const start = digits.length >= this.boxTargets.length ? 0 : from
    ;[...digits].slice(0, this.boxTargets.length - start).forEach((d, n) => { this.boxTargets[start + n].value = d; this.pop(this.boxTargets[start + n], n * 35) })
    this.focus(Math.min(start + digits.length, this.boxTargets.length - 1))
    this.update()
  }

  select(e) { e.target.select() }

  focus(i, clear = false) {
    const b = this.boxTargets[i]
    if (!b) return
    if (clear) b.value = ""
    b.focus(); b.select()
    if (clear) this.update()
  }

  update() {
    const code = this.boxTargets.map((b) => b.value).join("")
    const complete = code.length === this.boxTargets.length
    this.hiddenTarget.value = code
    if (complete && !this.element.classList.contains("is-complete")) this.wave()
    this.element.classList.toggle("is-complete", complete)
    if (complete) this.dispatch("complete", { detail: { code } })
  }

  get still() { return matchMedia("(prefers-reduced-motion: reduce)").matches || !Element.prototype.animate }

  get bounce() {
    const v = getComputedStyle(this.element).getPropertyValue("--ss-bounce").trim()
    return v && CSS.supports?.("transition-timing-function", v) ? v : "cubic-bezier(.34, 1.56, .64, 1)"
  }

  pop(box, delay = 0) {
    if (this.still) return
    box.animate([{ scale: 0.86 }, { scale: 1 }], { duration: 360, delay, easing: this.bounce, fill: "backwards" })
  }

  wave() {
    if (this.still) return
    this.boxTargets.forEach((b, n) => b.animate([{ translate: "0 0" }, { translate: "0 -4px", offset: 0.4 }, { translate: "0 0" }],
      { duration: 380, delay: 120 + n * 45, easing: "ease-in-out" }))
  }
}
