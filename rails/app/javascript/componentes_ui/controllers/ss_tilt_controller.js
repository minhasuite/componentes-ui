import { Controller } from "@hotwired/stimulus"

// Inclinação leve que segue o mouse (v0.19; o cartão físico, Ss::WalletCardComponent): gira até ~6°
// e move o brilho (--ss-mx/--ss-my). Só onde há hover de verdade; nada no toque nem com menos movimento.
//   <div class="ss-wallet-card" data-controller="ss-tilt">…</div>
export default class extends Controller {
  connect() {
    if (matchMedia("(prefers-reduced-motion: reduce)").matches || !matchMedia("(hover: hover) and (pointer: fine)").matches) return
    this.move = (e) => {
      const r = this.element.getBoundingClientRect()
      const x = (e.clientX - r.left) / r.width
      const y = (e.clientY - r.top) / r.height
      this.element.style.setProperty("--ss-rx", `${((0.5 - y) * 10).toFixed(2)}deg`)
      this.element.style.setProperty("--ss-ry", `${((x - 0.5) * 12).toFixed(2)}deg`)
      this.element.style.setProperty("--ss-mx", `${(x * 100).toFixed(1)}%`)
      this.element.style.setProperty("--ss-my", `${(y * 100).toFixed(1)}%`)
    }
    this.leave = () => { ["--ss-rx", "--ss-ry", "--ss-mx", "--ss-my"].forEach((p) => this.element.style.removeProperty(p)) }
    this.element.addEventListener("mousemove", this.move)
    this.element.addEventListener("mouseleave", this.leave)
  }

  disconnect() {
    if (!this.move) return
    this.element.removeEventListener("mousemove", this.move)
    this.element.removeEventListener("mouseleave", this.leave)
  }
}
