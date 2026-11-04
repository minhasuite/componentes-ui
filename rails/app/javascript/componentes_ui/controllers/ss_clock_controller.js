import { Controller } from "@hotwired/stimulus"

// Relógio (Ss::ClockComponent): anda de segundo em segundo (acerta na virada do segundo) com
// Intl no idioma da página (<html lang>) ou no locale dado. O ponto dos segundos acende nos
// segundos pares; com "reduzir movimento", fica aceso (o CSS cuida). seconds: :digits mostra
// os dígitos dos segundos (target s), menores, depois dos minutos.
export default class extends Controller {
  static targets = ["h", "m", "s", "dot", "ampm", "date"]
  static values = { hour12: Boolean, date: Boolean, locale: String, zone: String }

  connect() {
    const lang = this.localeValue || document.documentElement.lang || navigator.language
    const tz = this.zoneValue ? { timeZone: this.zoneValue } : {}
    this.time = new Intl.DateTimeFormat(lang, { hour: "numeric", minute: "2-digit", second: "2-digit", hour12: this.hour12Value, ...tz })
    this.day = new Intl.DateTimeFormat(lang, { weekday: "long", day: "numeric", month: "long", ...tz })
    this.tick()
    this.timeout = setTimeout(() => {
      this.tick()
      this.timer = setInterval(() => this.tick(), 1000)
    }, 1000 - (Date.now() % 1000))
  }

  disconnect() {
    clearTimeout(this.timeout)
    clearInterval(this.timer)
  }

  tick() {
    const now = new Date()
    const p = Object.fromEntries(this.time.formatToParts(now).map((x) => [x.type, x.value]))
    const h = this.hour12Value ? p.hour : String(p.hour).padStart(2, "0")
    if (this.hasHTarget) this.hTarget.textContent = h
    if (this.hasMTarget) this.mTarget.textContent = p.minute
    if (this.hasSTarget) this.sTarget.textContent = String(p.second).padStart(2, "0")
    if (this.hasAmpmTarget && p.dayPeriod) this.ampmTarget.textContent = p.dayPeriod.toUpperCase()
    if (this.hasDotTarget) this.dotTarget.dataset.on = Number(p.second) % 2 === 0
    const date = this.dateValue ? this.day.format(now) : null
    if (date && this.hasDateTarget) this.dateTarget.textContent = date
    this.element.setAttribute("aria-label", [`${h}:${p.minute}${p.dayPeriod ? " " + p.dayPeriod : ""}`, date].filter(Boolean).join(", "))
  }
}
