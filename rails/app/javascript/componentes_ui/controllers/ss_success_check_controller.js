import { Controller } from "@hotwired/stimulus"
import { haptic } from "componentes_ui/controllers/ss_haptics_controller"

// v1.14.0 · Ss::SuccessCheckComponent (par do SsSuccessCheck): quando aparece, o check se desenha (CSS: .is-drawn)
// com a vibração de sucesso e, com sound, o gancho do som: `ss:sound` { name: "success" } no window, que o produto
// ouve e toca (window.addEventListener("ss:sound", (e) => meuAudio[e.detail.name]?.play())). O pacote não traz áudio.
// As peças que terminam em ✓ (MorphButton, SwipeToConfirm, PixCard) chamam o ssSuccess daqui.
export function ssSuccess(el, { sound = false, vibrate = true } = {}) {
  if (vibrate) haptic("success")
  if (sound) window.dispatchEvent(new CustomEvent("ss:sound", { detail: { name: "success", source: el } }))
}

export default class extends Controller {
  static values = { sound: Boolean, haptic: { type: Boolean, default: true } }

  connect() {
    // Toca uma vez, quando fica visível (entra na tela ou o pai deixa de estar escondido).
    this.io = new IntersectionObserver((entries) => {
      if (!entries.some((e) => e.isIntersecting)) return
      this.io.disconnect()
      this.play()
    })
    this.io.observe(this.element)
  }

  disconnect() { this.io?.disconnect() }

  play() {
    this.element.classList.remove("is-drawn")
    void this.element.offsetWidth
    this.element.classList.add("is-drawn")
    ssSuccess(this.element, { sound: this.soundValue, vibrate: this.hapticValue })
  }
}
