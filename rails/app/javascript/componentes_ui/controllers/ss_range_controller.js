import { Controller } from "@hotwired/stimulus"
import { ssLang } from "componentes_ui/controllers/ss_intl"

// Formato estilo sprintf (%s, %d, %.Nf, %%) com o decimal do idioma da página (v0.10.1),
// igual ao RangeComponent#text: "%.1f °C" → "21,5 °C" em pt. Sem separador de milhar.
export function ssRangeText(format, value) {
  const v = Number(value)
  return format.replace(/%(?:\.(\d+))?([sdf])/, (_, prec, kind) => {
    if (!Number.isFinite(v)) return String(value)
    let digits
    if (kind === "d") return String(Math.trunc(v))
    if (kind === "f") digits = prec == null ? 6 : Number(prec)
    else if (prec != null) digits = Number(prec)
    else digits = (String(value).split(".")[1] || "").length
    return new Intl.NumberFormat(ssLang(), { minimumFractionDigits: digits, maximumFractionDigits: digits, useGrouping: false }).format(v)
  }).replace("%%", "%")
}

// Slider com o valor ao lado: atualiza o <output>, a parte preenchida (--p) e o aria-valuetext.
// Arrastando, marca data-dragging no input (o seletor cresce com mola e o valor ao lado também).
//
// v0.10: trilha em gradiente (track: kelvin|hue|brightness → o seletor pega a cor do ponto,
// --range-c), bolha com o valor (--pn no box), barra "fill" (texto branco só na parte cheia, --p no box) e
// envio automático do form (submit: release → no change, ao soltar; input → arrastando), com
// debounce. Tudo opcional: sem os valores novos, faz só o que fazia.
export default class extends Controller {
  static targets = ["input", "out", "bubble", "box"]
  static values = {
    format: { type: String, default: "%s" },
    track: String,
    tone: String,
    submit: String,
    debounce: { type: Number, default: 250 },
  }

  connect() {
    this.down = () => this.inputTarget.setAttribute("data-dragging", "")
    this.up = () => this.inputTarget.removeAttribute("data-dragging")
    this.inputTarget.addEventListener("pointerdown", this.down)
    ;["pointerup", "pointercancel", "lostpointercapture", "blur"].forEach((e) => this.inputTarget.addEventListener(e, this.up))
    window.addEventListener("pointerup", this.up)
  }

  disconnect() {
    clearTimeout(this.timer)
    this.inputTarget.removeEventListener("pointerdown", this.down)
    ;["pointerup", "pointercancel", "lostpointercapture", "blur"].forEach((e) => this.inputTarget.removeEventListener(e, this.up))
    window.removeEventListener("pointerup", this.up)
  }

  update() {
    const i = this.inputTarget
    const min = Number(i.min || 0), max = Number(i.max || 100)
    const v = Number(i.value)
    const p = max === min ? 0 : ((v - min) * 100) / (max - min)
    const text = ssRangeText(this.formatValue, i.value)
    i.style.setProperty("--p", `${p}%`)
    i.setAttribute("aria-valuetext", text)
    this.outTargets.forEach((o) => (o.textContent = text))
    if (this.hasBubbleTarget) this.bubbleTarget.textContent = text
    if (this.hasBoxTarget) {
      this.boxTarget.style.setProperty("--pn", (p / 100).toFixed(4))
      this.boxTarget.style.setProperty("--p", `${p}%`)
    }
    const c = this.thumbColor(v, p)
    if (c) i.style.setProperty("--range-c", c)
    if (this.submitValue === "input") this.schedule()
  }

  // Soltou (ou mudou pelo teclado): envia, se pedido.
  commit() {
    if (this.submitValue) this.schedule()
  }

  schedule() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      const form = this.inputTarget.form || this.element.closest("form")
      if (form) form.requestSubmit()
      else this.dispatch("change", { detail: { value: this.inputTarget.value } })
    }, this.debounceValue)
  }

  thumbColor(v, p) {
    switch (this.trackValue) {
      case "kelvin": return kelvin(v)
      case "hue": return `hsl(${Math.round(v)} 100% 50%)`
      case "brightness": return `color-mix(in srgb, ${this.toneValue || "var(--accent)"} ${Math.max(14, Math.round(p))}%, #1e1a38)`
      default: return null
    }
  }
}

// Cor aproximada de uma temperatura de cor (Tanner Helland), a mesma do Ruby e do Flutter.
export function kelvin(k) {
  const t = Math.min(40000, Math.max(1000, k)) / 100
  let r, g, b
  if (t <= 66) {
    r = 255
    g = 99.4708025861 * Math.log(t) - 161.1195681661
    b = t <= 19 ? 0 : 138.5177312231 * Math.log(t - 10) - 305.0447927307
  } else {
    r = 329.698727446 * Math.pow(t - 60, -0.1332047592)
    g = 288.1221695283 * Math.pow(t - 60, -0.0755148492)
    b = 255
  }
  const h = (x) => Math.round(Math.min(255, Math.max(0, x))).toString(16).padStart(2, "0")
  return `#${h(r)}${h(g)}${h(b)}`
}
