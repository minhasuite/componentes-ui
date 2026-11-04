import { Controller } from "@hotwired/stimulus"
import { reduced, spring, easeOutBack, table } from "componentes_ui/controllers/ss_motion_controller"

// Passo a passo: um painel por vez; Avançar valida os campos do passo; rascunho opcional no localStorage.
// Ao andar (Avançar/Voltar), a ligação entre os passos e a barra de progresso enchem como
// minhoca: a cabeça corre na frente e passa um pouco, o corpo vem ~90 ms depois com a mola,
// e uma faísca vai na cabeça e some no fim. Voltar esvazia ao contrário (a faísca volta).
// É WAAPI nas propriedades registradas --wz-h (cabeça), --wz-t (corpo) e --wz-s (faísca),
// com data-wz no elemento enquanto anima (o CSS em v09_forms.css desenha). O círculo do passo
// atual estala e solta uma ondinha (ss-indicator com motion-value="pop").
export default class extends Controller {
  static targets = ["panel", "dot", "progress", "back", "next", "submit"]
  static values = { key: String }

  connect() {
    this.index = 0
    this.fills = new Map()
    this.restore()
    this.onInput = () => this.save()
    this.element.addEventListener("input", this.onInput)
    this.element.addEventListener("change", this.onInput)
    // Enter num campo antes do último passo avança em vez de enviar o form.
    this.onKey = (e) => {
      if (e.key !== "Enter" || e.target.matches("textarea, button") || this.index === this.panelTargets.length - 1) return
      e.preventDefault(); this.next()
    }
    this.element.addEventListener("keydown", this.onKey)
    this.show(this.index)
  }

  disconnect() {
    this.fills?.forEach((a) => a.cancel())
    this.element.removeEventListener("input", this.onInput)
    this.element.removeEventListener("change", this.onInput)
    this.element.removeEventListener("keydown", this.onKey)
  }

  next() {
    const fields = [...this.panelTargets[this.index].querySelectorAll("input, select, textarea")]
    const bad = fields.find((f) => !f.checkValidity())
    if (bad) { bad.reportValidity(); return }
    this.show(Math.min(this.index + 1, this.panelTargets.length - 1), true)
  }

  back() { this.show(Math.max(this.index - 1, 0), true) }

  finish() { this.clear() }

  show(i, focus = false) {
    // Sentido (o painel entra do lado para onde se andou); sem animação no primeiro desenho.
    if (focus && i !== this.index) this.element.dataset.dir = i > this.index ? "next" : "back"
    else if (!focus) delete this.element.dataset.dir
    const was = this.index
    this.index = i
    const last = this.panelTargets.length - 1
    this.panelTargets.forEach((p, n) => { p.hidden = n !== i })
    this.dotTargets.forEach((d, n) => {
      d.toggleAttribute("data-done", n < i)
      if (n === i) d.setAttribute("aria-current", "step"); else d.removeAttribute("aria-current")
    })
    if (this.hasProgressTarget) {
      this.progressTarget.setAttribute("aria-valuenow", i + 1)
      this.progressTarget.querySelector(".ss-progress-bar").style.width = `${((i + 1) * 100) / (last + 1)}%`
    }
    if (focus && i !== was) this.fill(was, i)
    this.backTarget.disabled = i === 0
    this.nextTarget.hidden = i === last
    this.submitTarget.hidden = i !== last
    if (focus) this.panelTargets[i].querySelector("input, select, textarea, button")?.focus()
    this.save()
  }

  // Enche (ou esvazia) o que mudou entre o passo a e o b.
  fill(a, b) {
    if (reduced() || !this.element.animate) return
    const n = this.panelTargets.length
    const jobs = []
    if (this.hasProgressTarget) jobs.push({ el: this.progressTarget, from: ((a + 1) * 100) / n, to: ((b + 1) * 100) / n, max: 100, order: 0 })
    this.dotTargets.forEach((d, k) => {
      if (k === 0) return
      const was = k <= a ? 100 : 0, now = k <= b ? 100 : 0
      if (was !== now) jobs.push({ el: d, from: was, to: now, max: 104, order: b > a ? k - a - 1 : a - k })
    })
    jobs.forEach((j) => this.worm(j, j.order * 110))
  }

  worm({ el, from, to, max }, delay) {
    const T = 520, LEAD = 320, LAG = 90, N = 30
    const prev = this.fills.get(el)
    if (prev?.playState === "running") {
      const cs = getComputedStyle(el)
      const h = parseFloat(cs.getPropertyValue("--wz-h")), t = parseFloat(cs.getPropertyValue("--wz-t"))
      if (Number.isFinite(h) && Number.isFinite(t)) from = (h + t) / 2
    }
    prev?.cancel()
    const sp = spring(el)
    const lim = (v) => Math.min(max, Math.max(0, v)).toFixed(2)
    const frames = []
    for (let i = 0; i <= N; i++) {
      const p = i / N, ms = p * T
      const head = from + (to - from) * easeOutBack(ms / LEAD)
      const tail = from + (to - from) * sp((ms - LAG) / (T - LAG))
      const [spark] = table([[0, 0], [0.08, 1], [0.6, 1], [1, 0]], p)
      frames.push({ offset: p, "--wz-h": lim(head), "--wz-t": lim(tail), "--wz-s": spark.toFixed(3) })
    }
    el.setAttribute("data-wz", to > from ? "fill" : "drain")
    const anim = el.animate(frames, { duration: T, delay, easing: "linear", fill: "backwards" })
    this.fills.set(el, anim)
    const done = () => { if (this.fills.get(el) === anim) { el.removeAttribute("data-wz"); this.fills.delete(el) } }
    anim.finished.then(done, done)
  }

  get storeKey() { return this.keyValue ? `ss-wizard:${this.keyValue}` : null }

  save() {
    if (!this.storeKey) return
    const data = { step: this.index, fields: {} }
    this.element.querySelectorAll("[name]").forEach((f) => {
      if (f.type === "password" || f.type === "file" || f.type === "hidden" && f.name === "authenticity_token") return
      if ((f.type === "checkbox" || f.type === "radio")) { if (f.checked) data.fields[`${f.name}=${f.value}`] = true }
      else data.fields[f.name] = f.value
    })
    try { localStorage.setItem(this.storeKey, JSON.stringify(data)) } catch (_) {}
  }

  restore() {
    if (!this.storeKey) return
    let data
    try { data = JSON.parse(localStorage.getItem(this.storeKey) || "null") } catch (_) { return }
    if (!data) return
    this.element.querySelectorAll("[name]").forEach((f) => {
      if (f.type === "checkbox" || f.type === "radio") f.checked = !!data.fields[`${f.name}=${f.value}`]
      else if (f.name in data.fields && f.type !== "file" && f.type !== "password") f.value = data.fields[f.name]
    })
    this.index = Math.min(data.step || 0, this.panelTargets.length - 1)
  }

  clear() { if (this.storeKey) try { localStorage.removeItem(this.storeKey) } catch (_) {} }
}
