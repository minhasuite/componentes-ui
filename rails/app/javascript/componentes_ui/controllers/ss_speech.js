// v1.13.0 "confiança na IA e suíte": o valor falado em centavos (par do SsSpeech.parseAmountPtBr do Flutter e do
// ComponentesUi::Speech.parse_amount da gem). As mesmas regras e os mesmos casos (docs/v1130/fala.json).
//   ssParseAmount("cento e vinte e três e cinquenta") // 12350
//   ssParseAmount("doze e meio")                      // 1250
// null quando não há número ou a frase não fecha.

const UNITS = { zero: 0, um: 1, uma: 1, dois: 2, duas: 2, tres: 3, quatro: 4, cinco: 5, seis: 6, sete: 7, oito: 8, nove: 9 }
const TEENS = { dez: 10, onze: 11, doze: 12, treze: 13, catorze: 14, quatorze: 14, quinze: 15, dezesseis: 16, dezasseis: 16,
  dezessete: 17, dezassete: 17, dezoito: 18, dezenove: 19, dezanove: 19 }
const TENS = { vinte: 20, trinta: 30, quarenta: 40, cinquenta: 50, cincoenta: 50, sessenta: 60, setenta: 70, oitenta: 80, noventa: 90 }
const HUNDREDS = { cento: 100, duzentos: 200, duzentas: 200, trezentos: 300, trezentas: 300, quatrocentos: 400, quatrocentas: 400,
  quinhentos: 500, quinhentas: 500, seiscentos: 600, seiscentas: 600, setecentos: 700, setecentas: 700, oitocentos: 800,
  oitocentas: 800, novecentos: 900, novecentas: 900 }
const SCALES = { mil: 1000, milhao: 1e6, milhoes: 1e6, bilhao: 1e9, bilhoes: 1e9 }
const REAIS = new Set(["real", "reais", "conto", "contos"])
const CENTAVOS = new Set(["centavo", "centavos"])
const has = (o, k) => Object.prototype.hasOwnProperty.call(o, k)

class Group {
  constructor() { this.reset() }
  get empty() { return this.minLevel === 4 }
  add(v, level, closes = false) {
    if (level >= this.minLevel) return false
    this.value += v
    this.minLevel = closes ? 1 : level
    return true
  }
  set(v) { this.value = v; this.minLevel = 0 }
  reset() { this.value = 0; this.minLevel = 4 }
}

function thousands(t) {
  const parts = t.split(".")
  if (parts.slice(1).some((p) => p.length !== 3)) return null
  const j = parts.join("")
  return /^\d+$/.test(j) ? parseInt(j, 10) : null
}

function numeric(t) {
  const frac = (f) => (!f.length || f.length > 2 ? null : parseInt(f.padEnd(2, "0"), 10))
  if (t.includes(",")) {
    const i = t.lastIndexOf(",")
    const whole = t.slice(0, i), f = t.slice(i + 1)
    if (whole.includes(",")) return null
    const w = thousands(whole || "0"), c = frac(f)
    return w === null || c === null ? null : [w, c]
  }
  if (t.includes(".")) {
    const parts = t.split(".")
    if (parts.length === 2 && parts[1].length <= 2) {
      const c = frac(parts[1])
      return c === null ? null : [parseInt(parts[0], 10), c]
    }
    const w = thousands(t)
    return w === null ? null : [w, null]
  }
  return [parseInt(t, 10), null]
}

class Parser {
  constructor(text) {
    this.text = text
    this.mode = "reais"
    this.total = 0
    this.group = new Group()
    this.cents = new Group()
    this.lastScale = null
    this.lastWasScale = false
    this.seen = false
    this.neg = false
    this.rawCents = null
    this.numericFrac = null
    this.decimal = []
    this.decimalDigits = ""
    this.decimalOnlyDigits = true
  }

  run() {
    const folded = this.text.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replaceAll("r$", " ").replaceAll("−", "-")
    const tokens = folded.match(/\d+(?:[.,]\d+)*|[a-z]+|-/g) || []
    for (const t of tokens) if (!this.step(t)) return null
    return this.finish()
  }

  step(t) {
    if (t === "menos" || t === "-") { if (!this.seen) this.neg = true; return true }
    if (/^\d/.test(t)) return this.number(t)
    if (has(UNITS, t)) return this.word(UNITS[t], 1)
    if (has(TEENS, t)) return this.word(TEENS[t], 2, true)
    if (has(TENS, t)) return this.word(TENS[t], 2)
    if (has(HUNDREDS, t)) return this.word(HUNDREDS[t], 3)
    if (t === "cem") return this.word(100, 3, true)
    if (has(SCALES, t)) return this.scale(SCALES[t])
    if (REAIS.has(t)) return this.markReais()
    if (CENTAVOS.has(t)) return this.markCentavos()
    if (t === "meio" || t === "meia") return this.meio()
    if (t === "virgula") {
      if (this.mode !== "reais" || !this.seen) return false
      this.mode = "decimal"
      return true
    }
    return true
  }

  word(v, level, closes = false) {
    switch (this.mode) {
      case "reais":
        this.seen = true
        if (this.group.add(v, level, closes)) { this.lastWasScale = false; return true }
        if (this.group.empty) return false
        this.mode = "cents"
        return this.cents.add(v, level, closes)
      case "cents": return this.cents.add(v, level, closes)
      case "decimal":
        if (level !== 1) this.decimalOnlyDigits = false
        this.decimal.push([v, closes ? 2 : level])
        this.decimalDigits += String(v)
        return true
      default: return false
    }
  }

  number(t) {
    const n = numeric(t)
    if (!n) return false
    const [whole, frac] = n
    switch (this.mode) {
      case "reais":
        this.seen = true
        if (this.group.empty) {
          this.group.set(whole)
          this.lastWasScale = false
          if (frac !== null) { this.cents.set(frac); this.numericFrac = frac }
          return true
        }
        if (frac !== null || whole > 99 || !this.cents.empty) return false
        this.mode = "cents"
        this.cents.set(whole)
        return true
      case "cents":
        if (frac !== null || whole > 99 || !this.cents.empty) return false
        this.cents.set(whole)
        return true
      case "decimal":
        if (frac !== null) return false
        this.decimalDigits += t
        this.decimal.push([whole, whole < 10 ? 1 : 2])
        return true
      default: return false
    }
  }

  scale(s) {
    if (this.mode !== "reais") return false
    if (this.lastScale !== null && s >= this.lastScale) return false
    const mult = this.group.empty ? 1 : this.group.value
    this.total += mult * s
    if (this.numericFrac !== null) {
      this.total += Math.trunc(this.numericFrac * s / 100)
      this.numericFrac = null
      this.cents.reset()
    }
    this.group.reset()
    this.lastScale = s
    this.lastWasScale = true
    this.seen = true
    return true
  }

  markReais() {
    if (!this.seen) return true
    switch (this.mode) {
      case "reais": this.mode = "cents"; this.numericFrac = null; return true
      case "decimal": this.closeDecimal(); this.mode = "end"; return true
      case "cents": return this.numericFrac !== null || this.cents.empty
      default: return true
    }
  }

  markCentavos() {
    if (!this.seen) return true
    switch (this.mode) {
      case "cents": this.mode = "end"; return true
      case "reais":
        if (this.numericFrac !== null) return false
        if (this.total > 0) {
          const c = this.group.value % 100
          this.group.value -= c
          this.cents.set(c)
        } else {
          this.rawCents = this.group.value
          this.group.reset()
        }
        this.mode = "end"
        return true
      default: return false
    }
  }

  meio() {
    switch (this.mode) {
      case "reais":
        if (!this.seen) { this.rawCents = 50; this.seen = true }
        else if (this.lastWasScale && this.group.empty) this.total += Math.trunc(this.lastScale / 2)
        else { if (!this.cents.empty) return false; this.cents.set(50) }
        this.mode = "end"
        return true
      case "cents":
        if (!this.cents.empty) return false
        this.cents.set(50)
        this.mode = "end"
        return true
      default: return false
    }
  }

  closeDecimal() {
    if (!this.decimal.length) return true
    if (this.decimalOnlyDigits) {
      this.cents.set(parseInt(`${this.decimalDigits}00`.slice(0, 2), 10))
    } else {
      const g = new Group()
      for (const [v, level] of this.decimal) if (!g.add(v, level, level === 2 && v >= 10 && v < 20)) return false
      if (g.value > 99) return false
      this.cents.set(g.value)
    }
    this.decimal = []
    return true
  }

  finish() {
    if (!this.seen) return null
    if (this.mode === "decimal" && !this.closeDecimal()) return null
    if (this.cents.value > 99) return null
    const cents = (this.total + this.group.value) * 100 + this.cents.value + (this.rawCents ?? 0)
    return this.neg ? -cents : cents
  }
}

export function ssParseAmount(text) { return new Parser(String(text ?? "")).run() }

// O estado da tela no link do outro aparelho (par do SsHandoff / ComponentesUi::Handoff): JSON em base64url sem "=".
export function ssHandoffEncode(state) {
  const bytes = new TextEncoder().encode(JSON.stringify(state))
  let bin = ""
  bytes.forEach((b) => { bin += String.fromCharCode(b) })
  return btoa(bin).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "")
}
