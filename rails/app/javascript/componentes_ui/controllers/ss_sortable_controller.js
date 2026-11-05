import { Controller } from "@hotwired/stimulus"

// Lista de arrastar para ordenar (Ss::SortableListComponent). A alça arrasta com o ponteiro
// (mouse, dedo, caneta) e, com o foco nela, ↑/↓ movem um lugar. A cada mudança: evento
// ss-sortable:change (detail: { ids }) e, com url, PATCH JSON { ids } com o token CSRF.
// O leitor de tela ouve "Movido para a posição N de T" (texto do servidor, no idioma da página).
export default class extends Controller {
  static targets = ["list", "item", "live"]
  static values = { url: String, method: { type: String, default: "PATCH" }, param: { type: String, default: "ids" }, moved: String }

  disconnect() { this.drop() }

  get items() { return [...this.listTarget.children].filter((el) => el.matches(".ss-sortable-item")) }
  get ids() { return this.items.map((li) => li.dataset.id) }
  get reduce() { return matchMedia("(prefers-reduced-motion: reduce)").matches }

  // ── Teclado: ↑/↓ na alça ──
  key(e) {
    if (e.altKey || e.ctrlKey || e.metaKey || !["ArrowUp", "ArrowDown"].includes(e.key)) return
    e.preventDefault()
    const li = e.currentTarget.closest(".ss-sortable-item")
    const other = e.key === "ArrowUp" ? li.previousElementSibling : li.nextElementSibling
    if (!other) return
    const before = li.getBoundingClientRect().top
    e.key === "ArrowUp" ? other.before(li) : other.after(li)
    this.flip(li, before)
    e.currentTarget.focus()
    this.changed(li)
  }

  // ── Ponteiro: segura a alça e arrasta ──
  grab(e) {
    if (e.button !== 0) return
    e.preventDefault()
    const li = e.currentTarget.closest(".ss-sortable-item")
    this.drag = { li, y: e.clientY, start: this.ids.join(), handle: e.currentTarget }
    e.currentTarget.setPointerCapture?.(e.pointerId)
    li.classList.add("is-dragging")
    this.onMove = (ev) => this.move(ev)
    this.onUp = () => this.drop(true)
    window.addEventListener("pointermove", this.onMove)
    window.addEventListener("pointerup", this.onUp, { once: true })
    window.addEventListener("pointercancel", this.onUp, { once: true })
  }

  move(e) {
    const d = this.drag
    if (!d) return
    const { li } = d
    li.style.translate = `0 ${e.clientY - d.y}px`
    const mid = li.getBoundingClientRect()
    const center = mid.top + mid.height / 2
    const prev = li.previousElementSibling
    const next = li.nextElementSibling
    const swap = (other, after) => {
      const before = li.getBoundingClientRect().top - (e.clientY - d.y)
      const otherTop = other.getBoundingClientRect().top
      after ? other.after(li) : other.before(li)
      // O item continua sob o dedo: o deslocamento recomeça do lugar novo.
      const now = li.getBoundingClientRect().top - (e.clientY - d.y)
      d.y += now - before
      li.style.translate = `0 ${e.clientY - d.y}px`
      this.flipOther(other, otherTop)
    }
    if (prev && center < prev.getBoundingClientRect().top + prev.offsetHeight / 2) swap(prev, false)
    else if (next && center > next.getBoundingClientRect().top + next.offsetHeight / 2) swap(next, true)
  }

  drop(commit = false) {
    const d = this.drag
    if (!d) return
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    window.removeEventListener("pointercancel", this.onUp)
    d.li.classList.remove("is-dragging")
    d.li.style.translate = ""
    this.drag = null
    if (commit && this.ids.join() !== d.start) this.changed(d.li)
  }

  // ── Depois de mudar ──
  async changed(li) {
    const ids = this.ids
    const n = ids.indexOf(li.dataset.id) + 1
    if (this.hasLiveTarget && this.movedValue) this.liveTarget.textContent = this.movedValue.replace("{n}", n).replace("{total}", ids.length)
    li.classList.remove("is-moved"); void li.offsetWidth; li.classList.add("is-moved")
    this.dispatch("change", { prefix: "ss-sortable", detail: { ids, id: li.dataset.id, position: n - 1 } })
    if (!this.urlValue) return
    this.listTarget.classList.add("is-busy")
    try {
      const token = document.querySelector("meta[name=csrf-token]")?.content
      await fetch(this.urlValue, {
        method: this.methodValue,
        headers: { "Content-Type": "application/json", Accept: "application/json", "X-CSRF-Token": token || "" },
        body: JSON.stringify({ [this.paramValue]: ids })
      })
    } finally { this.listTarget.classList.remove("is-busy") }
  }

  flip(li, before) {
    if (this.reduce) return
    const dy = before - li.getBoundingClientRect().top
    li.animate([{ transform: `translateY(${dy}px)` }, { transform: "none" }],
      { duration: 360, easing: getComputedStyle(li).getPropertyValue("--ss-bounce").trim() || "ease-out" })
  }

  flipOther(other, top) {
    if (this.reduce) return
    const dy = top - other.getBoundingClientRect().top
    other.animate([{ transform: `translateY(${dy}px)` }, { transform: "none" }], { duration: 200, easing: "ease-out" })
  }
}
