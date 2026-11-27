import { Controller } from "@hotwired/stimulus"

// Inclinação leve que segue o ponteiro (v0.19; o cartão físico, Ss::WalletCardComponent; v1.14.0: o
// Ss::TiltCardComponent, par do SsTiltCard): gira até ~6° e move o reflexo (--ss-mx/--ss-my). Com o mouse, ao
// passar por cima; no toque (v1.14.0), enquanto o dedo está apertado no cartão (sem travar a rolagem: o cartão
// tem touch-action: pan-y). Nada com reduzir movimento, nem com data-ss-tilt-off (cartão em tela de dados densos).
//   <div class="ss-wallet-card" data-controller="ss-tilt">…</div>
const PROPS = ["--ss-rx", "--ss-ry", "--ss-mx", "--ss-my"]

export default class extends Controller {
  connect() {
    if (matchMedia("(prefers-reduced-motion: reduce)").matches || this.element.hasAttribute("data-ss-tilt-off")) return
    const fine = matchMedia("(hover: hover) and (pointer: fine)").matches
    this.move = (e) => {
      if (e.pointerType === "mouse" ? !fine : !this.pressed) return
      const r = this.element.getBoundingClientRect()
      const x = Math.min(Math.max((e.clientX - r.left) / r.width, 0), 1)
      const y = Math.min(Math.max((e.clientY - r.top) / r.height, 0), 1)
      this.element.classList.add("is-tilting")
      this.element.style.setProperty("--ss-rx", `${((0.5 - y) * 10).toFixed(2)}deg`)
      this.element.style.setProperty("--ss-ry", `${((x - 0.5) * 12).toFixed(2)}deg`)
      this.element.style.setProperty("--ss-mx", `${(x * 100).toFixed(1)}%`)
      this.element.style.setProperty("--ss-my", `${(y * 100).toFixed(1)}%`)
    }
    this.down = (e) => { if (e.pointerType !== "mouse") { this.pressed = true; this.move(e) } }
    this.leave = (e) => {
      if (e.type === "pointerleave" && e.pointerType !== "mouse" && this.pressed) return
      this.pressed = false
      this.element.classList.remove("is-tilting")
      PROPS.forEach((p) => this.element.style.removeProperty(p))
    }
    this.element.addEventListener("pointermove", this.move)
    this.element.addEventListener("pointerdown", this.down)
    this.element.addEventListener("pointerup", this.leave)
    this.element.addEventListener("pointercancel", this.leave)
    this.element.addEventListener("pointerleave", this.leave)
  }

  disconnect() {
    if (!this.move) return
    this.element.removeEventListener("pointermove", this.move)
    this.element.removeEventListener("pointerdown", this.down)
    this.element.removeEventListener("pointerup", this.leave)
    this.element.removeEventListener("pointercancel", this.leave)
    this.element.removeEventListener("pointerleave", this.leave)
  }
}
