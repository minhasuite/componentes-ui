import { Controller } from "@hotwired/stimulus"

// Ss::SplitViewComponent: marca o item clicado (aria-current), liga o modo
// "detalhe aberto" (data-detail) quando o frame carrega e volta para a lista.
export default class extends Controller {
  static targets = ["list", "frame"]
  static values = { frame: String }

  connect() {
    if (this.hasFrameTarget && !this.frameTarget.querySelector(".ss-split-empty")) this.element.setAttribute("data-detail", "")
    this.emptyHTML = `<div class="ss-split-empty">${this.element.querySelector(".ss-split-empty")?.innerHTML || ""}</div>`
  }

  pick(event) {
    const link = event.target.closest(`a[data-turbo-frame="${this.frameValue}"]`)
    if (!link || !this.listTarget.contains(link)) return
    this.listTarget.querySelectorAll("[aria-current]").forEach((a) => a.removeAttribute("aria-current"))
    link.setAttribute("aria-current", "true")
  }

  loaded(event) {
    if (event.target !== this.frameTarget) return
    this.element.setAttribute("data-detail", "")
    if (matchMedia("(max-width: 1023px)").matches) this.frameTarget.closest(".ss-split-detail")?.scrollIntoView({ block: "start" })
  }

  back() {
    this.element.removeAttribute("data-detail")
    this.frameTarget.innerHTML = this.emptyHTML
    const current = this.listTarget.querySelector("[aria-current]")
    current?.removeAttribute("aria-current"); current?.focus()
  }
}
