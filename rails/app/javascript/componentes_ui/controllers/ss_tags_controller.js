import { Controller } from "@hotwired/stimulus"

// Etiquetas: Enter ou vírgula vira chip, Backspace no vazio apaga a última; hidden = lista com vírgula.
// Movimento: a nova entra crescendo com mola (.is-new no CSS); a removida encolhe e fecha o
// espaço (WAAPI) antes de sair do DOM. Já sai da lista (hidden) na hora.
export default class extends Controller {
  static targets = ["list", "input", "hidden"]

  get values() { return [...this.listTarget.querySelectorAll(".ss-tag:not(.is-leaving) > span")].map((s) => s.textContent) }

  get tags() { return [...this.listTarget.querySelectorAll(".ss-tag:not(.is-leaving)")] }

  key(e) {
    if (e.key === "Enter" || e.key === ",") { e.preventDefault(); this.commit() }
    else if (e.key === "Backspace" && !this.inputTarget.value) {
      const last = this.tags.at(-1)
      if (last) { this.leave(last); this.update() }
    }
  }

  paste(e) {
    const text = (e.clipboardData || window.clipboardData).getData("text")
    if (!text.includes(",")) return
    e.preventDefault()
    text.split(",").forEach((t) => this.add(t))
    this.update()
  }

  commit() {
    this.inputTarget.value.split(",").forEach((t) => this.add(t))
    this.inputTarget.value = ""
    this.update()
  }

  add(raw) {
    const text = raw.trim()
    if (!text || this.values.some((v) => v.toLowerCase() === text.toLowerCase())) return
    const li = document.createElement("li"); li.className = "ss-tag is-new"
    const span = document.createElement("span"); span.textContent = text
    const btn = document.createElement("button")
    btn.type = "button"; btn.textContent = "×"; btn.setAttribute("aria-label", `Remover ${text}`); btn.dataset.action = "ss-tags#remove"
    li.append(span, btn)
    this.listTarget.append(li)
  }

  remove(e) {
    e.stopPropagation()
    const tag = e.target.closest(".ss-tag")
    if (tag) this.leave(tag)
    this.update()
    this.inputTarget.focus()
  }

  // Sai encolhendo e fecha o espaço; sem movimento (ou sem WAAPI), sai na hora.
  leave(tag) {
    tag.classList.add("is-leaving")
    if (matchMedia("(prefers-reduced-motion: reduce)").matches || !tag.animate) return tag.remove()
    const w = tag.getBoundingClientRect().width
    const gap = parseFloat(getComputedStyle(tag.parentElement.closest(".ss-tags-box") || tag).columnGap) || 0
    const a = tag.animate([
      { opacity: 1, scale: 1, width: `${w}px`, marginRight: "0px" },
      { opacity: 0, scale: 0.5, width: "0px", paddingLeft: "0px", paddingRight: "0px", marginRight: `${-gap}px` }
    ], { duration: 200, easing: "cubic-bezier(.4, 0, 1, 1)", fill: "forwards" })
    a.onfinish = a.oncancel = () => tag.remove()
  }

  focus(e) { if (e.target === e.currentTarget || e.target === this.listTarget) this.inputTarget.focus() }

  update() {
    this.hiddenTarget.value = this.values.join(",")
    this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.dispatch("change", { detail: { values: this.values } })
  }
}
