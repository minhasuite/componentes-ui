import { Controller } from "@hotwired/stimulus"

// Ss::BurstComponent (v1.9, par do SsBurst): play() põe um .ss-burst-fx com N <i> (um por ângulo, começando no
// alto; os ímpares mais curtos) que o CSS anima para fora e apaga; sai ao terminar. --r é o raio de partida.
// changed(): só toca quando o input que mudou ficou marcado. Por JS: el.dispatchEvent(new Event("ss:burst")).
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

export default class extends Controller {
  static values = { count: { type: Number, default: 7 }, distance: { type: Number, default: 14 }, radius: Number, auto: Boolean }

  connect() { if (this.autoValue) requestAnimationFrame(() => this.play()) }
  disconnect() { this.fx?.remove() }

  changed(e) { if (e.target?.checked) this.play() }

  play() {
    if (reduced()) return
    this.fx?.remove()
    const box = this.element.getBoundingClientRect()
    const r = (this.hasRadiusValue && this.radiusValue > 0 ? this.radiusValue : Math.min(box.width, box.height) / 2) + 2
    const fx = document.createElement("span")
    fx.className = "ss-burst-fx"
    fx.setAttribute("aria-hidden", "true")
    fx.style.setProperty("--r", `${r}px`)
    fx.style.setProperty("--dist", `${this.distanceValue}px`)
    for (let i = 0; i < this.countValue; i++) {
      const ray = document.createElement("i")
      ray.style.setProperty("--a", `${(360 * i) / this.countValue}deg`)
      ray.style.setProperty("--len", i % 2 ? "3px" : "4.5px")
      fx.append(ray)
    }
    this.element.append(fx)
    this.fx = fx
    fx.addEventListener("animationend", () => { if (this.fx === fx) { fx.remove(); this.fx = null } }, { once: true })
  }
}
