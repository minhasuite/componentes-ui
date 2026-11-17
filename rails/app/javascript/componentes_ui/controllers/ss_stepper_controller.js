import { Controller } from "@hotwired/stimulus"
import { reduced } from "componentes_ui/controllers/ss_motion_controller"

// Campo −/+ (Ss::StepperInputComponent). −/+ usam o stepDown/stepUp do próprio input (respeita
// min, max e step) e soltam input/change como se fosse digitado. Segurar repete (depois de
// 400 ms, a cada 90 ms). Nos limites, o botão do lado trava.
// v1.2.1: com decimals (StepperInputComponent(decimals: N)) o campo é texto no idioma da página ("0,5"):
// lê e escreve pelo Intl com o lang do <html>, faz a conta do −/+ aqui (texto não tem stepUp) e copia o
// valor com ponto para o hidden com o name (target raw), que é o que vai ao servidor.
export default class extends Controller {
  static targets = ["input", "down", "up", "raw"]
  static values = { decimals: Number }

  get decimal() { return this.decimalsValue > 0 }
  get lang() { return document.documentElement.lang || undefined }
  limit(name) { const i = this.inputTarget, v = this.decimal ? i.dataset[name] : i[name]; return v === undefined || v === "" ? null : Number(v) }

  // Texto do idioma → número ("1.234,5" → 1234.5; "0.5" também vale). Vazio = null.
  parse(text) {
    const t = String(text ?? "").trim().replace(/\s/g, "")
    if (t === "") return null
    const sep = new Intl.NumberFormat(this.lang).format(1.5).charAt(1)
    // Com vírgula de decimal, o ponto só é milhar quando há vírgula ("1.234,5"); "0.5" sozinho é meio.
    const n = Number(sep === "," ? (t.includes(",") ? t.replace(/\./g, "").replace(",", ".") : t) : t.replace(/,/g, ""))
    return Number.isFinite(n) ? n : null
  }

  format(n) {
    return new Intl.NumberFormat(this.lang, { minimumFractionDigits: this.decimalsValue, maximumFractionDigits: this.decimalsValue, useGrouping: false }).format(n)
  }

  get number() { return this.decimal ? this.parse(this.inputTarget.value) : (this.inputTarget.value === "" ? null : Number(this.inputTarget.value)) }

  writeRaw() {
    if (!this.hasRawTarget) return
    const n = this.number
    this.rawTarget.value = n === null ? "" : n.toFixed(this.decimalsValue)
  }

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
    if (this.decimal) {
      const min = this.limit("min"), max = this.limit("max"), step = this.limit("step") || 1
      let n = (this.number ?? min ?? 0) + dir * step
      if (min !== null) n = Math.max(n, min)
      if (max !== null) n = Math.min(n, max)
      i.value = this.format(Number(n.toFixed(this.decimalsValue)))
    } else {
      if (i.value === "") i.value = i.min || 0
      try { dir > 0 ? i.stepUp() : i.stepDown() } catch { i.value = Number(i.value || 0) + dir * Number(i.step || 1) }
    }
    if (i.value === before) return this.release()
    i.dispatchEvent(new Event("input", { bubbles: true }))
    i.dispatchEvent(new Event("change", { bubbles: true }))
    if (!reduced()) { i.classList.remove("is-bump"); void i.offsetWidth; i.classList.add("is-bump") }
  }

  // Ao sair do campo, prende entre min e max.
  clamp() {
    const i = this.inputTarget
    if (i.value === "") return this.sync()
    if (this.decimal) {
      const min = this.limit("min"), max = this.limit("max")
      let n = this.number ?? min ?? 0
      if (min !== null) n = Math.max(n, min)
      if (max !== null) n = Math.min(n, max)
      i.value = this.format(n)
      return this.sync()
    }
    const v = Number(i.value)
    if (i.min !== "" && v < Number(i.min)) i.value = i.min
    if (i.max !== "" && v > Number(i.max)) i.value = i.max
    this.sync()
  }

  sync() {
    const i = this.inputTarget, v = this.number ?? 0, min = this.limit("min"), max = this.limit("max")
    this.writeRaw()
    if (this.hasDownTarget) this.downTarget.disabled = i.disabled || (min !== null && v <= min)
    if (this.hasUpTarget) this.upTarget.disabled = i.disabled || (max !== null && v >= max)
    if (this.downTarget.disabled || this.upTarget.disabled) this.release()
  }
}
