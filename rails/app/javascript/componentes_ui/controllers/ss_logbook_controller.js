import { Controller } from "@hotwired/stimulus"

// Logbook (Ss::LogbookComponent): a página seguinte chega num turbo-frame no rodapé.
// - Chegou: o dia que continua da página anterior não repete o cabeçalho.
// - "Carregar mais" (lazy: false): o rodapé vira "Carregando…" enquanto busca.
// - Falhou (rede ou resposta sem o frame): o rodapé mostra o erro e "Tentar de novo",
//   que busca de novo o mesmo frame.
export default class extends Controller {
  static targets = ["more"]
  static values = { error: String, retry: String, loading: String }

  connect() {
    this.onLoad = () => this.dedupe()
    this.onFail = (e) => this.fail(e)
    this.element.addEventListener("turbo:frame-load", this.onLoad)
    this.element.addEventListener("turbo:fetch-request-error", this.onFail)
    this.element.addEventListener("turbo:frame-missing", this.onFail)
    this.dedupe()
  }

  disconnect() {
    this.element.removeEventListener("turbo:frame-load", this.onLoad)
    this.element.removeEventListener("turbo:fetch-request-error", this.onFail)
    this.element.removeEventListener("turbo:frame-missing", this.onFail)
  }

  // Cabeçalho do mesmo dia que o anterior (dia que continua): some.
  dedupe() {
    let last = null
    this.element.querySelectorAll(".ss-lb-head[data-day]").forEach((h) => {
      h.hidden = h.dataset.day === last
      h.closest(".ss-lb-day")?.classList.toggle("is-continued", h.hidden)
      if (!h.hidden) last = h.dataset.day
    })
    this.element.setAttribute("aria-busy", "false")
  }

  loading(e) {
    const foot = e.currentTarget.closest(".ss-lb-foot")
    if (!foot) return
    this.element.setAttribute("aria-busy", "true")
    // Depois do clique (o Turbo ainda lê o link no mesmo evento).
    setTimeout(() => {
      foot.innerHTML = `<span class="ss-lb-spin" aria-hidden="true"></span>${this.loadingValue || "…"}`
      foot.setAttribute("role", "status")
    })
  }

  fail(e) {
    const frame = e.target.closest?.("turbo-frame") || e.target
    if (!frame || frame.tagName !== "TURBO-FRAME") return
    e.preventDefault?.()
    this.element.setAttribute("aria-busy", "false")
    const src = frame.getAttribute("src") || frame.querySelector("a[href]")?.getAttribute("href")
    const p = document.createElement("p")
    p.className = "ss-lb-foot is-error"
    p.setAttribute("role", "alert")
    p.textContent = this.errorValue
    const b = document.createElement("button")
    b.type = "button"
    b.className = "ss-btn ss-btn-ghost ss-btn-sm"
    b.textContent = this.retryValue
    b.addEventListener("click", () => {
      p.innerHTML = '<span class="ss-lb-spin" aria-hidden="true"></span>'
      frame.removeAttribute("src")
      frame.src = src
    })
    p.append(" ", b)
    frame.replaceChildren(p)
  }
}
