import { Controller } from "@hotwired/stimulus"

// Lista de blocos (Ss::BlockListComponent): mover para cima/baixo troca o bloco de lugar no DOM
// (só entre irmãos da mesma lista), renumera os inputs de posição e avisa o leitor de tela.
// Duplicar/excluir sem URL disparam "ss-block-list:duplicate|delete" (detail: { id }); excluir
// sem preventDefault tira o bloco. Listas aninhadas têm o próprio controller.
export default class extends Controller {
  static targets = ["list", "live"]
  static values = { moved: String }

  connect() { this.renumber() }

  block(e) { return e.target.closest(".ss-blk") }

  // Só os blocos desta lista (não os das listas de dentro).
  get items() { return [...this.listTarget.children].filter((el) => el.matches(".ss-blk")) }

  moveUp(e) { this.move(e, -1) }
  moveDown(e) { this.move(e, 1) }

  move(e, dir) {
    const li = this.block(e)
    const other = dir < 0 ? li.previousElementSibling : li.nextElementSibling
    this.closeMenu(e)
    if (!other) return
    const before = li.getBoundingClientRect().top
    dir < 0 ? other.before(li) : other.after(li)
    this.renumber()
    this.flip(li, before)
    li.querySelector(".ss-blk-more-btn")?.focus()
    const n = this.items.indexOf(li) + 1
    if (this.hasLiveTarget) this.liveTarget.textContent = this.movedValue.replace("{n}", n)
    this.dispatch("move", { prefix: "ss-block-list", detail: { id: li.dataset.id, position: n - 1 } })
  }

  duplicate(e) {
    const li = this.block(e)
    this.closeMenu(e)
    this.dispatch("duplicate", { prefix: "ss-block-list", detail: { id: li.dataset.id } })
  }

  delete(e) {
    const li = this.block(e)
    this.closeMenu(e)
    const ev = this.dispatch("delete", { prefix: "ss-block-list", detail: { id: li.dataset.id }, cancelable: true })
    if (ev.defaultPrevented) return
    li.remove()
    this.renumber()
  }

  renumber() {
    this.items.forEach((li, i) => {
      const pos = li.querySelector(":scope > [data-ss-block-list-target='position']")
      if (pos) pos.value = i
      li.querySelector(":scope > .ss-blk-tools [data-move='up']")?.toggleAttribute("disabled", i === 0)
      li.querySelector(":scope > .ss-blk-tools [data-move='down']")?.toggleAttribute("disabled", i === this.items.length - 1)
    })
  }

  closeMenu(e) { e.target.closest("details.ss-blk-more")?.removeAttribute("open") }

  // Desliza do lugar antigo para o novo com a mola (FLIP); nada com "reduzir movimento".
  flip(li, before) {
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) return
    const dy = before - li.getBoundingClientRect().top
    li.animate([{ transform: `translateY(${dy}px)` }, { transform: "none" }],
      { duration: 460, easing: getComputedStyle(li).getPropertyValue("--ss-bounce").trim() || "ease-out" })
  }
}
