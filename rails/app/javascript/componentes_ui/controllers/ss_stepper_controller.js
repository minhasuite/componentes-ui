import { Controller } from "@hotwired/stimulus"
import { reduced } from "componentes_ui/controllers/ss_motion_controller"

// Campo −/+ (Ss::StepperInputComponent). −/+ usam o stepDown/stepUp do próprio input (respeita
// min, max e step) e soltam input/change como se fosse digitado. Segurar repete (depois de
// 400 ms, a cada 90 ms). Nos limites, o botão do lado trava.
export default class extends Controller {
  static targets = ["input", "down", "up"]

  connect() { this.sync() }
  disconnect() { this.release() }

  // Clique pelo teclado (Enter/Espaço: detail 0); o do mouse/dedo já andou no pointerdown.
  down(e) { if (e.detail === 0) this.step(-1) }
  up(e) { if (e.detail === 0) this.step(1) }

  hold(e) {
    if (e.button !== 0 || e.currentTarget.disabled) return
    const dir = e.currentTarget === this.upTarget ? 1 : -1
    this.step(dir)
    this.release()
    this.wait = setTimeout(() => { this.rep = setInterval(() => this.step(dir), 90) }, 400)
  }

  release() { clearTimeout(this.wait); clearInterval(this.rep) }

  step(dir) {
    const i = this.inputTarget
    if (i.disabled) return
    const before = i.value
    if (i.value === "") i.value = i.min || 0
    try { dir > 0 ? i.stepUp() : i.stepDown() } catch { i.value = Number(i.value || 0) + dir * Number(i.step || 1) }
    if (i.value === before) return this.release()
    i.dispatchEvent(new Event("input", { bubbles: true }))
    i.dispatchEvent(new Event("change", { bubbles: true }))
    if (!reduced()) { i.classList.remove("is-bump"); void i.offsetWidth; i.classList.add("is-bump") }
  }

  // Ao sair do campo, prende entre min e max.
  clamp() {
    const i = this.inputTarget
    if (i.value === "") return this.sync()
    const v = Number(i.value)
    if (i.min !== "" && v < Number(i.min)) i.value = i.min
    if (i.max !== "" && v > Number(i.max)) i.value = i.max
    this.sync()
  }

  sync() {
    const i = this.inputTarget, v = Number(i.value)
    if (this.hasDownTarget) this.downTarget.disabled = i.disabled || (i.min !== "" && v <= Number(i.min))
    if (this.hasUpTarget) this.upTarget.disabled = i.disabled || (i.max !== "" && v >= Number(i.max))
    if (this.downTarget.disabled || this.upTarget.disabled) this.release()
  }
}
