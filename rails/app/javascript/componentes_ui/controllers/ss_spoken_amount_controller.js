import { Controller } from "@hotwired/stimulus"
import { ssParseAmount } from "componentes_ui/controllers/ss_speech"

// v1.13.0 (Ss::MoneyInputComponent(voice: true), par do SsSpokenAmount/SsMoneyField(onVoice:)): o microfone do campo
// de dinheiro. Usa o SpeechRecognition do navegador (no idioma da página; sem ele, o botão fica escondido), converte o
// texto em centavos pelo ssParseAmount e escreve no campo como o ss-money espera (os dígitos; no modo conta, "123,50"),
// com a linha "Ouvi “…”" (região viva) ou "Não entendi…". O produto com reconhecedor próprio manda o texto pelo evento
// ss-spoken-amount:text ({ detail: { text } }); cada valor ouvido sai em ss-spoken-amount:heard ({ text, cents }).
const Recognition = () => window.SpeechRecognition || window.webkitSpeechRecognition

export default class extends Controller {
  static targets = ["input", "button", "out"]
  static values = { texts: Object, expression: Boolean }

  connect() {
    if (this.hasButtonTarget) this.buttonTarget.hidden = !Recognition()
    this.onText = (e) => this.use(String(e.detail?.text ?? e.detail ?? ""))
    this.element.addEventListener("ss-spoken-amount:text", this.onText)
  }

  disconnect() {
    this.element.removeEventListener("ss-spoken-amount:text", this.onText)
    this.recognition?.abort()
  }

  listen() {
    const R = Recognition()
    if (!R) return
    if (this.recognition) { this.recognition.stop(); return }
    const r = (this.recognition = new R())
    r.lang = document.documentElement.lang || "pt-BR"
    r.interimResults = false
    r.maxAlternatives = 3
    this.listening(true)
    r.onresult = (e) => {
      const alts = [...(e.results?.[0] ?? [])].map((a) => a.transcript)
      const text = alts.find((a) => ssParseAmount(a) !== null) ?? alts[0] ?? ""
      this.use(text)
    }
    r.onerror = () => this.listening(false)
    r.onend = () => { this.recognition = null; this.listening(false) }
    r.start()
  }

  listening(on) {
    if (!this.hasButtonTarget) return
    this.buttonTarget.setAttribute("aria-pressed", on)
    this.buttonTarget.toggleAttribute("data-listening", on)
    this.buttonTarget.setAttribute("aria-label", on ? this.textsValue.listening : this.textsValue.speak)
    if (on) this.say(this.textsValue.listening)
  }

  use(text) {
    const cents = ssParseAmount(text)
    if (cents === null) {
      this.say((this.textsValue.not_understood ?? "").replace("%{text}", text), true)
    } else {
      const neg = cents < 0, abs = Math.abs(cents)
      this.inputTarget.value = this.expressionValue
        ? `${neg ? "-" : ""}${Math.trunc(abs / 100)},${String(abs % 100).padStart(2, "0")}`
        : `${neg ? "-" : ""}${abs}`
      this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
      this.say((this.textsValue.heard ?? "").replace("%{text}", text))
    }
    this.dispatch("heard", { prefix: "ss-spoken-amount", detail: { text, cents } })
  }

  say(text, bad = false) {
    if (!this.hasOutTarget) return
    this.outTarget.hidden = !text
    this.outTarget.textContent = text
    this.outTarget.classList.toggle("is-bad", bad)
  }
}
