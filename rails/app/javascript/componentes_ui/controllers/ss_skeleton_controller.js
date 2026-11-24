import { Controller } from "@hotwired/stimulus"
import { reduced } from "componentes_ui/controllers/ss_motion_controller"

// v1.9 · skeleton que vira conteúdo (par do SsSkeletonSwitch do Flutter). Vai no <turbo-frame> do
// Ss::SkeletonComponent(frame:) (o componente já liga). Quando o frame chega, em vez da troca seca:
// uma cópia do esqueleto fica por cima esmaecendo (.ss-skel-ghost) enquanto o conteúdo novo aparece e
// sobe --ss-dist-medium (.ss-skel-in, --ss-dur-medium com --ss-ease-enter): o crossfade.
// Só anima a troca que sai do esqueleto; navegar dentro do frame depois troca normal. Menos movimento:
// troca direto. Sem frame (Turbo Stream que substitui o .ss-skel), ponha a classe .ss-skel-in no conteúdo.
export default class extends Controller {
  connect() {
    this.onRender = (e) => this.wrap(e)
    this.element.addEventListener("turbo:before-frame-render", this.onRender)
  }

  disconnect() {
    this.element.removeEventListener("turbo:before-frame-render", this.onRender)
  }

  wrap(event) {
    const frame = this.element
    const skel = frame.querySelector(":scope > .ss-skel")
    if (!skel || reduced() || !event.detail?.render) return
    const original = event.detail.render
    event.detail.render = async (current, next) => {
      const f = frame.getBoundingClientRect(), r = skel.getBoundingClientRect()
      const ghost = skel.cloneNode(true)
      ghost.classList.add("ss-skel-ghost")
      ghost.removeAttribute("role")
      ghost.removeAttribute("aria-busy")
      ghost.setAttribute("aria-hidden", "true")
      Object.assign(ghost.style, { left: `${r.left - f.left}px`, top: `${r.top - f.top}px`, width: `${r.width}px` })
      await original(current, next)
      frame.classList.add("is-ss-revealing")
      ;[...frame.children].forEach((c) => {
        c.classList.add("ss-skel-in")
        c.addEventListener("animationend", () => c.classList.remove("ss-skel-in"), { once: true })
      })
      frame.append(ghost)
      const done = () => { ghost.remove(); frame.classList.remove("is-ss-revealing") }
      ghost.addEventListener("animationend", done, { once: true })
      setTimeout(done, 1000)
    }
  }
}
