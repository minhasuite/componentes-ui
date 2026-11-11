import { Controller } from "@hotwired/stimulus"

// v0.21 · micro-animação de mudança de estado da casa (par do SsCue do Flutter):
// ligou (on), abriu (open), alguém chegou (arrive). Toca uma vez quando o estado
// vira "ativo" (active true) e nunca na primeira pintura da página.
//
//   <div class="ss-cue" data-controller="ss-cue" data-ss-cue-kind-value="on"
//        data-ss-cue-active-value="true" data-ss-cue-key-value="w12-p3">…</div>
//   (ou ss_cue_attrs(kind: :on, active: true, key: "w12-p3") no ERB)
//
// `key` identifica o mesmo objeto entre trocas do HTML (Turbo Frame/Stream refaz o
// elemento a cada mudança): o estado anterior fica num mapa por chave, e a troca
// de falso para verdadeiro acena. Sem `key`, só a mudança do atributo no mesmo
// elemento acena. "Menos movimento" (prefers-reduced-motion) desliga.
const seen = new Map()
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

export default class extends Controller {
  static values = { kind: { type: String, default: "on" }, active: Boolean, key: String }

  activeValueChanged(now) {
    const before = this.hasKeyValue && this.keyValue ? seen.get(this.keyValue) : this.last
    if (this.hasKeyValue && this.keyValue) seen.set(this.keyValue, now)
    this.last = now
    if (before === false && now) this.play()
  }

  play() {
    if (reduced()) return
    const el = this.element
    el.classList.remove("is-cueing")
    void el.offsetWidth // reinicia a animação
    el.classList.add("is-cueing")
    clearTimeout(this.timer)
    this.timer = setTimeout(() => el.classList.remove("is-cueing"), 900)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
