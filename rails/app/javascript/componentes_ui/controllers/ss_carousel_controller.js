import { Controller } from "@hotwired/stimulus"
import { ssFormat } from "componentes_ui/controllers/ss_intl"

// Ss::SnapCarouselComponent (v1.9, par do SsSnapCarousel): scroll-snap no centro; a cada rolagem, --d (0..1, a
// distância do item ao meio em larguras de item) encolhe e apaga os vizinhos; o item do meio ganha data-current,
// as bolinhas/contador seguem e sai "ss-carousel:change" { index }. ← → andam um item.
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

export default class extends Controller {
  static targets = ["track", "slide", "dots", "count", "prev", "next"]
  static values = { index: Number, of: String }

  connect() {
    this.current = this.indexValue
    requestAnimationFrame(() => { this.go(this.current, false); this.paint() })
  }

  disconnect() { cancelAnimationFrame(this.frame) }

  scrolled() {
    cancelAnimationFrame(this.frame)
    this.frame = requestAnimationFrame(() => this.paint())
  }

  paint() {
    const t = this.trackTarget
    const mid = t.scrollLeft + t.clientWidth / 2
    let best = 0, bestD = Infinity
    this.slideTargets.forEach((s, i) => {
      const c = s.offsetLeft + s.offsetWidth / 2
      const d = Math.abs(c - mid) / Math.max(1, s.offsetWidth)
      if (d < bestD) { bestD = d; best = i }
      s.style.setProperty("--d", Math.min(1, d).toFixed(3))
    })
    if (best !== this.current) {
      this.current = best
      navigator.vibrate?.(4)
      this.dispatch("change", { detail: { index: best }, prefix: "ss-carousel" })
    }
    const n = this.slideTargets.length
    this.slideTargets.forEach((s, i) => s.toggleAttribute("data-current", i === best))
    if (this.hasDotsTarget) [...this.dotsTarget.children].forEach((d, i) => d.toggleAttribute("data-current", i === best))
    if (this.hasCountTarget) {
      const text = `${best + 1}/${n}`
      if (this.countTarget.textContent !== text) this.countTarget.textContent = text
      this.countTarget.setAttribute("aria-label", ssFormat(this.ofValue, { n: best + 1, total: n }))
    }
    if (this.hasPrevTarget) this.prevTarget.disabled = best === 0
    if (this.hasNextTarget) this.nextTarget.disabled = best === n - 1
  }

  go(i, smooth = true) {
    const s = this.slideTargets[Math.max(0, Math.min(this.slideTargets.length - 1, i))]
    if (!s) return
    const t = this.trackTarget
    const left = s.offsetLeft + s.offsetWidth / 2 - t.clientWidth / 2
    t.scrollTo({ left, behavior: smooth && !reduced() ? "smooth" : "auto" })
  }

  prev() { this.go(this.current - 1) }
  next() { this.go(this.current + 1) }

  key(e) {
    if (e.target !== this.trackTarget) return
    if (e.key === "ArrowLeft") { e.preventDefault(); this.prev() }
    if (e.key === "ArrowRight") { e.preventDefault(); this.next() }
  }
}
